//
//  FirestoreDataManager.swift
//  Welling
//
//  Created by Irwin Billing on 2024-05-29.
//

import FirebaseAuth
import FirebaseFirestore
import Foundation
import os

class FirestoreDataManager {
    static let loggerCategory: String = String(describing: FirestoreDataManager.self)
    static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: FirestoreDataManager.self))
    
    let db = Firestore.firestore()
    let encoder = Firestore.Encoder()
    let decoder = JSONDecoder()
    var pendingMessageIdsInUserState: [String] = []
    var pendingMessageListenerRegistration: (any ListenerRegistration)?
    var allListenerRegistrations: [any ListenerRegistration] = []
    var messageUpdateListeners: [(_ messages: [MobileMessage]) throws -> Void] = []
    var messagesCompletedListener: [(_ messages: [MobileMessage]) throws -> Void] = []

    var userListeners: [(_ user: WellingUser) throws -> Void] = []
    
    init() {
        let auth = Auth
            .auth()
        if auth.currentUser != nil {
            refreshListeners()
        }
        auth.addStateDidChangeListener(authStateHandler)
    }
    
    deinit {
        for listener in allListenerRegistrations {
            listener.remove()
        }
    }
    
    func authStateHandler(auth: Auth, user: User?) {
        guard let user = user else {
            stopAllListeners()
            return
        }
        
        refreshListeners()
    }
    
    func stopAllListeners() {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        
        // Remove existing listeners before listening to new user's objects.
        for listener in allListenerRegistrations {
            listener.remove()
        }
        
        allListenerRegistrations.removeAll()
    }
    
    func refreshListeners() {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        stopAllListeners()
        
        do {
            try initUserState()
            try registerUpdatesToUserState()
            try registerUpdatesToUserListener()
        } catch {
            WLogger.shared.record(error)
        }
    }
    
    func initUserState() throws {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        
        guard let uid = Auth.auth().currentUser?.uid else {
            throw FirestoreDataManagerError.runtimeError("Current user must be logged in before you can listen to updates")
        }
        
        self.db
            .collection("user_state")
            .document(uid)
            .getDocument(completion: onUserStateSnapshot)
    }
    
    func registerUpdatesToUserListener() throws {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        
        guard let uid = Auth.auth().currentUser?.uid else {
            throw FirestoreDataManagerError.runtimeError("Current user must be logged in before you can listen to updates")
        }
        let listener = db
            .collection("users")
            .document(uid)
            .addSnapshotListener(onUserSnapshot)
        allListenerRegistrations.append(listener)
    }
    
    func registerUpdatesToUserState() throws {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        
        guard let uid = Auth.auth().currentUser?.uid else {
            throw FirestoreDataManagerError.runtimeError("Current user must be logged in before you can listen to updates")
        }
        
        // First get current state, add listeners, then listen to changes.
        
        let listener = db
            .collection("user_state")
            .document(uid)
            .addSnapshotListener(onUserStateSnapshot)
        allListenerRegistrations.append(listener)
    }
    
    func registerUpdatesToPendingMessages() throws {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        
        guard let uid = Auth.auth().currentUser?.uid else {
            throw FirestoreDataManagerError.runtimeError("Current user must be logged in before you can listen to updates")
        }
        
        if let _currentListener = pendingMessageListenerRegistration {
            _currentListener.remove()
        }
        
        if pendingMessageIdsInUserState.count == 0 {
            WLogger.shared.log(Self.loggerCategory, "No pending messages to listen to")
            return
        }
        
        let listener = db
            .collection("users")
            .document(uid)
            .collection("messages")
            .whereField("id", in: pendingMessageIdsInUserState)
            .addSnapshotListener(onMessagesQuerySnapshot)
        allListenerRegistrations.append(listener)
        pendingMessageListenerRegistration = listener
    }
    
    private func onMessagesQuerySnapshot(querySnapshot: QuerySnapshot?, error: (any Error)?) {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        
        guard let uid = Auth.auth().currentUser?.uid else {
            Self.logger.error("Current user must be logged in before you can listen to updates")
            return
        }
        
        guard let docs = querySnapshot?.documents else {
            WLogger.shared.record(error)
            Self.logger.error("Error fetching user messages: \(error)")
            return
        }
        
        Task {
            var firebaseMessages: [FirebaseMobileMessage]
            do {
                firebaseMessages = try docs.map { try $0.data(as: FirebaseMobileMessage.self) }
            } catch {
                WLogger.shared.record(error)
                return
            }
            
            let messagesResult: FetchResult<[MobileMessage]> = try await mapFrom(firebaseMessages: firebaseMessages, forUid: uid)
            guard let messages = messagesResult.value else {
                WLogger.shared.error(Self.loggerCategory, "Unable to map firebase message to mobile message: \(String(describing: messagesResult.error))")
                return
            }
            
            for listener in messageUpdateListeners {
                do {
                    try listener(messages)
                } catch {
                    WLogger.shared.record(error)
                }
            }
            
        }
        
    }
    
    private func onUserStateSnapshot(snapshot: DocumentSnapshot?, error: (any Error)?) {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        
        guard let doc = snapshot else {
            WLogger.shared.record(error)
            return
        }
        
        let userState: UserState
        do {
            WLogger.shared.log(Self.loggerCategory, "Decoding user state document snapshot.")
            userState = try doc.data(as: UserState.self)
        } catch {
            if let nsError = error as? NSError {
                if nsError.userInfo.debugDescription.contains("Cannot get keyed decoding container -- found null value instead.") {
                    WLogger.shared.log(Self.loggerCategory, "This user does not yet have a user state document.")
                    // We can ignore this error, we do not yet have a user state, data was empty.
                    return
                }
            }
            WLogger.shared.record(error)
            return
        }
        
        WLogger.shared.log(Self.loggerCategory, "Got user state, listening to docs as needed")
        
        refreshUserState(userState: userState)
    }
    
    private func refreshUserState(userState: UserState) {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        
        // First listen to pending docs, if they are different.
        if userState.pendingMessageIds.count != pendingMessageIdsInUserState.count
            || Set(userState.pendingMessageIds) != Set(pendingMessageIdsInUserState)
        {
            WLogger.shared.log(Self.loggerCategory, "List of pending messages changed, updating listeners")
            
            // Get latest verions, and listen for updates.
            pendingMessageIdsInUserState = userState.pendingMessageIds
            do {
                Task {
                    try await self.getAndUpdateMessagesWith(ids: self.pendingMessageIdsInUserState)
                }
                try registerUpdatesToPendingMessages()
            } catch {
                WLogger.shared.record(error)
            }
        } else {
            WLogger.shared.log(Self.loggerCategory, "Pending messages did not change, not updating listeners")
        }
        
        if userState.processedMessageIds.count > 0 {
            WLogger.shared.log(Self.loggerCategory, "Got \(userState.processedMessageIds.count) processed messages to get")
            // This can be deleted from processed, and latest version updated.
            Task {
                do {
                    let completedMessages = try await self.getAndUpdateMessagesWith(ids: userState.processedMessageIds)
                    
                    if !completedMessages.isEmpty {
                        for listener in messagesCompletedListener {
                            do {
                                try listener(completedMessages)
                            } catch {
                                WLogger.shared.record(error)
                            }
                        }
                    }
                    
                    // now delete it from the doc.
                    WLogger.shared.log(Self.loggerCategory, "Removing messages from processed messages array")
                    
                    try await db
                        .collection("user_state")
                        .document(userState.uid)
                        .updateData([
                            "processedMessageIds": FieldValue.arrayRemove(userState.processedMessageIds)
                        ])
                    
                    WLogger.shared.log(Self.loggerCategory, "Removed processed messages from array")
                } catch {
                    WLogger.shared.record(error)
                }
            }
        } else {
            WLogger.shared.log(Self.loggerCategory, "Number of processed message IDs is 0")
        }
    }
    
    private func onUserSnapshot(snapshot: DocumentSnapshot?, error: (any Error)?) {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        
        guard let doc = snapshot else {
            WLogger.shared.log(Self.loggerCategory, "Snapshot is empty.")
            WLogger.shared.record(error)
            return
        }
        
        if doc.metadata.isFromCache {
            // Ignore.
            return
        }
        
        var user: WellingUser
        do {
            user = try doc.data(as: WellingUser.self)
        } catch {
            if let nsError = error as? NSError {
                if nsError.userInfo.debugDescription.contains("Cannot get keyed decoding container -- found null value instead.") {
                    WLogger.shared.log(Self.loggerCategory, "The user document was empty.")
                    return
                }
            }
            
            WLogger.shared.record(error)
            return
        }
        
        WLogger.shared.log(Self.loggerCategory, "Got user snapshot")
        
        for listener in userListeners {
            do {
                try listener(user)
            } catch {
                WLogger.shared.record(error)
            }
        }
    }
    
    private func getAndUpdateMessagesWith(ids: [String]) async throws -> [MobileMessage] {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")

        let messages = try await getMessagesWith(ids: ids)
        if let error = messages.error {
            WLogger.shared.record(error.cause)
            return []
        }
        guard let _messages = messages.value else {
            Self.logger.error("Was expecting to load messages with ids, but response was empty")
            return []
        }
        if _messages.count != ids.count {
            Self.logger.warning("Was expecting \(ids.count) messages, but only got \(_messages.count). Continuing.")
        }
        
        for listener in messageUpdateListeners {
            do {
                try listener(_messages)
            } catch {
                WLogger.shared.record(error)
            }
        }
        
        return _messages
    }
    
    func getMe() async throws -> FetchResult<WellingUser> {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        
        guard let uid = Auth.auth().currentUser?.uid else {
            return returnUnauthenticated()
        }
        
        let docRef = db.collection("users").document(uid)
        
        do {
            let document = try await docRef.getDocument()
            if !document.exists {
                return FetchResult(value: nil, error: ResultError(title: "Not Found", message: "That user was not found.", cause: nil), statusCode: 404, unauthenticated: false)
            }
            
            return try FetchResult(value: document.data(as: WellingUser.self), error: nil, statusCode: 200, unauthenticated: false)
        } catch {
            WLogger.shared.record(error)
            return returnUnexpectedError(cause: error)
        }
    }
    
    func getMessagesSince(timestamp: Date) async throws -> FetchResult<[MobileMessage]> {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        
        guard let uid = Auth.auth().currentUser?.uid else {
            return returnUnauthenticated()
        }
        
        do {
            let result = try await db
                .collection("users")
                .document(uid)
                .collection("messages")
                .whereField("timestamp", isGreaterThanOrEqualTo: timestamp)
                .order(by: "timestamp", descending: true)
                .getDocuments()
            
            let messagesResult: FetchResult<[MobileMessage]> = try await mapFrom(firebaseMessages: result.documents.map { try $0.data(as: FirebaseMobileMessage.self) }, forUid: uid)
            
            guard let messages = messagesResult.value else {
                WLogger.shared.record(messagesResult.error?.cause)
                return messagesResult.withoutValue()
            }
            
            return FetchResult(value: messages)
        } catch {
            WLogger.shared.record(error)
            return returnUnexpectedError(cause: error)
        }
    }
    
    func getMessagesWith(ids: [String]) async throws -> FetchResult<[MobileMessage]> {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        
        guard let uid = Auth.auth().currentUser?.uid else {
            return returnUnauthenticated()
        }
        
        if ids.count == 0 {
            return FetchResult(value: [], error: nil, statusCode: 200, unauthenticated: false)
        }
        
        do {
            async let allMessagesProm = try db
                .collection("users")
                .document(uid)
                .collection("messages")
                .whereField("id", in: ids)
                .getDocuments()
            async let foodLogFoodsProm = getFoodsForMessages(uid: uid, ids: ids)
            
            let (allMessagesResult, foodLogFoodsResult) = try await (allMessagesProm, foodLogFoodsProm)
            
            let allMessagses = try allMessagesResult.documents.map { try $0.data(as: FirebaseMobileMessage.self) }
            
            if let error = foodLogFoodsResult.error {
                WLogger.shared.record(error.cause)
                return foodLogFoodsResult.withoutValue()
            }
            
            guard let foodLogFoodsById = foodLogFoodsResult.value else {
                return foodLogFoodsResult.withoutValue()
            }
            
            var mappedMessages: [MobileMessage] = []
            for message in allMessagses {
                var foodLog: MobileFoodLogEntry? = nil
                var favoriteFood: MobileFoodLogEntry? = nil
                
                if let foodLogFood: [FoodLogFood] = foodLogFoodsById[message.id] {
                    if let messageFoodLog = message.foodLog {
                        foodLog = MobileFoodLogEntry(firebase: messageFoodLog, foods: foodLogFood.filter({$0.foodLogId == messageFoodLog.id}))
                    }
                    
                    if let messageFavoriteFoodLog = message.favoriteFood {
                        favoriteFood = MobileFoodLogEntry(firebase: messageFavoriteFoodLog, foods: foodLogFood.filter({$0.foodLogId == messageFavoriteFoodLog.id}))
                    }
                }
                
                mappedMessages.append(MobileMessage(firebase: message, foodLog: foodLog, favoriteFood: favoriteFood))
            }
            
            return FetchResult(value: mappedMessages, error: nil, statusCode: 200, unauthenticated: false)
        } catch {
            WLogger.shared.record(error)
            return returnUnexpectedError(cause: error)
        }
    }
    
    private func getFoodsForMessages(uid: String, ids: [String]) async throws -> FetchResult<[String:[FoodLogFood]]> {
        if ids.count == 0 {
            return FetchResult(value: [String:[FoodLogFood]](), error: nil, statusCode: 200, unauthenticated: false)
        }
        
        do {
            let result = try await db
                .collection("users")
                .document(uid)
                .collection("food_log_foods")
                .whereField("messageId", in: ids)
                .getDocuments()
            
            var byId: [String:[FoodLogFood]] = [String:[FoodLogFood]]()
            
            for doc in result.documents {
                let foodLogFood = try doc.data(as: FoodLogFood.self)
                byId[foodLogFood.messageId, default: []].append(foodLogFood)
            }
            
            return FetchResult(value: byId)
        } catch {
            WLogger.shared.record(error)
            return returnUnexpectedError(cause: error)
        }
    }
    
    func getMostRecentMessageTimestamp() async throws -> FetchResult<Date?> {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        
        guard let uid = Auth.auth().currentUser?.uid else {
            return returnUnauthenticated()
        }
        
        do {
            let lastMessageResult = try await db
                .collection("users")
                .document(uid)
                .collection("messages")
                .order(by: "timestamp", descending: true)
                .limit(to: 1)
                .getDocuments()
            
            if lastMessageResult.isEmpty {
                return FetchResult(value: nil)
            }
            
            let parsedMessage: MobileMessage = try lastMessageResult.documents[0].data(as: MobileMessage.self)
            return FetchResult(value: parsedMessage.timestamp)
        } catch {
            WLogger.shared.record(error)
            return returnUnexpectedError(cause: error)
        }
    }
    
    func getMessage(withId: String) async throws -> FetchResult<MobileMessage> {
        guard let uid = Auth.auth().currentUser?.uid else {
            return returnUnauthenticated()
        }
        
        do {
            async let messageResultProm = db
                .collection("users")
                .document(uid)
                .collection("messages")
                .document(withId)
                .getDocument(as: FirebaseMobileMessage.self)
            
            async let foodLogFoodsProm = getFoodsForMessage(uid: uid, messageId: withId)
            
            let (message, foodLogFoodsResult) = try await (messageResultProm, foodLogFoodsProm)
            
            if let error = foodLogFoodsResult.error {
                WLogger.shared.record(error.cause)
                return foodLogFoodsResult.withoutValue()
            }
            
            guard let foodLogFoods = foodLogFoodsResult.value else {
                return foodLogFoodsResult.withoutValue()
            }
            
            var foodLog: MobileFoodLogEntry? = nil
            var favoriteFood: MobileFoodLogEntry? = nil
            
            if let messageFoodLog = message.foodLog {
                foodLog = MobileFoodLogEntry(firebase: messageFoodLog, foods: foodLogFoods.filter({$0.foodLogId == messageFoodLog.id}))
            }
            
            if let messageFavoriteFoodLog = message.favoriteFood {
                favoriteFood = MobileFoodLogEntry(firebase: messageFavoriteFoodLog, foods: foodLogFoods.filter({$0.foodLogId == messageFavoriteFoodLog.id}))
            }
            
            return FetchResult(value: MobileMessage(firebase: message, foodLog: foodLog, favoriteFood: favoriteFood))
        } catch {
            WLogger.shared.record(error)
            return returnUnexpectedError(cause: error)
        }
    }
    
    private func getFoodsForMessage(uid: String, messageId: String) async throws -> FetchResult<[FoodLogFood]> {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        
        do {
            let result = try await db
                .collection("users")
                .document(uid)
                .collection("food_log_foods")
                .whereField("messageId", isEqualTo: messageId)
                .getDocuments()
            
            if result.isEmpty || result.documents.count > 1 {
                WLogger.shared.log(Self.loggerCategory, "Results was empty or > 1")
                return FetchResult(value: nil, error: .init(title: "Unknown", message: "Unknown error, please try again.", cause: nil), statusCode: 500, unauthenticated: false)
            }
            
            var docs: [FoodLogFood] = try result.documents.map({try $0.data(as: FoodLogFood.self)})
            
            return FetchResult(value: docs)
        } catch {
            WLogger.shared.record(error)
            return returnUnexpectedError(cause: error)
        }
    }
    
    private func mapFrom(firebaseMessages: [FirebaseMobileMessage], forUid: String) async throws -> FetchResult<[MobileMessage]> {
        WLogger.shared.log(Self.loggerCategory, "Mapping \(firebaseMessages.count) messages")
        var messages: [MobileMessage] = []
        
        // We can only do this 30 messages at a time
        let batchSize: Int = 30
        var messagesWithFoodLog = Array(firebaseMessages.filter({$0.foodLog != nil}).map({$0.id}))
        WLogger.shared.log(Self.loggerCategory, "\(messagesWithFoodLog.count) messages with food logs")
        var foodLogFoodsById: [String:[FoodLogFood]] = [:]
        
        while messagesWithFoodLog.count > 0 {
            let numToRemove = min(batchSize, messagesWithFoodLog.count)
            let batch: [String] = Array(messagesWithFoodLog.prefix(numToRemove))
            messagesWithFoodLog.removeFirst(numToRemove)
            
            WLogger.shared.log(Self.loggerCategory, "Retrieving food log foods for \(batch.count) food logs")
            let foodLogFoodsResult: FetchResult<[String:[FoodLogFood]]> = try await getFoodsForMessages(uid: forUid, ids: batch)
            
            guard let foodLogFoods = foodLogFoodsResult.value else {
                WLogger.shared.record(foodLogFoodsResult.error?.cause)
                return foodLogFoodsResult.withoutValue()
            }
            
            WLogger.shared.log(Self.loggerCategory, "Got food log foods for \(foodLogFoods.count) food logs")
            
            for foodLogFood in foodLogFoods {
                foodLogFoodsById[foodLogFood.key] = foodLogFood.value
            }
        }
        
        for message in firebaseMessages {
            var foodLog: MobileFoodLogEntry? = nil
            var favoriteFood: MobileFoodLogEntry? = nil
            
            if let foodLogFood: [FoodLogFood] = foodLogFoodsById[message.id] {
                if let messageFoodLog = message.foodLog {
                    foodLog = MobileFoodLogEntry(firebase: messageFoodLog, foods: foodLogFood.filter({$0.foodLogId == messageFoodLog.id}))
                }
                
                if let messageFavoriteFoodLog = message.favoriteFood {
                    favoriteFood = MobileFoodLogEntry(firebase: messageFavoriteFoodLog, foods: foodLogFood.filter({$0.foodLogId == messageFavoriteFoodLog.id}))
                }
            }
            
            messages.append(MobileMessage(firebase: message, foodLog: foodLog, favoriteFood: favoriteFood))
        }
        
        return FetchResult(value: messages)
    }
    
    func create(message: MobileMessage) async throws -> FetchResult<Bool> {
        guard let uid = Auth.auth().currentUser?.uid else {
            return returnUnauthenticated()
        }
        
        try await db
            .collection("users")
            .document(uid)
            .collection("messages")
            .addDocument(data: encoder.encode(message))
        
        try await db
            .collection("user_state")
            .document(uid)
            .updateData([
                "processedMessageIds": FieldValue.arrayUnion([message.id])
            ])
        
        return FetchResult(value: true, error: nil, statusCode: 200, unauthenticated: false)
    }
    
    func listenForUpdatesToMessages(listener: @escaping (_ messages: [MobileMessage]) -> Void) {
        messageUpdateListeners.append(listener)
    }
    func listenForCompletedMessages(listener: @escaping (_ messages: [MobileMessage]) -> Void) {
        messagesCompletedListener.append(listener)
    }
    
    func listenForUpdatesToUser(listener: @escaping (_ user: WellingUser) -> Void) {
        userListeners.append(listener)
    }
    
    private func returnUnexpectedError<T>(cause: Error?) -> FetchResult<T> {
        return FetchResult<T>(
            value: nil,
            error: ResultError(title: "Unexpected Erorr", message: "Please try agian.", cause: cause),
            statusCode: 0,
            unauthenticated: false)
    }
    
    private func returnNotFoundError<T>(cause: Error?) -> FetchResult<T> {
        return FetchResult<T>(
            value: nil,
            error: ResultError(title: "Not Found", message: "This item was not found.", cause: cause),
            statusCode: 404,
            unauthenticated: false)
    }
    
    func returnUnauthenticated<T>() -> FetchResult<T> {
        return FetchResult<T>(
            value: nil,
            error: ResultError(
                title: NSLocalizedString("Unauthorized", comment: "Title for an unauthorized action modal."),
                message: NSLocalizedString("You must be logged in to perform this action.", comment: "Message for an unauthorized action modal."),
                cause: nil),
            statusCode: 401,
            unauthenticated: false)
    }
    
    func returnSuccessfullVoid<Void>() -> FetchResult<Void> {
        return FetchResult<Void>(
            value: nil,
            error: nil,
            statusCode: 200,
            unauthenticated: false)
    }
}

enum FirestoreDataManagerError: Error {
    case runtimeError(String)
}

extension FirestoreDataManagerError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .runtimeError (let message):
            return message
        }
    }
}

extension FirestoreDataManagerError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .runtimeError (let message):
            return NSLocalizedString(message, comment: "none")
        }
    }
}
