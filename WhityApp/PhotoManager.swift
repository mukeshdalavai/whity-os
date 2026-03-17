import Photos

class PhotoManager {

    static func fetchLatestMetaPhoto(completion: @escaping (Data?) -> Void) {

        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            
            print("PHOTO AUTH STATUS:", status.rawValue)

            guard status == .authorized || status == .limited else {
                print("Photo permission denied")
                completion(nil)
                return
            }

            let collections = PHAssetCollection.fetchAssetCollections(
                with: .album,
                subtype: .any,
                options: nil
            )

            var metaAlbum: PHAssetCollection?

            collections.enumerateObjects { collection, _, stop in
                print("ALBUM FOUND:", collection.localizedTitle ?? "nil")
                if collection.localizedTitle == "Meta AI" {
                    metaAlbum = collection
                    stop.pointee = true
                }
            }

            guard let album = metaAlbum else {
                completion(nil)
                return
            }

            let options = PHFetchOptions()
            options.sortDescriptors = [
                NSSortDescriptor(key: "creationDate", ascending: false)
            ]
            options.fetchLimit = 1

            let assets = PHAsset.fetchAssets(in: album, options: options)
            print("META AI ASSET COUNT:", assets.count)

            guard let asset = assets.firstObject else {
                completion(nil)
                return
            }

            let manager = PHImageManager.default()

            let requestOptions = PHImageRequestOptions()
            requestOptions.isSynchronous = true

            manager.requestImageDataAndOrientation(
                for: asset,
                options: requestOptions
            ) { data, _, _, _ in
                if let data = data {
                    print("IMAGE DATA SIZE:", data.count)
                    completion(data)
                } else {
                    print("IMAGE DATA NIL")
                    completion(nil)
                }
            }

        }
    }
}
