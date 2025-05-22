/*
See the License.txt file for this sample’s licensing information.
*/

import Photos

@MainActor
class PhotoAssetCollection: RandomAccessCollection {
    static let defaultAsset: PhotoAsset = .init()
    
    private(set) var fetchResult: PHFetchResult<PHAsset>
    private var iteratorIndex: Int = 0
    
    private var cache = [Int : PhotoAsset]()
    
    var startIndex: Int { 0 }
    var endIndex: Int { fetchResult.count }
    
    init(_ fetchResult: PHFetchResult<PHAsset>) {
        self.fetchResult = fetchResult
    }

    subscript(position: Int) -> PhotoAsset {
        if let asset = cache[position] {
            return asset
        }
        
        // Seomtimes, it seems that fetchResult is mutated under us..
        if position >= fetchResult.count {
            return Self.defaultAsset
        }
        let asset = PhotoAsset(phAsset: fetchResult.object(at: position), index: position)
        DispatchQueue.main.async { [weak self] in
            self?.cache[position] = asset
        }
        return asset
    }
    
    var phAssets: [PHAsset] {
        var assets = [PHAsset]()
        fetchResult.enumerateObjects { (object, count, stop) in
            assets.append(object)
        }
        return assets
    }
}

extension PhotoAssetCollection: Sequence, IteratorProtocol {

    @MainActor
    func next() -> PhotoAsset? {
        if iteratorIndex >= count {
            return nil
        }
        
        defer {
            iteratorIndex += 1
        }
        
        return self[iteratorIndex]
    }
}

