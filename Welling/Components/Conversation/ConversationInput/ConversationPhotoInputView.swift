//
//  ConversationImageInputView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-12.
//

import SwiftUI

struct ConversationPhotoInputView: View {
    @EnvironmentObject var um: UserManager
    @Binding var present: Bool
    @StateObject var viewModel: ConversationImageInputViewModel = ConversationImageInputViewModel()
    @State var viewFinderHeight: CGFloat = 0
    @FocusState var textFieldFocus: Bool
    
    var onSend: (_ body: String, _ meal: Meal, _ localImagePath: String) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                VStack(alignment: .center) {
                    Text("Photo")
                        .fontWithLineHeight(Theme.Text.h5)
                        .foregroundStyle(Theme.Colors.TextPrimary100)
                }
                
                HStack {
                    if viewModel.state == .chosePhoto || viewModel.state == .scanBarcode {
                        IconButtonView("xmark", showBackgroundColor: true) {
                            onXMark()
                        }
                    } else {
                        IconButtonView("arrow-left-long", showBackgroundColor: true) {
                            onBackTapped()
                        }
                    }
                    Spacer()
                }
            }
            .padding(.top, Theme.Spacing.xsmall)
            
            
            VStack {
                switch viewModel.state {
                case .chosePhoto:
                    ViewfinderView(image: $viewModel.viewfinderImage)
                case .photoChosen:
                    VStack {
                        if let _ = viewModel.lastSnappedImage {
                            ViewfinderView(image: $viewModel.lastSnappedImage)
                        } else if let _ = viewModel.viewfinderImage {
                            ViewfinderView(image: $viewModel.viewfinderImage)
                        } else {
                            ProgressView()
                        }
                    }
                    .overlay {
                        Rectangle()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .foregroundStyle(.black)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Spacing.xlarge))
                            .opacity(viewModel.shutterFlash ? 1 : 0)
                    }
                case .scanBarcode:
                    ViewfinderView(image: $viewModel.viewfinderImage)
                case .barcodeScanned:
                    VStack {
                        if let _ = viewModel.lastSnappedImage {
                            ViewfinderView(image: $viewModel.lastSnappedImage)
                        } else if let _ = viewModel.viewfinderImage {
                            ViewfinderView(image: $viewModel.viewfinderImage)
                        } else {
                            ProgressView()
                        }
                    }
                }
                Spacer()
            }
            .padding(.top, Theme.Spacing.navBar)
            
            VStack {
                switch viewModel.state {
                case .chosePhoto:
                    PhotoInputTakePhotoControlsView(photoLibraryAuthorized: $viewModel.photoLibraryAuthorized, photoCollection: $viewModel.photoCollection, onChosePhotoFromLibrary: viewModel.chosePhotoFromLibrary, onSwitchCameraDevice: viewModel.camera.switchCaptureDevice, onTakePhoto: viewModel.takePhoto, onRecentPhotoChosen: viewModel.onRecentPhotoChosen)
                case .photoChosen:
                    PhotoInputPhotoTakenControlsView(meal: $viewModel.chosenMeal, textFocused: $textFieldFocus, text: $viewModel.text, isSaving: $viewModel.isSaving) {
                        Task { @MainActor in
                            self.viewModel.isSaving = true
                            let result = await self.viewModel.onSave(uid: um.user.uid)
                            guard let result = result else {
                                self.viewModel.isSaving = false
                                return
                            }
                            
                            onSend(result.text, result.meal, result.localImagePath)
                            onXMark()
                            
                            self.viewModel.isSaving = false
                        }
                    }
                case .scanBarcode:
                    HStack {
                        Spacer()
                        SnapPictureButton(disabled: true) {
                            
                        }
                        Spacer()
                    }
                case .barcodeScanned:
                    VStack {
                        
                    }
                }
            }
            .padding(Theme.Spacing.medium)
            .background(Theme.Colors.SurfacePrimary100)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.xlarge))
        }
        .padding(.horizontal, Theme.Spacing.small)
        .background(Theme.Colors.SurfaceNeutral05)
        .onDisappear {
            onDismiss()
        }.fullScreenCover(isPresented: $viewModel.presentPhotoCollectionView, onDismiss: viewModel.onChosePhotoLibraryDismissed) {
            PhotoCollectionView(photoCollection: viewModel.photoCollection)
                .environmentObject(viewModel)
        }
        .alert(isPresented: $viewModel.presentLibraryAccessRequired) {
            Alert (title: Text("Camera access required to take photos"),
                   message: Text("Go to settings to grant permissions."),
                   primaryButton: .default(Text("Settings"), action: {
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }),
                   secondaryButton: .default(Text("Cancel")))
        }
        .alert(isPresented: $viewModel.presentCameraAccessRequired) {
            Alert (title: Text("Library access required to chose photos"),
                   message: Text("Go to settings to grant permissions."),
                   primaryButton: .default(Text("Settings"), action: {
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }),
                   secondaryButton: .default(Text("Cancel")))
        }
        .task {
            await viewModel.startCamera()
            await viewModel.loadPhotos()
            await viewModel.loadThumbnail()
        }
    }
    
    @MainActor
    func onXMark() {
        if textFieldFocus {
            textFieldFocus = false
        }
        viewModel.stopCamera()
        present = false
    }
    
    @MainActor 
    func onDismiss() {
        viewModel.stopCamera()
    }
    
    @MainActor
    func onBackTapped() {
        if textFieldFocus {
            textFieldFocus = false
            return
        }
        viewModel.retakePhoto()
    }
}

struct PhotoInputPhotoTakenControlsView: View {
    @Binding var meal: Meal?
    @FocusState.Binding var textFocused: Bool
    @Binding var text: String
    @Binding var isSaving: Bool
    let onSend: () -> Void
    
    init(meal: Binding<Meal?>, textFocused: FocusState<Bool>.Binding, text: Binding<String>, isSaving: Binding<Bool>, onSend: @escaping () -> Void) {
        self._meal = meal
        self._textFocused = textFocused
        self._text = text
        self._isSaving = isSaving
        self.onSend = onSend
    }
    
    var body: some View {
        VStack(spacing: Theme.Spacing.medium) {
            MealPickerUI(meal: $meal) { meal in
                
            }
            
            TextField("Add details or ask a question...", text: $text)
                .textFieldStyle(WellingTextFeldStyle())
                .submitLabel(.done)
                .focused($textFocused)
                .onSubmit {
                   textFocused = false
                }
            HStack {
                Spacer()
                SendButton(isSaving: $isSaving) {
                   onSend()
                }
                Spacer()
            }
        }
    }
}

struct PhotoInputTakePhotoControlsView: View {
    @Binding var photoLibraryAuthorized: Bool
    @Binding var photoCollection: PhotoCollection
    @Binding var photoAssetCollection: PhotoAssetCollection
    let onChosePhotoFromLibrary: () -> Void
    let onSwitchCameraDevice: () -> Void
    let onTakePhoto: () -> Void
    let onRecentPhotoChosen: (_ asset: PhotoAsset) -> Void
    
    init(photoLibraryAuthorized: Binding<Bool>, photoCollection: Binding<PhotoCollection>, onChosePhotoFromLibrary: @escaping () -> Void, onSwitchCameraDevice: @escaping () -> Void, onTakePhoto: @escaping () -> Void, onRecentPhotoChosen: @escaping (_ asset: PhotoAsset) -> Void) {
        self._photoLibraryAuthorized = photoLibraryAuthorized
        self._photoCollection = photoCollection
        self._photoAssetCollection = photoCollection.photoAssets
        self.onChosePhotoFromLibrary = onChosePhotoFromLibrary
        self.onSwitchCameraDevice = onSwitchCameraDevice
        self.onTakePhoto = onTakePhoto
        self.onRecentPhotoChosen = onRecentPhotoChosen
    }
    
    var body: some View {
        VStack {
            VStack {
                if !photoLibraryAuthorized {
                    VStack(spacing: 0) {
                        Text("Camera roll access for quick logging not granted")
                            .fontWithLineHeight(Theme.Text.regularRegular)
                            .foregroundStyle(Theme.Colors.TextNeutral2)
                            .frame(alignment: .center)
                            .multilineTextAlignment(.center)
                        Link("Go to settings", destination: URL(string: UIApplication.openSettingsURLString)!)
                            .fontWithLineHeight(Theme.Text.regularMedium)
                            .foregroundStyle(.blue)
                    }
                } else if photoAssetCollection.count == 0 {
                    VStack(spacing: 0) {
                        Text("Camera roll is empty")
                            .fontWithLineHeight(Theme.Text.regularRegular)
                            .foregroundStyle(Theme.Colors.TextNeutral2)
                            .frame(alignment: .center)
                            .multilineTextAlignment(.center)
                    }
                    
                } else {
                    HStack(spacing: 10) {
                        ForEach(0...3, id: \.self) { id in
                            if id < photoAssetCollection.count {
                                let asset = photoAssetCollection[id]
                                PhotoView(asset: asset, cache: photoCollection.cache)
                                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
                                    .onTapGesture {
                                        if asset == PhotoAssetCollection.defaultAsset {
                                            return
                                        }
                                        onRecentPhotoChosen(asset)
                                    }
                            } else {
                                Rectangle()
                                    .frame(width: 76, height: 76)
                                    .background(.clear)
                                    .foregroundStyle(.clear)
                            }
                        }
                    }
                }
                
            }
            .frame(height: 80)
            
            HStack {
                IconButtonView("media-image") {
                    onChosePhotoFromLibrary()
                }
                
                Spacer()
                
                SnapPictureButton(disabled: false) {
                    onTakePhoto()
                }
                
                Spacer()
                
                Button {
                    onSwitchCameraDevice()
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .frame(width: 24, height: 24)
                        .padding(.horizontal, Theme.Spacing.medium)
                        .padding(.vertical, Theme.Spacing.xsmall)
                        .foregroundStyle(Theme.Colors.TextPrimary100)
                }
            }
            .frame(height: 64)
        }
    }
}

#Preview {
    ConversationPhotoInputView(present: .constant(true)) {message, meal, imageUrl in }
}
