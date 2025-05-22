//
//  ConversationImageInputViewModel.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-12.
//

import Foundation
import AVFoundation
import SwiftUI
import os

/*

 */
class ConversationImageInputViewModel: ObservableObject {
    static let loggerCategory =  String(describing: ConversationImageInputViewModel.self)
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: loggerCategory)
    
    let camera = Camera()
    @Published var photoCollection: PhotoCollection
    
    @Published var state: ConversationImageViewState = .chosePhoto
    
    @Published var isSaving: Bool = false
    @Published var viewfinderImage: Image?
    @Published var thumbnailImage: Image?
    @Published var lastSnappedImage: Image?
    @Published var lastSnappedUIImage: UIImage?
    @Published var shutterFlash: Bool = true
    @Published var photoLibraryAuthorized: Bool = false
    @Published var presentPhotoCollectionView: Bool = false
    @Published var presentLibraryAccessRequired: Bool = false
    @Published var presentCameraAccessRequired: Bool = false
    
    @Published var chosenMeal: Meal? = .lunch
    @Published var text: String = ""
    
    var isPhotosLoaded = false
    
    @MainActor
    init() {
        self.photoCollection = PhotoCollection(smartAlbum: .smartAlbumUserLibrary)
        Task {
            await handleCameraPreviews()
        }
        
        Task {
            await handleCameraPhotos()
        }
        
        self.chosenMeal = self.inferCurrentMeal()
    }
    
    @MainActor 
    func onSave(uid: String) async -> SendImageResult? {
        let localPath: String? = await saveImage(uid: uid)
        guard let localPath = localPath else {
            return nil
        }
       
        return SendImageResult(text: text, meal: chosenMeal ?? .lunch, localImagePath: localPath)
    }
    
    static let hourToMeal: [Meal] = [
        .dinner, // 0
        .dinner, // 1
        .dinner, // 2
        .dinner, // 3
        .breakfast, // 4
        .breakfast, // 5
        .breakfast, // 6
        .breakfast, // 7
        .breakfast, // 8
        .breakfast, // 9
        .snack, // 10
        .snack, // 11
        .lunch, // 12
        .lunch, // 1
        .lunch, // 2
        .snack, // 3
        .snack, // 4
        .dinner, // 5
        .dinner, // 6
        .dinner, // 7
        .dinner, // 8
        .dinner, // 9
        .dinner, // 10
        .dinner, // 11,
    ]
    
    func inferCurrentMeal() -> Meal {
        let hour: Int = Calendar.current.component(.hour, from: .now)
        return Self.hourToMeal[hour]
    }
    
    @MainActor
    private func saveImage(uid: String) async -> String? {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        
        guard let lastSnappedUIImage = self.lastSnappedUIImage else {
            WLogger.shared.error(Self.loggerCategory, "Nothing to save.")
            return nil
        }
        
        let result: String? = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .background).async {
                let imageFileName = "\(UUID().uuidString).jpeg"
                let imageDir = "users/\(uid)/images"
                let dirURL = URL.documentsDirectory.appending(path: imageDir)
                let tempURL = dirURL.appendingPathComponent(imageFileName)
                
                let imageData = lastSnappedUIImage.jpegData(compressionQuality: 0.5)
                guard let imageData = imageData else {
                    Self.logger.error("Could not get jpeg data from image to save")
                    continuation.resume(returning: nil)
                    return
                }
               
                do {
                    try FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true)
                    if !FileManager.default.createFile(atPath: tempURL.path(), contents: imageData) {
                        Self.logger.error("Error writing image to temp URL, create file returned false")
                        continuation.resume(returning: nil)
                    } else {
                        continuation.resume(returning: "\(imageDir)/\(imageFileName)")
                    }
                } catch {
                    WLogger.shared.record(error)
                    continuation.resume(returning: nil)
                }
            }
        }
        
        return result
    }
    
    @MainActor
    func startCamera() async {
        let startResult = await camera.start()
        switch startResult {
        case .started:
            return
        case .accessDenied:
            presentCameraAccessRequired = true
        case .couldNotStart:
            return
        }
    }
    
    func stopCamera() {
          camera.stop()
    }
    
    func chosePhotoFromLibrary() {
        if !photoLibraryAuthorized {
            self.presentLibraryAccessRequired = true
           return
        }
        
        pauseCamera()
        presentPhotoCollectionView = true
    }
    
    func onRecentPhotoChosen(asset: PhotoAsset) {
        Task { @MainActor in
            await onPhotoFromLibraryChosen(asset: asset)
        }
    }
    
    @MainActor
    func onPhotoFromLibraryChosen(asset: PhotoAsset) async {
        state = .photoChosen
        presentPhotoCollectionView = false
        shutterFlash.toggle()
        await photoCollection.cache.requestImage(for: asset, targetSize: CGSize(width: 2056, height: 2056))  { result in
            if let result = result {
                Task { @MainActor in
                    self.lastSnappedImage = result.image
                    self.lastSnappedUIImage = result.uiImage
                }
            }
        }
    }
    
    func onChosePhotoLibraryDismissed() {
        if state == .chosePhoto {
            resumeCamera()
        }
    }
    
    func takePhoto() {
        camera.takePhoto()
        pauseCamera()
        state = .photoChosen
        withAnimation(.easeInOut(duration: 0.2)) {
            shutterFlash.toggle()
        }
    }
    
    func retakePhoto() {
        state = .chosePhoto
        lastSnappedImage = nil
        resumeCamera()
        shutterFlash = true
    }
    
    func pauseCamera() {
        camera.isPreviewPaused = true
    }
    
    func resumeCamera() {
        camera.isPreviewPaused = false
    }
    
    func handleCameraPreviews() async {
        let imageStream = camera.previewStream
            .map { $0.image }

        for await image in imageStream {
            Task { @MainActor in
                viewfinderImage = image
            }
        }
    }
    
    func handleCameraPhotos() async {
        let unpackedPhotoStream = camera.photoStream
            .compactMap { self.unpackPhoto($0) }
        
        for await photoData in unpackedPhotoStream {
            Task { @MainActor in
                thumbnailImage = photoData.thumbnailImage
                if let uiImage = UIImage(data: photoData.imageData) {
                    lastSnappedImage = Image(uiImage: uiImage)
                    lastSnappedUIImage = uiImage
                }
            }
//            savePhoto(imageData: photoData.imageData)
        }
    }
    
    private func unpackPhoto(_ photo: AVCapturePhoto) -> PhotoData? {
        guard let imageData = photo.fileDataRepresentation() else { return nil }

        guard let previewCGImage = photo.previewCGImageRepresentation(),
           let metadataOrientation = photo.metadata[String(kCGImagePropertyOrientation)] as? UInt32,
              let cgImageOrientation = CGImagePropertyOrientation(rawValue: metadataOrientation) else { return nil }
        let imageOrientation = Image.Orientation(cgImageOrientation)
        let thumbnailImage = Image(decorative: previewCGImage, scale: 1, orientation: imageOrientation)
        
        let photoDimensions = photo.resolvedSettings.photoDimensions
        let imageSize = (width: Int(photoDimensions.width), height: Int(photoDimensions.height))
        let previewDimensions = photo.resolvedSettings.previewDimensions
        let thumbnailSize = (width: Int(previewDimensions.width), height: Int(previewDimensions.height))
        
        return PhotoData(thumbnailImage: thumbnailImage, thumbnailSize: thumbnailSize, imageData: imageData, imageSize: imageSize)
    }
    
    func savePhoto(imageData: Data) {
        Task {
            do {
                try await photoCollection.addImage(imageData)
                WLogger.shared.error(Self.loggerCategory, "Added image data to photo collection.")
            } catch let error {
                WLogger.shared.record(error)
            }
        }
    }
    
    @MainActor
    func loadPhotos() async {
        guard !isPhotosLoaded else { return }
        
        photoLibraryAuthorized = await PhotoLibrary.checkAuthorization()
        guard photoLibraryAuthorized else {
            Self.logger.error("Photo library access was not authorized.")
            return
        }
        
        Task {
            do {
                try await self.photoCollection.load()
                await self.loadThumbnail()
            } catch let error {
                Self.logger.error("Failed to load photo collection: \(error.localizedDescription)")
            }
            self.isPhotosLoaded = true
        }
    }
    
    func loadThumbnail() async {
        if photoCollection.photoAssets.count == 0 {
            return
        }
        
        guard let asset = photoCollection.photoAssets.first else { return }
        await photoCollection.cache.requestImage(for: asset, targetSize: CGSize(width: 256, height: 256))  { result in
            if let result = result {
                Task { @MainActor in
                    self.thumbnailImage = result.image
                }
            }
        }
    }
}

enum ConversationImageViewState: Equatable  {
    case chosePhoto
    case photoChosen
    case scanBarcode
    case barcodeScanned
}

fileprivate struct PhotoData {
    var thumbnailImage: Image
    var thumbnailSize: (width: Int, height: Int)
    var imageData: Data
    var imageSize: (width: Int, height: Int)
}

fileprivate extension CIImage {
    var image: Image? {
        let ciContext = CIContext()
        guard let cgImage = ciContext.createCGImage(self, from: self.extent) else { return nil }
        return Image(decorative: cgImage, scale: 1, orientation: .up)
    }
}

fileprivate extension Image.Orientation {

    init(_ cgImageOrientation: CGImagePropertyOrientation) {
        switch cgImageOrientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        }
    }
}

struct SendImageResult {
    let text: String
    let meal: Meal
    let localImagePath: String
}
