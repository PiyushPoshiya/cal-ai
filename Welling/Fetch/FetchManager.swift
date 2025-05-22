//
//  Fetch.swift
//  Welling
//
//  Created by Irwin Billing on 2024-05-12.
//

import FirebaseAuth
import Foundation
import os
import Alamofire

private var baseURL: String {
    #if API_DEV
    //    "http://localhost:3000/api"
    //        URL(string: "https://2546-50-68-207-111.ngrok.io/v2")!
    #else
    "https://api.welling.ai/api"
//    "https://wellen-api-staging.azurewebsites.net/api"
//    "http://localhost:3000/api"
//    "https://rnjis-154-20-50-6.a.free.pinggy.link/api"
    #endif
}

var requestTimeout: TimeInterval = 60

class FetchManager {
    static let loggerCategory = String(describing: FetchManager.self)
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: loggerCategory)

    static let global: FetchManager = .init()

    static let iso8601: (regular: ISO8601DateFormatter, withFractionalSeconds: ISO8601DateFormatter) = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return (ISO8601DateFormatter(), formatter)
    }()

    let jsonEncoder: JSONEncoder = .init()
    let jsonDecoder: JSONDecoder = .init()
    let userAgent: String = UAString()
    var afSession: Alamofire.Session = Alamofire.Session.default

    init() {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX") // 1
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(formatter)

        jsonDecoder.dateDecodingStrategy = .formatted(formatter)
    }

    func getMe(signedTransactionPayload: String?, signedRenewalInfoPayload: String?, status: Int?) async -> FetchResult<WellingUser> {
        WLogger.shared.log(Self.loggerCategory, "Getting me.")

        guard let authToken: String = getAuthToken() else {
            return returnUnauthenticated()
        }

        do {
            let req: URLRequest = try getRequest(path: "/mobile/me/v2/with-transaction-info", method: "POST", authToken: authToken, body: GetMeRequest(signedTransactionPayload: signedTransactionPayload, signedRenewalInfoPayload: signedRenewalInfoPayload, status: status))
            return await executeRequestWithResponse(req: req)
        } catch {
            WLogger.shared.record(error)
            return returnUnexpectedError(cause: error)
        }
    }

    func updateUser(email: String) async -> FetchResult<Void> {
        WLogger.shared.log(Self.loggerCategory, "Updating user.")

        guard let authToken: String = getAuthToken() else {
            return returnUnauthenticated()
        }

        do {
            let req: URLRequest = try getRequest(path: "/mobile/me/email", method: "POST", authToken: authToken, body: UpdateEmailRequest(email: email))
            return await executeRequest(req: req)
        } catch {
            WLogger.shared.record(error)
            return returnUnexpectedError(cause: error)
        }
    }

    func sendMessage(message: NewMessageRequest) async -> FetchResult<Void> {
        WLogger.shared.log(Self.loggerCategory, "Sending message.")
        guard let authToken: String = getAuthToken() else {
            return returnUnauthenticated()
        }

        do {
            let req: URLRequest = try getRequest(path: "/mobile/messages", method: "POST", authToken: authToken, body: message)
            return await executeRequest(req: req)
        } catch {
            WLogger.shared.record(error)
            return returnUnexpectedError(cause: error)
        }
    }

    func getIsFormSubmitted() async -> FetchResult<IsFormSubmittedResponseBody> {
        WLogger.shared.log(Self.loggerCategory, "Getting if form is submitted.")
        guard let authToken: String = getAuthToken() else {
            return returnUnauthenticated()
        }

        do {
            let req: URLRequest = try getRequest(path: "/mobile/me/is-form-submitted", method: "GET", authToken: authToken)
            return await executeRequestWithResponse(req: req)
        } catch {
            WLogger.shared.record(error)
            return returnUnexpectedError(cause: error)
        }
    }

    func getFoods(ids: [String]) async -> FetchResult<[Food]> {
        WLogger.shared.log(Self.loggerCategory, "Get foods.")
        guard let authToken: String = getAuthToken() else {
            return returnUnauthenticated()
        }

        do {
            let req: URLRequest = try getRequest(path: "/foods", method: "POST", authToken: authToken, body: GetFoodsRequest(ids: ids))
            return await executeRequestWithResponse(req: req)
        } catch {
            WLogger.shared.record(error)
            return returnUnexpectedError(cause: error)
        }
    }

    func signUpTempUser(request: TempUserSignUpRequest) async -> FetchResult<WellingUser> {
        WLogger.shared.log(Self.loggerCategory, "Sign up temp user.")
        do {
            var params: [URLQueryItem] = request.utmParams.getQueryItems()
            params.append(URLQueryItem(name: "timezone", value: request.timezone))

            let req: URLRequest = try getRequest(path: "/auth/mobile/signup", method: "POST", authToken: nil, body: TempUserSignUpRequestBody(uid: request.uid, appVersion: request.appVersion), queryItems: params)
            return await executeRequestWithResponse(req: req)
        } catch {
            WLogger.shared.record(error)
            return returnUnexpectedError(cause: error)
        }
    }

    func trySyncWhatsAppNumber() async -> FetchResult<Void> {
        WLogger.shared.log(Self.loggerCategory, "Try sync WhatsApp number.")
        guard let authToken: String = getAuthToken() else {
            return returnUnauthenticated()
        }

        do {
            let req: URLRequest = try getRequest(path: "/auth/mobile/wa-sync", method: "POST", authToken: nil, body: WaSyncRequestBody(idToken: authToken))
            return await executeRequest(req: req)
        } catch {
            WLogger.shared.record(error)
            return returnUnexpectedError(cause: error)
        }
    }

    private func executeRequest(req: URLRequest) async -> FetchResult<Void> {
        WLogger.shared.log(Self.loggerCategory, "Execute request.")
        do {
            let afDataTask = await afSession.request(req, interceptor: .retryPolicy).serializingData().response

            guard let httpResponse = afDataTask.response else {
                throw URLError(.badServerResponse)
            }
            return FetchResult<Void>(
                value: nil,
                error: nil,
                statusCode: httpResponse.statusCode,
                unauthenticated: false)

        } catch {
            WLogger.shared.record(error)
            return FetchResult<Void>(
                value: nil,
                error: ResultError(title: NSLocalizedString("Unknown", comment: "Unknown error."), message: NSLocalizedString("Please try again.", comment: "Asking user to try again"), cause: error),
                statusCode: 0,
                unauthenticated: true)
        }
    }

    private func executeRequestWithResponse<T: Decodable>(req: URLRequest) async -> FetchResult<T> {
        WLogger.shared.log(Self.loggerCategory, "Execute request with response.")
        do {
            let afDataTask = await afSession.request(req, interceptor: .retryPolicy).serializingData().response

            guard let httpResponse = afDataTask.response else {
                throw URLError(.badServerResponse)
            }
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                return FetchResult<T>(
                    value: nil,
                    error: ResultError(title: NSLocalizedString("Unauthenticated", comment: "User is not authenticated"), message: NSLocalizedString("Not logged in.", comment: "Message shown when user is not logged in."), cause: nil),
                    statusCode: httpResponse.statusCode,
                    unauthenticated: true)
            }
            if httpResponse.statusCode < 200 || httpResponse.statusCode > 299 {
                return FetchResult<T>(
                    value: nil,
                    error: ResultError(title: NSLocalizedString("Unknown", comment: "Unknown error."), message: NSLocalizedString("Please try again.", comment: "Asking user to try again"), cause: nil),
                    statusCode: httpResponse.statusCode,
                    unauthenticated: true)
            }

            guard let data = afDataTask.data else {
                return FetchResult<T>(
                    value: nil,
                    error: ResultError(title: NSLocalizedString("Unknown", comment: "Unknown error."), message: NSLocalizedString("Please try again.", comment: "Asking user to try again"), cause: nil),
                    statusCode: httpResponse.statusCode,
                    unauthenticated: true)
            }

            return try FetchResult<T>(
                value: jsonDecoder.decode(T.self, from: data),
                error: nil,
                statusCode: 200,
                unauthenticated: false)

        } catch {
            WLogger.shared.record(error)
            return FetchResult<T>(
                value: nil,
                error: ResultError(title: NSLocalizedString("Unknown", comment: "Unknown error."), message: NSLocalizedString("Please try again.", comment: "Asking user to try again"), cause: error),
                statusCode: 0,
                unauthenticated: true)
        }
    }

    private func getRequest(
        path: String,
        method: String,
        authToken: String?,
        body: Encodable? = nil,
        queryItems: [URLQueryItem] = [],
        headers: KeyValuePairs<String, String> = [:]) throws -> URLRequest {
        var urlComponents = URLComponents(string: baseURL + path)!
        urlComponents.queryItems = queryItems

        var req = URLRequest(url: urlComponents.url!)
        req.httpMethod = method

        if let _authToken: String = authToken {
            req.setValue(_authToken, forHTTPHeaderField: "X-Welling-Auth")
        }

        req.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        for (key, value) in headers {
            req.setValue(value, forHTTPHeaderField: key)
        }

        if let _body: any Encodable = body {
            req.httpBody = try jsonEncoder.encode(_body)
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        return req
    }

    private func returnUnexpectedError<T>(cause: Error?) -> FetchResult<T> {
        return FetchResult<T>(
            value: nil,
            error: ResultError(title: "Unexpected Erorr", message: "Please try agian.", cause: cause),
            statusCode: 0,
            unauthenticated: false)
    }

    private func returnUnauthenticated<T>() -> FetchResult<T> {
        return FetchResult<T>(
            value: nil,
            error: ResultError(
                title: NSLocalizedString("Unauthorized", comment: "Title for an unauthorized action modal."),
                message: NSLocalizedString("You must be logged in to perform this action.", comment: "Message for an unauthorized action modal."),
                cause: nil),
            statusCode: 401,
            unauthenticated: false)
    }

    func getAuthToken() -> String? {
        WLogger.shared.log(Self.loggerCategory, "Get auth token.")
        let auth = Auth.auth()

        let sem = DispatchSemaphore(value: 0)
        var token: String?
        var error: Error?

        guard let currentUser = auth.currentUser else {
            return nil
        }

        currentUser.getIDToken { result_token, result_error in
            token = result_token
            error = result_error

            sem.signal()
        }

        sem.wait()

        if let error: Error = error {
            WLogger.shared.record(error)
            return nil
        }

        return token
    }
}

enum SortOrder: String {
    case asc
    case desc
}
