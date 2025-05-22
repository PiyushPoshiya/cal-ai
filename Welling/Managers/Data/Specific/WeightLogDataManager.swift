//
//  WeightLogDataManager.swift
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
    func update(weightLog: MobileWeightLog, weightInKg: Double) async throws -> Void {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        
        let now = Date.now
        
        let id = weightLog.id
        
        if let weightLog = weightLog.thaw() {
            try await realm.asyncWrite {
                weightLog.weightInKg = weightInKg
                weightLog.dateUpdated = now
            }
            
            Task {
                do {
                    try await firestore.update(weightLogWithId: id, weightInKg: weightInKg, dateUpdated: now)
                } catch {
                    WLogger.shared.record(error)
                }
            }
        }
    }
    
    @MainActor
    func delete(weightLog: MobileWeightLog) async throws -> Void {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        
        let now = Date.now
        let id = weightLog.id
        
        if let weightLog = weightLog.thaw() {
            try await realm.asyncWrite {
                weightLog.dateDeleted = now
            }
            
            Task {
                do {
                    try await firestore.delete(weightLogWithId: id, dateDeleted: now)
                } catch {
                    WLogger.shared.record(error)
                }
            }
        }
    }
}

extension FirestoreDataManager {
    func update(weightLogWithId: String, weightInKg: Double, dateUpdated: Date) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw FirestoreDataManagerError.runtimeError("Current user must be logged")
        }
        
        try await db
            .collection("users")
            .document(uid)
            .collection("messages")
            .document(weightLogWithId)
            .updateData([
                "weightLog.weightInKg": weightInKg,
                "activityLog.dateUpdated": dateUpdated
            ])
    }
    
    func delete(weightLogWithId: String, dateDeleted: Date) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw FirestoreDataManagerError.runtimeError("Current user must be logged")
        }
        
        try await db
            .collection("users")
            .document(uid)
            .collection("messages")
            .document(weightLogWithId)
            .updateData([
                "weightLog.dateDeleted": dateDeleted
            ])
    }
}
