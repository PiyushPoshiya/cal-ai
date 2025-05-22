//
//  WRemoteConfig.swift
//  Welling
//
//  Created by Irwin Billing on 2024-05-16.
//

import Foundation
import FirebaseRemoteConfig

class WRemoteConfig {
    
    static var remoteConfig: RemoteConfig {
        let c = RemoteConfig.remoteConfig()
        
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 60 * 60
        c.configSettings = settings
        
        c.setDefaults(fromPlist: "remote_config_defaults")
        return c
    }
    
    init() {
    }
    
    func getSignUpTypeFormId(n: String) throws -> String {
        let val = Self.remoteConfig.configValue(forKey: "signup_typeform_id")
        guard let strVal = val.stringValue else {
            throw NSError(domain: "WRemoteConfig", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to find config value for 'signup_typeform_id'"])
        }
        
        return strVal
    }
}
