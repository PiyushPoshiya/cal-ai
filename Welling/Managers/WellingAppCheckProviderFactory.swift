//
//  WellingAppCheckProviderFactory.swift
//  Welling
//
//  Created by Irwin Billing on 2024-07-06.
//

import Foundation
import Firebase
import FirebaseAppCheck

class WellingAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
      return AppAttestProvider(app: app)
    }
  }
