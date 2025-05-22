//
//  Common.swift
//  Welling
//
//  Created by Irwin Billing on 2024-05-25.
//

import Foundation

struct FetchResult<T> {
    let value: T?
    let error: ResultError?
    let statusCode: Int
    var unauthenticated: Bool

    init(value: T?, error: ResultError?, statusCode: Int, unauthenticated: Bool) {
        self.value = value
        self.error = error
        self.statusCode = statusCode
        self.unauthenticated = unauthenticated
    }
    
    init(value: T) {
        self.value = value
        self.error = nil
        self.statusCode = 200
        self.unauthenticated = false
    }
    
    func withoutValue<U>() -> FetchResult<U> {
       return FetchResult<U>(value: nil, error: error, statusCode: statusCode, unauthenticated: unauthenticated)
    }
}

struct ResultError {
    let title: String
    let message: String
    let cause: Error?
}

