/*****************************************************************************
 * MediaLibraryBaseModel.swift
 *
 * Copyright © 2018 VLC authors and VideoLAN
 * Copyright © 2018 Videolabs
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

// Expose a "shadow" version without associatedType in order to use it as a type
protocol MediaLibraryBaseModel {
    init(medialibrary: MediaLibraryService)

    var anyfiles: [VLCMLObject] { get }

    var sortModel: SortModel { get }

    var updateView: (() -> Void)? { get set }

    var indicatorName: String { get }
    var cellType: BaseCollectionViewCell.Type { get }

    func anyAppend(_ item: VLCMLObject)
    func anyDelete(_ items: [VLCMLObject])
    func sort(by criteria: VLCMLSortingCriteria, desc: Bool)
}

protocol MLBaseModel: AnyObject, MediaLibraryBaseModel {
    associatedtype MLType where MLType: VLCMLObject

    init(medialibrary: MediaLibraryService)

    var files: [MLType] { get set }

    var medialibrary: MediaLibraryService { get }

    var updateView: (() -> Void)? { get set }

    var indicatorName: String { get }

    func append(_ item: MLType)
    func delete(_ items: [MLType])
    func sort(by criteria: VLCMLSortingCriteria, desc: Bool)
}

extension MLBaseModel {
    var anyfiles: [VLCMLObject] {
        return files
    }

    func anyAppend(_ item: VLCMLObject) {
        guard let item = item as? MLType else {
            preconditionFailure("MLBaseModel: Wrong underlying ML type.")
        }
        append(item)
    }

    func anyDelete(_ items: [VLCMLObject]) {
        guard let items = items as? [MLType] else {
            preconditionFailure("MLBaseModel: Wrong underlying ML type.")
        }
        delete(items)
    }

    func sort(by criteria: VLCMLSortingCriteria, desc: Bool) {
        fatalError()
    }
}

protocol SearchableMLModel {
    func contains(_ searchString: String) -> Bool
}

protocol MediaCollectionModel {
    func files(with criteria: VLCMLSortingCriteria,
               desc: Bool) -> [VLCMLMedia]?
    func sortModel() -> SortModel?
    func title() -> String
    func numberOfTracksString() -> String
}

// MARK: - Helper methods

extension MLBaseModel {
    /// Swap the given [MLType] to the cached array.
    /// This only swaps models with the same VLCMLIdentifiers
    /// - Parameter models: To be swapped models
    /// - Returns: New array of `MLType` if changes have been made, else return a unchanged cached version.
    func swapModels(with models: [MLType]) -> [MLType] {
        var newFiles = files

        // FIXME: This should be handled in a thread safe way
        for var model in models {
            for (currentMediaIndex, file) in files.enumerated()
                where file.identifier() == model.identifier() {
                    swap(&newFiles[currentMediaIndex], &model)
                    break
            }
        }
        return newFiles
    }

    func filterFilesFromDeletion(of items: [VLCMLObject]) {
        files = files.filter() {
            for item in items where $0.identifier() == item.identifier() {
                return false
            }
            return true
        }
    }

    func filterFilesFromDeletion(of ids: [VLCMLIdentifier]) {
        files = files.filter() {
            return !ids.contains($0.identifier())
        }
    }
}

extension VLCMLObject {
    static func == (lhs: VLCMLObject, rhs: VLCMLObject) -> Bool {
        return lhs.identifier() == rhs.identifier()
    }
}

extension MediaCollectionModel {
    func files(with criteria: VLCMLSortingCriteria = .default,
               desc: Bool = false) -> [VLCMLMedia]? {
        return files(with: criteria, desc: desc)
    }

    func thumbnail() -> UIImage? {
        var image: UIImage? = nil
        if image == nil {
            for track in files() ?? [] where track.thumbnailStatus() == .available {
                image = UIImage(contentsOfFile: track.thumbnail()?.path ?? "")
                break
            }
        }
        if image == nil
            || (!UserDefaults.standard.bool(forKey: kVLCSettingShowThumbnails) && self is VLCMLMediaGroup)
            || (!UserDefaults.standard.bool(forKey: kVLCSettingShowArtworks) && !(self is VLCMLMediaGroup)) {
            let isDarktheme = PresentationTheme.current == PresentationTheme.darkTheme
            if self is VLCMLMediaGroup {
                image = isDarktheme ? UIImage(named: "movie-placeholder-dark") : UIImage(named: "movie-placeholder-white")
            } else {
                image = isDarktheme ? UIImage(named: "album-placeholder-dark") : UIImage(named: "album-placeholder-white")
            }
        }
        return image
    }
}
