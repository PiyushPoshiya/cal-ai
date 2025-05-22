//
//  StringUtils.swift
//  Welling
//
//  Created by Irwin Billing on 2024-05-13.
//

import Foundation

extension String {
    static func isNullOrEmpty(_ s: String?) -> Bool {
        if let _s = s {
            return _s.isEmpty
        }
        
        return true
    }
}
