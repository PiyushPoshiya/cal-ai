//
//  FetchModels.swift
//  Welling
//
//  Created by Irwin Billing on 2024-05-13.
//

import Foundation

struct UpdateFcmTokenRequest: Encodable {
    let fcmToken: String
}

struct TempUserSignUpRequest: Encodable {
    let uid: String
    let timezone: String
    let utmParams: UtmParams
    let appVersion: StructAppVersion
}

struct TempUserSignUpRequestBody: Encodable {
    let uid: String
    let appVersion: StructAppVersion
}

struct IsFormSubmittedResponseBody: Decodable {
    let submitted: Bool
}

struct WaSyncRequestBody: Encodable {
    let idToken: String
}

struct NewMessageRequest: Encodable {
    static let empty = NewMessageRequest(_version: 0, id: "", text: nil, mealHint: nil, replyingToMessageId: nil, image: nil)

    let _version: Int;
    let id: String;
    let text: String?
    let mealHint: Meal?
    let replyingToMessageId: String?
    var image: NewMessageReestImage?
}

struct NewMessageReestImage: Encodable {
    let localPath: String
    let fbFullPath: String
    let downloadURL: String?
    let state: ImageProcessingState
}

struct NewMessageResponse: Decodable {

}


struct GetFoodsRequest: Encodable {
    let ids: [String]
}

struct GetMeRequest: Encodable {
    let signedTransactionPayload: String?
    let signedRenewalInfoPayload: String?
    let status: Int?
}

struct UpdateEmailRequest: Encodable {
    let email: String
}
