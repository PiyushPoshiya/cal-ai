//
//  SignUpWebView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-05-16.
//

import SwiftUI
import UIKit
import WebKit
import os

struct SignUpWebView: UIViewRepresentable {
    let formId: String
    let handlers: PSignUpFormHandler
    let n: String
    let tracking: UtmParams
    
    func makeViewConfiguration() -> WKWebViewConfiguration
    {
        let configuration: WKWebViewConfiguration = WKWebViewConfiguration()
        let dropSharedWorkersScript: WKUserScript = WKUserScript(source: "delete window.SharedWorker;", injectionTime: WKUserScriptInjectionTime.atDocumentStart, forMainFrameOnly: false)
        configuration.userContentController.addUserScript(dropSharedWorkersScript)

        return configuration
    }

    func makeUIView(context: Context) -> WKWebView {
        let webConfiguration: WKWebViewConfiguration = WKWebViewConfiguration()
        webConfiguration.defaultWebpagePreferences.allowsContentJavaScript = true
        
        SignUpWebViewMessageHandler.register(controller: webConfiguration.userContentController, handlers: handlers)
         
        let webView: SignUpWKWebView = SignUpWKWebView(frame: .zero, configuration: webConfiguration)

        webView.isOpaque = false
        webView.backgroundColor = UIColor(Theme.Colors.SurfaceNeutral05)
        webView.navigationDelegate = webView
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        
        let index: URL = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "static/signup")!
        let htmlString: String? = try? String(contentsOf: index, encoding: String.Encoding.utf8)
        var formatted: String? = htmlString?.replacingOccurrences(of: "<form-id>", with: formId, options: .literal)
        formatted = formatted?.replacingOccurrences(of: "<tracking>", with: buildTrackingString(), options: .literal)
        formatted = formatted?.replacingOccurrences(of: "<nano-id>", with: buildNanoIdString(), options: .literal)

        webView.loadHTMLString(formatted!, baseURL: nil)

        return webView
    }

    func buildTrackingString() -> String {
      var trackingStrings: [String] = [];
      if (tracking.campaign != nil) {
        trackingStrings.append("utm_campaign=\(tracking.campaign!)")
      }
      if (tracking.source != nil) {
        trackingStrings.append("utm_source=\(tracking.source!)")
      }
      if (tracking.medium != nil) {
        trackingStrings.append("utm_medium=\(tracking.medium!)")
      }
      if (tracking.term != nil) {
        trackingStrings.append("utm_term=\(tracking.term!)")
      }
      if (tracking.content != nil) {
        trackingStrings.append("utm_content=\(tracking.content!)")
      }

      return trackingStrings.joined(separator: ",")
    }

    func buildNanoIdString() -> String {
      return "n=\(n)"
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
    }
}

class SignUpWebViewMessageHandler: NSObject, WKScriptMessageHandler {
    private static let logger: Logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: SignUpWebViewMessageHandler.self)
    )
    
    let handlers: PSignUpFormHandler
    
    init(handlers: PSignUpFormHandler) {
        self.handlers = handlers
    }
    
    static func register(controller: WKUserContentController, handlers: PSignUpFormHandler) {
        let messageHandler: SignUpWebViewMessageHandler = SignUpWebViewMessageHandler(handlers: handlers)
        controller.add(messageHandler, name: "onReady")
        controller.add(messageHandler, name: "onStarted")
        controller.add(messageHandler, name: "onQuestionChanged")
        controller.add(messageHandler, name: "onSubmit")
        controller.add(messageHandler, name: "onClose")
        controller.add(messageHandler, name: "onEndingButtonClick")
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "onReady":
            handlers.onReady()
        case "onStarted":
            handlers.onStarted()
        case "onQuestionChanged":
            if let bodyString = message.body as? String {
                handlers.onQuestionChanged(question: bodyString)
            } else {
                Self.logger.error("onQuestionChanged called with a non-string body")
            }
        case "onSubmit":
            handlers.onSubmit()
        case "onClose":
            handlers.onClose()
        case "onEndingButtonClick":
            handlers.onEndingButtonClick()
        default:
            Self.logger.error("Unknown message receieved from signup webview: \(message.name)")
            break
        }
    }
}

class SignUpWKWebView:  WKWebView, WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if webView.isLoading {
            return
        }
    }
}
