//
//  MobileMessageImageView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-07-03.
//

import SwiftUI
import os
import NukeUI

struct MobileMessageImageView: View {
    @Binding var image: MobileMessageImage
    @StateObject var viewModel: MobileMessageImageViewModel = MobileMessageImageViewModel()
    
    var body: some View {
        HStack {
            if let image = viewModel.uiImageFromFile {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if let downloadURL = image.downloadURL {
                LazyImage(url: URL.init(string: downloadURL)) { state in
                    if let image = state.image {
                        image.resizable()
                            .scaledToFill()
                    } else if state.error != nil {
                        Image(systemName: "photo")
                            .foregroundStyle(Theme.Colors.Neutral7)
                    }
                }
            }
        }
        .onAppear {
            Task { @MainActor in
                await viewModel.onAppear(image: image)
            }
        }
    }
}

class MobileMessageImageViewModel: ObservableObject {
    static let loggerCategory =  String(describing: MobileMessageImageViewModel.self)
    fileprivate static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: loggerCategory)
    
    @Published var uiImageFromFile: UIImage?
    
    @MainActor
    func onAppear(image: MobileMessageImage) async {
        let targetResolution = CGSize(width: 270 * UIScreen.main.scale, height: 324 * UIScreen.main.scale)
        let path = image.localPath
        if path.count == 0 {
            return
        }
        
        uiImageFromFile = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .background).async {
                let result = MobileMessageImageViewModel.tryLoadImage(imagePath: path, targetResolution: targetResolution)
                continuation.resume(returning: result)
            }
        }
    }
    
    static func tryLoadImage(imagePath: String, targetResolution: CGSize) -> UIImage? {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        
        // TODO local caching for image path. Perhaps using the NukeUI library.
    
        let path = URL.documentsDirectory.appending(path: imagePath)
        if !FileManager.default.fileExists(atPath: path.path) {
            Self.logger.error("Error loading image, file doesn't exist")
            return nil
        }
        
        do {
            let imageData = try Data(contentsOf: path)
            let image = UIImage(data: imageData)
            guard let image = image else {
                Self.logger.error("Error loading image from data")
                return nil
            }
            
            return image.scaleImage(toSize: targetResolution)
        } catch {
            WLogger.shared.record(error)
        }
        
        return nil
    }
}
