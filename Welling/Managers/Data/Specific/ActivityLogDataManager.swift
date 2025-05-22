//
//  ActivityLogDataManager.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-24.
//

import FirebaseAuth
import FirebaseFirestore
import Foundation
import os
import RealmSwift

extension DM {
    @MainActor
    func update(activityLog: MobilePhysicalActivityLog, caloriesExpended: Double) async throws -> Void {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        
        let now = Date.now
        
        let id = activityLog.id
        
        if let activityLog = activityLog.thaw() {
            try await realm.asyncWrite {
                activityLog.caloriesExpended = caloriesExpended
                activityLog.dateUpdated = now
            }
            
            Task {
                do {
                    try await firestore.update(activityLogWithId: id, caloriesExpended: caloriesExpended, dateUpdated: now)
                } catch {
                    WLogger.shared.record(error)
                }
            }
        }
    }
    
    @MainActor
    func delete(activityLog: MobilePhysicalActivityLog) async throws -> Void {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        
        let now = Date.now
        let id = activityLog.id
        
        if let activityLog = activityLog.thaw() {
            try await realm.asyncWrite {
                activityLog.dateDeleted = now
            }
            
            Task {
                do {
                    try await firestore.delete(activityLogWithId: id, dateDeleted: now)
                } catch {
                    WLogger.shared.record(error)
                }
            }
        }
    }
}


extension FirestoreDataManager {
    func update(activityLogWithId: String, caloriesExpended: Double, dateUpdated: Date) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw FirestoreDataManagerError.runtimeError("Current user must be logged")
        }
        
        try await db
            .collection("users")
            .document(uid)
            .collection("messages")
            .document(activityLogWithId)
            .updateData([
                "activityLog.caloriesExpended": caloriesExpended,
                "activityLog.dateUpdated": dateUpdated
            ])
    }
    
    func delete(activityLogWithId: String, dateDeleted: Date) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw FirestoreDataManagerError.runtimeError("Current user must be logged")
        }
        
        try await db
            .collection("users")
            .document(uid)
            .collection("messages")
            .document(activityLogWithId)
            .updateData([
                "activityLog.dateDeleted": dateDeleted
            ])
    }
}
