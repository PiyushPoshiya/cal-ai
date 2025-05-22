//
//  LocalImage.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-15.
//

import SwiftUI
import os

struct LocalImage: View {
    static let loggerCategory =  String(describing: LocalImage.self)
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: loggerCategory)
    
    @State var loadingError: Bool = false
    @State var image: UIImage?
    var path: String
    
    var body: some View {
        VStack {
            if loadingError {
                    Image(systemName: "photo")
                        .foregroundStyle(Theme.Colors.Neutral7)
            } else if let image = image {
                Image(uiImage: image)
            } else {
                EmptyView()
            }
        }
        .onAppear {
            Task {
                await loadImage()
            }
        }
    }
   
    func loadImage() async {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        
        do {
            let data = try Data(contentsOf: URL(string: "file://\(path)")!)
            await MainActor.run {
                self.image = UIImage(data: data)
            }
        } catch {
            loadingError = true
            WLogger.shared.record(error)
        }
    }
}

#Preview {
    LocalImage(path: "")
}
