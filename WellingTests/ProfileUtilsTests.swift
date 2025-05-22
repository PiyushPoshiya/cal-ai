//
//  ProfileUtilsTests.swift
//  WellingTests
//
//  Created by Irwin Billing on 2024-06-26.
//

import XCTest
@testable import Welling

final class ProfileUtilsTests: XCTestCase {


    func testNoOverrides() throws {
        let profile: MacroProfile = MacroProfile(
            targetProteinPercentOverride: nil, currentWeight: 60, height: 170, goal: .loseWeight, age: 26, gender: .male, dietaryPreference: "Balanced Diet", targetCalories: 2000)
        
        let computedProfile: ComputedMacroProfile = ProfileUtils.getMacroProfile(macroProfile: profile)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
