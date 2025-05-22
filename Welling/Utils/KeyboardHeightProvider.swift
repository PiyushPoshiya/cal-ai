//
//  KeyboardHeightProvider.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-07.
//

import Foundation
import SwiftUI

class KeyboardHeightProvider: ObservableObject {
    @Published var keyboardHeight: CGFloat = 0

    init() {
//        if let keyboardHeight = UserDefaults.standard.keyboardHeight {
//            self.keyboardHeight = CGFloat(keyboardHeight)
//        } else {
//            self.keyboardHeight = 300
//        }
        self.keyboardHeight = 290
//        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear), name: UIResponder.keyboardWillShowNotification, object: nil)
    }

    @objc func keyboardWillAppear(notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            NotificationCenter.default.removeObserver(self)
            if keyboardSize.height == keyboardHeight {
                return
            }
            UserDefaults.standard.keyboardHeight = Float(keyboardSize.height)
            keyboardHeight = keyboardSize.height
        }
    }
}

// MARK: - Keys

extension UserDefaults {
    private enum Keys {
        static let keyboardHeight = "keyboardHeight"
    }
}

// MARK: - keyboardHeight

extension UserDefaults {
    var keyboardHeight: Float? {
        get {
            float(forKey: Keys.keyboardHeight)
        }
        set {
            set(newValue, forKey: Keys.keyboardHeight)
        }
    }
}
