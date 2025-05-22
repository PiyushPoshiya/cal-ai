/*
See the License.txt file for this sample’s licensing information.
*/

import Photos
import os.log

class PhotoLibrary {
    private static let haveRequestedAccessKey: String = "PhotoLibrary.haveRequestedAccess"
    private static let haveAccessKey: String = "PhotoLibrary.haveAccess"

    static func checkAuthorization() async -> Bool {
//        if Self.haveRequestedAccess() {
//            return self.haveAccess()
//        }
//        
//        let accessGranted: Bool = await Self.requestAccess()
//        Self.setHaveRequestedAccess()
//        Self.setHaveAccess(access: accessGranted)
//        
//        return accessGranted
        
        return await Self.requestAccess()
    }
    
    static func requestAccess() async -> Bool {
        switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
        case .authorized:
            return true
        case .notDetermined:
            let result = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            return result == .authorized || result == .limited
        case .denied:
            return false
        case .limited:
            return true
        case .restricted:
            return false
        @unknown default:
            return false
        }
    }
    
    static func haveRequestedAccess() -> Bool {
        return UserDefaults.standard.bool(forKey: haveRequestedAccessKey)
    }
    
    static func setHaveRequestedAccess() {
        UserDefaults.standard.setValue(true, forKey: haveRequestedAccessKey)
    }
    
    static func haveAccess() -> Bool {
        return UserDefaults.standard.bool(forKey: haveAccessKey)
    }
    
    static func setHaveAccess(access: Bool) {
        UserDefaults.standard.setValue(access, forKey: haveAccessKey)
    }
}

fileprivate let logger = Logger(subsystem: "com.apple.swiftplaygroundscontent.capturingphotos", category: "PhotoLibrary")

