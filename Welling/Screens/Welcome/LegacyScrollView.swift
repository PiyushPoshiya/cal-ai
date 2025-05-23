//
//  LegacyScrollView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-07-14.
//

import Foundation
import SwiftUI
import UIKit

struct LegacyScrollView: UIViewRepresentable {
    enum Action {
        case idle
        case offset(x: CGFloat, y: CGFloat, animated: Bool)
    }

    let axis: Axis
    @Binding var action: Action
    private let uiScrollView: UIScrollView
    private let delegate: UIScrollViewDelegate

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UIScrollView {
        return self.uiScrollView
    }
    
    func updateUIView(_ uiView: UIScrollView, context: Context) {
        switch self.action {
        case .offset(let x, let y, let animated):
            uiView.setContentOffset(CGPoint(x: x, y: y), animated: animated)
            DispatchQueue.main.async {
                self.action = .idle
            }
        default:
            break
        }
    }

    class Coordinator: NSObject {
        let legacyScrollView: LegacyScrollView

        init(_ legacyScrollView: LegacyScrollView) {
            self.legacyScrollView = legacyScrollView
        }
    }

    init<Content: View>(axis: Axis, action: Binding<Action>, delegate: UIScrollViewDelegate, @ViewBuilder content: () -> Content) {
        self.axis = axis
        self._action = action
        self.uiScrollView = UIScrollView()

        let hosting = UIHostingController(rootView: content())
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        
        self.uiScrollView.addSubview(hosting.view)
        
        self.delegate = delegate
        self.uiScrollView.delegate = delegate
        self.uiScrollView.decelerationRate = UIScrollView.DecelerationRate.fast
        self.uiScrollView.showsHorizontalScrollIndicator = false
        
//        self.uiScrollView.isPagingEnabled = true
//        self.uiScrollView.clipsToBounds = false
        
        let constraints: [NSLayoutConstraint]
        switch self.axis {
        case .horizontal:
            constraints = [
                hosting.view.leadingAnchor.constraint(equalTo: self.uiScrollView.contentLayoutGuide.leadingAnchor),
                hosting.view.trailingAnchor.constraint(equalTo: self.uiScrollView.contentLayoutGuide.trailingAnchor),
                hosting.view.topAnchor.constraint(equalTo: self.uiScrollView.topAnchor),
                hosting.view.bottomAnchor.constraint(equalTo: self.uiScrollView.bottomAnchor),
                hosting.view.heightAnchor.constraint(equalTo: self.uiScrollView.heightAnchor)
            ]
        case .vertical:
            constraints = [
                hosting.view.leadingAnchor.constraint(equalTo: self.uiScrollView.leadingAnchor),
                hosting.view.trailingAnchor.constraint(equalTo: self.uiScrollView.trailingAnchor),
                hosting.view.topAnchor.constraint(equalTo: self.uiScrollView.contentLayoutGuide.topAnchor),
                hosting.view.bottomAnchor.constraint(equalTo: self.uiScrollView.contentLayoutGuide.bottomAnchor),
                hosting.view.widthAnchor.constraint(equalTo: self.uiScrollView.widthAnchor)
            ]
        }
        self.uiScrollView.addConstraints(constraints)
    }
}
