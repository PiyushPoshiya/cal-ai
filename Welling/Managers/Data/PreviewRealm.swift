//
//  PreviewRealm.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-03.
//

import Foundation
import RealmSwift

class PreviewRealm {
    static var user: WellingUser = {
        do {
            let decoder = JSONDecoder()
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX") //1
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            decoder.dateDecodingStrategy = .formatted(formatter)

            let userUrl = Bundle.main.url(forResource: "user", withExtension: "json", subdirectory: "static/sample-data")!
            let data = try Data(contentsOf: userUrl)
            return try decoder.decode(WellingUser.self, from: data)
        } catch {
            return WellingUser.sample
        }
    }()

    static var messages: [MobileMessage] = {
        do {
            let decoder = JSONDecoder()
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX") //1
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            decoder.dateDecodingStrategy = .formatted(formatter)

            let messagesUrl = Bundle.main.url(forResource: "message-history", withExtension: "json", subdirectory: "static/sample-data")!
            let data = try Data(contentsOf: messagesUrl)
            return try decoder.decode([MobileMessage].self, from: data)
        } catch {
            return []
        }
    }()

    static var previewRealm: Realm {
        var realm: Realm
        let identifier = "previewRealm"
        let config = Realm.Configuration(inMemoryIdentifier: identifier)
        do {
            realm = try Realm(configuration: config)
            // Check to see whether the in-memory realm already contains a Person.
            // If it does, we'll just return the existing realm.
            // If it doesn't, we'll add a Person append the Dogs.

            // First setup the user
            let realmUsers: Results<WellingUser> = realm.objects(WellingUser.self)
            if realmUsers.count == 0 {
                try realm.write {
                    realm.add(user)
                }
            }

            let realmMessages: Results<MobileMessage> = realm.objects(MobileMessage.self)
            if realmMessages.count == 0 {
                try realm.write {
                    realm.add(messages)
                }
            }

            // Setup some chat messages
            return realm
        } catch let error {
            fatalError("Can't bootstrap item data: \(error.localizedDescription)")
        }
    }
}
