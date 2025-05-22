//
//  Firebase.swift
//  Welling
//
//  Created by Irwin Billing on 2024-05-17.
//

import Foundation
import FirebaseFirestore

struct FireStoreSignUpSentinel: Codable {
    @DocumentID var id: String?
    var uid: String
    var w_user_id: String
    var status: String
    var date_created: Int
}
