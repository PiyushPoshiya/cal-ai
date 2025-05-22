//
//  String.swift
//  Welling
//
//  Created by Irwin Billing on 2024-07-11.
//

import Foundation

extension String {
    static var markdownOptions = AttributedString.MarkdownParsingOptions(
        allowsExtendedAttributes: false,
        interpretedSyntax: .inlineOnlyPreservingWhitespace,
        failurePolicy: .returnPartiallyParsedIfPossible,
        languageCode: nil
    )
}
