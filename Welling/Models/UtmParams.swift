//
//  UtmParams.swift
//  Welling
//
//  Created by Irwin Billing on 2024-05-16.
//

import Foundation

struct UtmParams: Encodable {
    static let empty: UtmParams = UtmParams(campaign: nil, source: nil, medium: nil, term: nil, content: nil)

    let campaign: String?
    let source: String?
    let medium: String?
    let term: String?
    let content: String?
    
    func getQueryItems() -> [URLQueryItem] {
        var items: [URLQueryItem] = []
        
        if let campaign = campaign {
            items.append(URLQueryItem(name: "campaign", value: campaign))
        }
        if let source = source {
            items.append(URLQueryItem(name: "source", value: source))
        }
        if let medium = medium {
            items.append(URLQueryItem(name: "medium", value: medium))
        }
        if let term = term {
            items.append(URLQueryItem(name: "term", value: term))
        }
        if let content = content {
            items.append(URLQueryItem(name: "content", value: content))
        }
        
        return items;
    }
    
    static func from(tracking: WellenUserTracking?) -> UtmParams {
        guard let t = tracking else {
            return UtmParams.empty
        }
        
        return UtmParams(campaign: t.utm_campaign, source: t.utm_source, medium: t.utm_medium, term: t.utm_term, content: t.utm_content)
    }
}
