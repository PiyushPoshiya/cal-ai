//
//  WLogger.swift
//  Welling
//
//  Created by Irwin Billing on 2024-08-02.
//

import Foundation
import os
import FirebaseCrashlytics

struct WLogger {
    static let shared = WLogger()
    static let crashlytics: Crashlytics = Crashlytics.crashlytics()

    func log(_ category: String, _ msg: String) {
        let logMessage = "[\(category)] - \(Date.now.ISO8601Format()) - \(msg)"
        Self.crashlytics.log(logMessage)
        print(logMessage)
    }

    func error(_ category: String, _ msg: String) {
        let logMessage = "[\(category)] - \(Date.now.ISO8601Format()) - ERROR - \(msg)"
        Self.crashlytics.log(logMessage)
        print(logMessage)
    }

    func record(_ error: (any Error)?) {
        if let error = error {
            self.error("unknown", error.localizedDescription)
            Self.crashlytics.record(error: error, userInfo: ["description": error.localizedDescription])
            print(error)
        }
    }
}
