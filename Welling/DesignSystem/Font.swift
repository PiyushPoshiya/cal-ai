import SwiftUI

public extension Font {
    /// Namespace to prevent naming collisions with static accessors on
    /// SwiftUI's Font.
    ///
    /// Xcode's autocomplete allows for easy discovery of design system fonts.
    /// At any call site that requires a font, type `Font.DesignSystem.<esc>`
    struct DesignSystem {
        public static let displayD1 = Font.custom("DMSans-Medium", size: 56)
        public static let displayD2 = Font.custom("DMSans-Medium", size: 48)
        
        public static let headingH1 = Font.custom("DMSans-Medium", size: 40)
        public static let headingH2 = Font.custom("DMSans-Medium", size: 36)
        public static let headingH3 = Font.custom("DMSans-Medium", size: 32)
        public static let headingH4 = Font.custom("DMSans-Medium", size: 24)
        public static let headingH5 = Font.custom("DMSans-Medium", size: 20)
        public static let headingH6 = Font.custom("DMSans-Medium", size: 18)
        
        public static let textLargeNormal = Font.custom("DMSans-Regular", size: 18)
        public static let textLargeMedium = Font.custom("DMSans-Medium", size: 18)
        public static let textLargeBold = Font.custom("DMSans-Bold", size: 18)
        public static let textLargeLink = Font.custom("DMSans-Regular", size: 18)
        public static let textMediumNormal = Font.custom("DMSans-Regular", size: 16)
        public static let textMediumMedium = Font.custom("DMSans-Medium", size: 16)
        public static let textMediumBold = Font.custom("DMSans-Bold", size: 16)
        public static let textMediumLink = Font.custom("DMSans-Regular", size: 16)
        public static let textRegularNormal = Font.custom("DMSans-Regular", size: 14)
        public static let textRegularMedium = Font.custom("DMSans-Medium", size: 14)
        public static let textRegularBold = Font.custom("DMSans-Bold", size: 14)
        public static let textRegularLink = Font.custom("DMSans-Regular", size: 14)
        public static let textRegularStrikethrough = Font.custom("DMSans-Regular", size: 14)
        public static let textSmallNormal = Font.custom("DMSans-Regular", size: 12)
        public static let textSmallMedium = Font.custom("DMSans-Medium", size: 12)
        public static let textSmallBold = Font.custom("DMSans-Bold", size: 12)
        public static let textSmallLink = Font.custom("DMSans-Regular", size: 12)
        public static let textSmallStrikethrough = Font.custom("DMSans-Regular", size: 12)
        public static let textTinyNormal = Font.custom("DMSans-Regular", size: 10)
        public static let textTinyMedium = Font.custom("DMSans-Medium", size: 10)
        public static let textTinyBold = Font.custom("DMSans-Bold", size: 10)
        public static let textTinyLink = Font.custom("DMSans-Regular", size: 10)
        public static let textTinyStrikethrough = Font.custom("DMSans-Regular", size: 10)
    }
}
