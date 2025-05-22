//
//  Untitled.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-14.
//

import Foundation
import FirebaseStorage
import os

class CloudstoreManager {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: CloudstoreManager.self))
   
    let storage: Storage
    
    init() {
        storage = Storage.storage()
    }
    
    /**
     Upload an iamge to firebase.
     @returns the  path to the firebase document.
     */
    func upload(localPath: String, fbFullPath: String) async throws  {
        let localFilePath =  URL.documentsDirectory.appending(path: localPath)
        
        let imageRef = storage.reference(forURL: fbFullPath)
        
        let _ = try await imageRef.putFileAsync(from: localFilePath, metadata: nil)
    }
    
    func getCloudstoreFullPathForImage(withName: String, forUid: String) -> String {
        let ref = getCloudstoreRefForImage(withName: withName, forUid: forUid)
        return "gs://\(ref.bucket)/\(ref.fullPath)"
    }
    
    func getDownloadURL(url: String) async throws -> URL {
        return try await storage.reference(forURL: url).downloadURL()
    }
    
    private func getCloudstoreRefForImage(withName: String, forUid: String) -> StorageReference {
        let fbPath: String = "/users/\(forUid)/images/\(withName)"
        let imageRef: StorageReference = storage.reference().child(fbPath)
        return imageRef
    }
}
