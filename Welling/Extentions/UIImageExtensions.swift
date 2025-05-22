//
//  UIImageExtensions.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-17.
//

import Foundation
import SwiftUI

extension UIImage {
    func scaleImage(toSize newSize: CGSize) -> UIImage? {
        let scale = newSize.height / self.size.height
        let width = self.size.width * scale
        let newSize = CGSize(width: width, height: newSize.height)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
