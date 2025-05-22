//
//  WelcomeCarouselView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-07-13.
//

import SwiftUI
import CollectionViewPagingLayout

fileprivate struct Item: Identifiable {
    let id = UUID()
    let image: String
    
    init(_ image: String) {
        self.image = image
    }
}

struct WelcomeCarouselView: View {
    fileprivate let images: [Item] = [.init("welcome-screenshot-1"), .init("welcome-screenshot-2"), .init("welcome-screenshot-3"), .init("welcome-screenshot-4"), .init("welcome-screenshot-5")]
    var delegate: UIScrollViewDelegate = WelcomeCarouselViewScrollDelegate()
    @State private var action = LegacyScrollView.Action.idle
    
    let dragGesture = DragGesture().onEnded {_ in
        print("Offset: \(String(describing: offset))")
    }
    
    var body: some View {
        VStack (alignment: .leading, spacing: Theme.Spacing.xlarge) {
            if #available(iOS 17, *) {
                ScrollView (.horizontal) {
                    LazyHStack (spacing: 0.0) {
                        ForEach (images.indices, id: \.self) {idx in
                            let image = images[idx].image
                            Image(image)
                                .resizable()
                                .frame(width: 312, height: 488)
                                .cornerRadius(Theme.Radius.xlarge)
                                .scrollTransition(axis: .horizontal) { content, phase in
                                    content
                                        .offset(x: phase.isIdentity ? 0.0 : -1 * Theme.Spacing.xxxlarge, y: 0.0)
                                        .scaleEffect(x: phase.isIdentity ? 1.0 : 0.7, y: phase.isIdentity ? 1.0 : 0.7)
                                        .opacity(phase.isIdentity ? 1.0 : 0.5)
                                }
                                .padding(.trailing, idx == images.count - 1 ? Theme.Spacing.xxxlarge : 0.0)
                        }
                    }
                    .frame(height: 488)
                    .scrollTargetLayout()
                }
                .safeAreaPadding(.horizontal, Theme.Spacing.horizontalPadding)
                .defaultScrollAnchor(.topLeading)
                .scrollTargetBehavior(.viewAligned)
                .scrollIndicators(.hidden)
            } else {
                ScalePageView(images) { image in
                    // Build your view here
                    Image(image.image)
                        .resizable()
                        .frame(width: 312, height: 488)
                        .cornerRadius(Theme.Radius.xlarge)
                }
                .numberOfVisibleItems(3)
                .options(.init(
                    translationRatio: .init(x: 0.62, y: 0.1),
                    shadowEnabled: false
                ))
                .frame(height: 488)
            }
        }
    }
}


class WelcomeCarouselViewScrollDelegate: NSObject, UIScrollViewDelegate {
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if ((scrollView.contentOffset.x + scrollView.frame.size.width) >= scrollView.contentSize.width) {
            // no snap needed ... we're at the end of the scrollview
            return
        }
        
        let index: CGFloat = CGFloat(lrintf(Float(targetContentOffset.pointee.x) / 312))
        targetContentOffset.pointee.x = index * 312
    }
    
    
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentIndex: CGFloat = CGFloat(lrintf(Float(scrollView.contentOffset.x) / 312))
        
        // views offset relative to parent - we can compute this ourself, it's just index of the subvie * their width
        // current scroll offset
        // center
        // The further the view offset is from center, the smaller it is
        for i in 0...scrollView.subviews.count-1 {
            let offset: Double = abs((312.0 * Double(i)) - scrollView.contentOffset.x)
            let subview = scrollView.subviews[i]
            // 1 -> 0.5, depending on diff. s = diff/
            let alpha: Double = offset == 0.0 ? 1 : min(1.0, max(0.5, 312.0 / (offset+offset)))
            subview.alpha = alpha
        }
    }
}


struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}

#Preview {
    WelcomeCarouselView()
}
