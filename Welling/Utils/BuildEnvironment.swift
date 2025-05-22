//
//  IsProduction.swift
//  Welling
//
//  Created by Irwin Billing on 2024-07-25.
//

import Foundation

class BuildEnvironment {
    static func isSimulatorOrTestFlight() -> Bool {
        guard let path = Bundle.main.appStoreReceiptURL?.path else {
            return false
        }
        return path.contains("CoreSimulator") || path.contains("sandboxReceipt")
    }
}
