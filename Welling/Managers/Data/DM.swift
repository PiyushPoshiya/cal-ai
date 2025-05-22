//
//  RealmDataManager.swift
//  Welling
//
//  Created by Irwin Billing on 2024-05-25.
//

import Foundation
import os
import RealmSwift
import Mixpanel
import StoreKit
import FirebaseMessaging
import FirebaseAuth

@MainActor
class DM: ObservableObject {
    static let loggerCategory = String(describing: DM.self)
    static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: loggerCategory
    )

    static let LOAD_ENTIRE_HISTORY: Bool = false
    
    static let shared: DM = .init()

    var realm: Realm
    var uid: String = ""
    let fetchManager: FetchManager = .global
    let firestore: FirestoreDataManager = .init()
    let cloudstore: CloudstoreManager = .init()
    var um: UserManager = .notLoggedIn
    var userListener: (_ user: WellingUser) throws -> Void = { user in
    }
    var alreadyListeningToMessages: Bool = false

    @MainActor
    init() {
        var config = Realm.Configuration.defaultConfiguration
        config.schemaVersion = 8
        Realm.Configuration.defaultConfiguration = config
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            realm = PreviewRealm.previewRealm
        } else {
            realm = try! Realm()
        }
        #else
        realm = try! Realm()
        #endif
        
        Auth.auth().addStateDidChangeListener(authStateHandler)
        NotificationCenter.default.addObserver(forName: .fcmToken, object: nil, queue: nil) { notification in
            let userInfo = notification.userInfo
            Task { @MainActor in
                self.fcmTokenNotificationHandler(userInfo: userInfo)
            }
        }
    }

    @MainActor
    func set(um: UserManager) {
        if self.uid == um.user.uid {
            return
        }

        self.um = um
        
        self.switchRealm(toUid: um.user.uid)

        if alreadyListeningToMessages {
            return
        }

        let messaging: Messaging = Messaging.messaging()
        
        messaging.token { token, error in
            if let error = error {
                Self.logger.error("Error getting messaging token: \(error)")
                return
            }
            if let token = token {
                self.fcmTokenUpdatedHandler(token)
            }
        }

        alreadyListeningToMessages = true
        onUserSnapshot(user: self.um.user)

        firestore.listenForUpdatesToMessages(listener: onMessagesSnapshot)
        firestore.listenForCompletedMessages(listener: onMessagesCompleted)
        firestore.listenForUpdatesToUser(listener: onUserSnapshot)
    }
    
    private func switchRealm(toUid: String) {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        self.uid = um.user.uid
        
        var config = Realm.Configuration.defaultConfiguration
        config.fileURL!.deleteLastPathComponent()
        config.fileURL!.appendPathComponent(uid)
        config.fileURL!.appendPathExtension("realm")
        Realm.Configuration.defaultConfiguration = config

        WLogger.shared.log(Self.loggerCategory, "Switching realm from \(String(describing: self.realm.configuration.fileURL)) to \(String(describing: config.fileURL))")
        
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            realm = PreviewRealm.previewRealm
        } else {
            realm = try! Realm(configuration: config)
        }
        #else
        realm = try! Realm(configuration: config)
        #endif
    }
    
    func authStateHandler(auth: Auth, user: FirebaseAuth.User?) {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        // print "auth state changed", and which user is logged in
        WLogger.shared.log(Self.loggerCategory, "auth state changed, user: \(user?.uid ?? "nil")")

        guard let user = user else {
            return
        }

        Task { @MainActor in
            if self.uid == user.uid {
                return
            }
            
            WLogger.shared.log(Self.loggerCategory, "Current user changed, recreating realm")
            self.switchRealm(toUid: user.uid)
        }
    }

    @MainActor
    func clearRealm() async throws {
        try await self.realm.asyncWrite {
            self.realm.deleteAll()
        }
    }

    deinit {
    }

    @MainActor
    func saveMessageForSending(message: MobileMessage, localImagePath: String?) async throws {
        if let localImagePath = localImagePath {
            let fbFullPath = cloudstore.getCloudstoreFullPathForImage(withName: "\(message.id).\(URL(string: localImagePath)!.pathExtension)", forUid: uid)
            message.image = MobileMessageImage(localPath: localImagePath, fbFullPath: fbFullPath, downloadURL: nil, state: .saved)
        }

        try await realm.asyncWrite {
            self.realm.add(message)
        }
    }


    @MainActor
    func sendMessage(message: MobileMessage) async throws -> FetchResult<Void> {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")

        var newMessageRequest = NewMessageRequest(_version: message._version, id: message.id, text: message.text, mealHint: message.mealHint, replyingToMessageId: message.replyingToMessageId, image: nil)


        if let image = message.image {

            do {
                try await updateMessageImageUploadState(message: message, state: .uploading)

                try await cloudstore.upload(localPath: image.localPath, fbFullPath: image.fbFullPath)

                let downloadURL = try await cloudstore.getDownloadURL(url: image.fbFullPath)
                newMessageRequest.image = NewMessageReestImage(localPath: image.localPath, fbFullPath: image.fbFullPath, downloadURL: downloadURL.absoluteString, state: image.state)

                try await setMessageImageUploaded(message: message, downloadURL: downloadURL)
            } catch {
                WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")

                return FetchResult(value: nil, error: ResultError(title: "Couldn't upload", message: "Please try again.", cause: error), statusCode: 500, unauthenticated: false)
            }
            // Decided not to delete file and just keep them locally.
//            do {
//                try FileManager.default.removeItem(atPath: URL.documentsDirectory.appending(path: image.localPath).path)
//            } catch {
//                Self.logger.error("Could not delete local image, ignoring: \(error)")
//            }
        }

        return await fetchManager.sendMessage(message: newMessageRequest)
    }


    @MainActor
    func updateMessageState(message: MobileMessage, state: MessageProcessingState) async throws {
        try await realm.asyncWrite {
            message.state = state
        }
    }


    @MainActor
    func updateMessageImageUploadState(message: MobileMessage, state: ImageProcessingState) async throws {
        try await realm.asyncWrite {
            if let _ = message.image {
                message.image!.state = state
            }
        }
    }

    @MainActor
    func setMessageImageUploaded(message: MobileMessage, downloadURL: URL) async throws {
        try await realm.asyncWrite {
            if let _ = message.image {
                message.image!.state = .uploaded
                message.image!.downloadURL = String(downloadURL.absoluteString)
            }
        }
    }

    func queryLatestChatHistory(count: Int) -> [MobileMessage] {
        let allMessages = realm
            .objects(MobileMessage.self)
            .sorted(byKeyPath: "timestamp", ascending: true)

        var messages: [MobileMessage] = []
        let allMessagesCount = allMessages.count

        WLogger.shared.error(Self.loggerCategory, "Loading \(count) messages from a total of \(allMessagesCount) messages")
        // count = 900, allMessagesCount = 150
        // numToAppend = 150
        // 50, 49, ... 1
        // allMessages[150 - 150 ... 150-1]
        let numToAppend = min(count, allMessagesCount)

        if numToAppend == 0 {
            return messages
        }

        for i in (1...numToAppend).reversed() {
            messages.append(allMessages[allMessagesCount - i])
        }

        return messages
    }

    @MainActor
    func loadLatestChatHistory() async throws -> ResultError? {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")

        // TODO, query should be lastSeenMessage.timestamp and before now
        let since: Date = loadMostRecentMessageTimestamp(uid: self.uid)
        let chatHistoryResult = try await firestore.getMessagesSince(timestamp: since)
        if let error = chatHistoryResult.error {
            Self.logger.error("Error loading latest chat history messages: \(error.cause)")
            return error
        }

        guard let chatHistory = chatHistoryResult.value else {
            Self.logger.error("Non error but did not have a body")
            return ResultError(title: "Unknown Error", message: "Please try again.", cause: nil)
        }

        if chatHistory.isEmpty {
            return nil
        }

        do {
            WLogger.shared.log(Self.loggerCategory, "Read \(chatHistory.count) messages")
            try await realm.asyncWrite {
                for chat in chatHistory {
                    realm.add(chat, update: .modified)
                }
            }

            if let mostRecentMessage = chatHistory.first {
                saveMostRecentMessageSeenTimestamp(uid: self.uid, timestamp: mostRecentMessage.timestamp)
            }
        } catch {
            WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")

            return ResultError(title: "Unknown Error", message: "Please try again.", cause: error)
        }

        return nil
    }

    private func onMessagesSnapshot(messages: [MobileMessage]) {
        Task { @MainActor in
            try await realm.asyncWrite {
                for message in messages {
                    self.realm.add(message, update: .modified)
                }
            }
        }
    }

    private func onMessagesCompleted(messages: [MobileMessage]) {
    }

    @MainActor
    func saveMessage(message: MobileMessage) async throws {
        try await realm.asyncWrite {
            self.realm.add(message, update: .modified)
        }
    }

    @MainActor
    func onUserSnapshot(user: WellingUser) {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        Task { @MainActor in
            do {
               try await realm.asyncWrite {
                    self.realm.add(user, update: .modified)
                }
                try userListener(user)

                self.updateMixpanelUser(user: user)
            } catch {
                WLogger.shared.record(error)
            }
        }

    }

    @MainActor
    func fcmTokenNotificationHandler(userInfo: [AnyHashable: Any]?) {
        if let token = userInfo?["token"] as? String {
            self.fcmTokenUpdatedHandler(token)
        }
    }

    func fcmTokenUpdatedHandler(_ token: String) {
        if token == um.user.fcmToken {
            WLogger.shared.log(Self.loggerCategory, "Not updating fcmToken, it is still the same")
            return
        }

        if !um.isLoggedIn && !um.isLoggedInAnonymously {
            WLogger.shared.log(Self.loggerCategory, "Not updating FCM token, we're not signed in")
            return
        }
        
        WLogger.shared.log(Self.loggerCategory, "Updating FCM token")

        Task { @MainActor in
            try await self.update(user: um.user, fcmToken: token)
        }
    }

    @MainActor
    func updateMixpanelUser(user: WellingUser) {
        var properties: [String: MixpanelType] = [:]
        properties["$name"] = user.profile?.name
        properties["nanoId"] = user.nanoId
        if let profile = user.profile {
            properties["$name"] = profile.name
            properties["preferredUnits"] = profile.preferredUnits.rawValue
            properties["age"] = profile.age
            properties["height"] = profile.height
            properties["gender"] = profile.gender.rawValue
            properties["dietaryPreference"] = profile.dietaryPreference
            properties["goal"] = profile.goal.rawValue
            properties["activityLevel"] = profile.activityLevel?.rawValue
            properties["usedCalorieCountingAppBefore"] = profile.usedCalorieCountingAppBefore
            properties["usedNutritionCoachBefore"] = profile.usedNutritionCoachBefore
            properties["mainReasonToBecomeHealthier"] = profile.mainReasonToBecomeHealthier
            properties["mainReasonToLoseWeight"] = profile.mainReasonToLoseWeight
            properties["mainReasonToBuildMuscle"] = profile.mainReasonToBuildMuscle
            properties["mainReasonToKeepFit"] = profile.mainReasonToKeepFit
            properties["importantEventComingUp"] = profile.importantEventComingUp
            properties["howDidYouHearAboutWelling"] = profile.howDidYouHearAboutWelling
            properties["whichCommunityDidYouHearAboutFrom"] = profile.whichCommunityDidYouHearAboutFrom
            properties["appVersion"] = getAppVersionString()
        }

        if let geo = user.geo {
            properties["country"] = geo.country
            properties["city"] = geo.city
        }

        Mixpanel.mainInstance().people.set(properties: properties)
    }

    private func loadMostRecentMessageTimestamp(uid: String) -> Date {
        return Date(timeIntervalSince1970: UserDefaults.standard.double(forKey: "\(uid)/most_recent_message_seen_timestamp"))
    }

    private func saveMostRecentMessageSeenTimestamp(uid: String, timestamp: Date) {
        UserDefaults.standard.set(timestamp.timeIntervalSince1970, forKey: "\(uid)/most_recent_message_seen_timestamp")
    }
}
