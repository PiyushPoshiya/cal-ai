//
//  Theme.swift
//  Welling
//
//  Created by Irwin Billing on 2024-05-13.
//

import SwiftUI

enum Theme {
    enum Kerning {
        static let Button: CGFloat = 0.0
    }

    ///MARK :- WEL-853: Make sure all color names are lowercase
    ///Task :- Chnage Color Name are lowercase in Assets Color
    ///Date :- 13 August, 2024
    ///By Piyush Poshiya

    enum Colors {
        static let SurfaceNeutral05: Color = .init("surface-neutral05")
        static let SurfaceNeutral2: Color = .init("surface-neutral2")
        static let SurfaceNeutral3: Color = .init("surface-neutral3")
        static let SurfaceNeutral9: Color = .init("surface-neutral9")

        static let SurfacePrimary100: Color = .init("surface-primary100")
        static let SurfacePrimary120: Color = .init("surface-primary120")

        static let SurfaceSecondary100: Color = .init("surface-secondary100")

        static let Neutral7: Color = .init("neutral-7")

        static let TextNeutral9: Color = .init("text-neutral9")
        static let TextNeutral8: Color = .init("text-neutral8")
        static let TextNeutral7: Color = .init("text-neutral7")
        static let TextNeutral3: Color = .init("text-neutral3")
        static let TextNeutral2: Color = .init("text-neutral2")
        static let TextNeutral05: Color = .init("text-neutral05")
        static let TextPrimary100: Color = .init("text-primary100")
        static let TextSecondary100: Color = .init("text-secondary100")

        static let BorderNeutral05: Color = .init("border-neutral05")
        static let BorderNeutral2: Color = .init("border-neutral2")
        static let BorderNeutral3: Color = .init("border-neutral3")
        static let BorderNeutral95: Color = .init("border-neutral95")

        static let SemanticInfoFocus: Color = .init("semantic-info-focus")
        static let SemanticWarning: Color = .init("semantic-warning")
        static let SemanticValidated: Color = .init("semantic-validated")
        static let SemanticError: Color = .init("semantic-error")
    }

    enum Spacing {
        static let none: CGFloat = 0
        static let xxxsmall: CGFloat = 2
        static let xxsmall: CGFloat = 4
        static let xsmall: CGFloat = 8
        static let small: CGFloat = 12
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let xlarge: CGFloat = 32
        static let xxlarge: CGFloat = 40
        static let xxxlarge: CGFloat = 48
        static let xxxxlarge: CGFloat = 64

        static let spacer: CGFloat = 20
        static let verticalPadding: CGFloat = 10.0
        static let horizontalPadding: CGFloat = 12.0

        static let navBar: CGFloat = 20.0
        
        static let cardSpacing: CGFloat = 12
    }

    enum Radius {
        static let none: CGFloat = 0
        static let xxsmall: CGFloat = 4
        static let xsmall: CGFloat = 8
        static let small: CGFloat = 12
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let xlarge: CGFloat = 32
        static let xxlarge: CGFloat = 40
        static let xxxlarge: CGFloat = 64
        static let full: CGFloat = 360
    }

    enum Text {
        static let d1: FontWithLineHeightProps = .init(font: UIFont(name: "DMSans-Medium", size: 56) ?? UIFont.systemFont(ofSize: 56), lineHeight: 67, kerning: -1.12)
        static let d2: FontWithLineHeightProps = .init(font: UIFont(name: "DMSans-Medium", size: 48) ?? UIFont.systemFont(ofSize: 48), lineHeight: 58, kerning: -0.96)

        static let h1: FontWithLineHeightProps = .init(font: UIFont(name: "DMSans-Medium", size: 40) ?? UIFont.systemFont(ofSize: 40), lineHeight: 48, kerning: -1.2)
        static let h2: FontWithLineHeightProps = .init(font: UIFont(name: "DMSans-Medium", size: 36) ?? UIFont.systemFont(ofSize: 36), lineHeight: 43, kerning: -1.62)

        static let h3: FontWithLineHeightProps = .init(font: UIFont(name: "DMSans-Medium", size: 32) ?? UIFont.systemFont(ofSize: 32), lineHeight: 38, kerning: -1.44)
        static let h4: FontWithLineHeightProps = .init(font: UIFont(name: "DMSans-Medium", size: 24) ?? UIFont.systemFont(ofSize: 24), lineHeight: 34, kerning: -0.96)
        static let h5: FontWithLineHeightProps = .init(font: UIFont(name: "DMSans-Medium", size: 20) ?? UIFont.systemFont(ofSize: 20), lineHeight: 28, kerning: -0.8)
        static let h6: FontWithLineHeightProps = .init(font: UIFont(name: "DMSans-Medium", size: 18) ?? UIFont.systemFont(ofSize: 18), lineHeight: 25, kerning: -0.63)

        static let navBarSubheading = FontWithLineHeightProps(font: UIFont(name: "DMSans-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14), lineHeight: 34, kerning: -0.35)

        static let largeRegular = FontWithLineHeightProps(font: UIFont(name: "DMSans-Regular", size: 18) ?? UIFont.systemFont(ofSize: 18), lineHeight: 27, kerning: -0.63)
        static let largeMedium = FontWithLineHeightProps(font: UIFont(name: "DMSans-Medium", size: 18) ?? UIFont.systemFont(ofSize: 18), lineHeight: 27, kerning: -0.63)
        static let largeSemiBold = FontWithLineHeightProps(font: UIFont(name: "DMSans-Medium", size: 18) ?? UIFont.systemFont(ofSize: 18), lineHeight: 27, kerning: -0.63)
        static let largeBold = FontWithLineHeightProps(font: UIFont(name: "DMSans-Bold", size: 18) ?? UIFont.systemFont(ofSize: 20), lineHeight: 27, kerning: -0.63)

        static let mediumRegular = FontWithLineHeightProps(font: UIFont(name: "DMSans-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16), lineHeight: 24, kerning: -0.4)
        static let mediumMedium = FontWithLineHeightProps(font: UIFont(name: "DMSans-Medium", size: 16) ?? UIFont.systemFont(ofSize: 16), lineHeight: 24, kerning: -0.4)
        static let mediumSemiBold = FontWithLineHeightProps(font: UIFont(name: "DMSans-Medium", size: 16) ?? UIFont.systemFont(ofSize: 16), lineHeight: 24, kerning: -0.4)
        static let mediumBold = FontWithLineHeightProps(font: UIFont(name: "DMSans-Bold", size: 16) ?? UIFont.systemFont(ofSize: 16), lineHeight: 24, kerning: -0.4)

        static let regularRegular = FontWithLineHeightProps(font: UIFont(name: "DMSans-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14), lineHeight: 21, kerning: -0.35)
        static let regularMedium = FontWithLineHeightProps(font: UIFont(name: "DMSans-Medium", size: 14) ?? UIFont.systemFont(ofSize: 14), lineHeight: 21, kerning: -0.35)
        static let regularSemiBold = FontWithLineHeightProps(font: UIFont(name: "DMSans-Medium", size: 14) ?? UIFont.systemFont(ofSize: 14), lineHeight: 21, kerning: -0.35)
        static let regularBold = FontWithLineHeightProps(font: UIFont(name: "DMSans-Bold", size: 14) ?? UIFont.systemFont(ofSize: 14), lineHeight: 21, kerning: -0.35)

        static let smallRegular: FontWithLineHeightProps = .init(font: UIFont(name: "DMSans-Regular", size: 12) ?? UIFont.systemFont(ofSize: 12), lineHeight: 18, kerning: -0.24)
        static let smallMedium: FontWithLineHeightProps = .init(font: UIFont(name: "DMSans-Medium", size: 12) ?? UIFont.systemFont(ofSize: 12), lineHeight: 18, kerning: -0.24)
        static let smallSemiBold: FontWithLineHeightProps = .init(font: UIFont(name: "DMSans-Medium", size: 12) ?? UIFont.systemFont(ofSize: 12), lineHeight: 18, kerning: -0.24)
        static let smallBold: FontWithLineHeightProps = .init(font: UIFont(name: "DMSans-Bold", size: 12) ?? UIFont.systemFont(ofSize: 12), lineHeight: 18, kerning: -0.24)
        static let smallItalic: FontWithLineHeightProps = .init(font: UIFont(name: "DMSans-Italic", size: 12) ?? UIFont.systemFont(ofSize: 12), lineHeight: 18, kerning: -0.24)

        static let tinyRegular: FontWithLineHeightProps = .init(font: UIFont(name: "DMSans-Regular", size: 10) ?? UIFont.systemFont(ofSize: 10), lineHeight: 15, kerning: -0.2)
        static let tinyMedium: FontWithLineHeightProps = .init(font: UIFont(name: "DMSans-Medium", size: 10) ?? UIFont.systemFont(ofSize: 10), lineHeight: 15, kerning: -0.2)
        static let tinySemiBold: FontWithLineHeightProps = .init(font: UIFont(name: "DMSans-Medium", size: 10) ?? UIFont.systemFont(ofSize: 10), lineHeight: 15, kerning: -0.2)
        static let tinyBold: FontWithLineHeightProps = .init(font: UIFont(name: "DMSans-Bold", size: 10) ?? UIFont.systemFont(ofSize: 10), lineHeight: 15, kerning: -0.2)
    }
}
