/*
See the License.txt file for this sample’s licensing information.
*/

import SwiftUI
import os.log

struct PhotoCollectionView: View {
    @ObservedObject var photoCollection : PhotoCollection
    
    @Environment(\.displayScale) private var displayScale
    @EnvironmentObject var viewModel: ConversationImageInputViewModel
        
    private static let itemSpacing = Theme.Spacing.xxsmall
    private static let itemCornerRadius = 15.0
    private static let itemSize = CGSize(width: 130, height: 130)
    
    private var imageSize: CGSize {
        return CGSize(width: Self.itemSize.width * displayScale, height: Self.itemSize.height * displayScale)
    }
    
    private let columns = [
        GridItem(.flexible(minimum: itemSize.width, maximum: itemSize.width), spacing: itemSpacing),
        GridItem(.flexible(minimum: itemSize.width, maximum: itemSize.width), spacing: itemSpacing),
        GridItem(.flexible(minimum: itemSize.width, maximum: itemSize.width), spacing: itemSpacing)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                VStack(alignment: .center) {
                    Text("Library")
                        .fontWithLineHeight(Theme.Text.h5)
                        .foregroundStyle(Theme.Colors.TextPrimary100)
                }
                
                HStack {
                    IconButtonView("xmark", showBackgroundColor: true) {
                        viewModel.presentPhotoCollectionView = false
                    }
                    Spacer()
                }
            }
            .padding(.horizontal, Theme.Spacing.small)
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: Self.itemSpacing) {
                    ForEach(photoCollection.photoAssets, id: \.id) { asset in
                        if asset != PhotoAssetCollection.defaultAsset {
                            photoItemView(asset: asset)
                        }
                    }
                }
                .padding([.vertical], Self.itemSpacing)
            }
            .padding(.top, Theme.Spacing.navBar)
            .padding(.horizontal, Theme.Spacing.small)
        }
        .background(Theme.Colors.SurfaceNeutral05)
    }
    
    private func photoItemView(asset: PhotoAsset) -> some View {
        PhotoItemView(asset: asset, cache: photoCollection.cache, imageSize: imageSize)
            .frame(width: Self.itemSize.width, height: Self.itemSize.height)
            .clipped()
            .cornerRadius(Self.itemCornerRadius)
            .contentShape(Path(CGRect(x: 0, y: 0, width: Self.itemSize.width, height: Self.itemSize.height)))
            .onTapGesture {
                Task { @MainActor in
                    await viewModel.onPhotoFromLibraryChosen(asset: asset)
                }
            }
            .onAppear {
                Task {
                    await photoCollection.cache.startCaching(for: [asset], targetSize: imageSize)
                }
            }
            .onDisappear {
                Task {
                    await photoCollection.cache.stopCaching(for: [asset], targetSize: imageSize)
                }
            }
    }
}
