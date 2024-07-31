//
//  CBImagePickerVC.swift
//  Doc Scanner
//
//  Created by Umar Farooq on 02/11/2020.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import UIKit
import Photos

protocol CBImagePickerDelegate {
    /// Retruns an array of images that are selected by the user
    /// - Parameter images: Array of images that are selected
    func didFinishedPickingImage(_ images: [UIImage]) 
}

class CBImagePickerVC: UIViewController {

    /* MARK:- IBOutlets */
    @IBOutlet weak var albumsCV : UICollectionView!
    @IBOutlet weak var photosCV : UICollectionView!
        
    @IBOutlet weak var totalSelectedView  : UIView!
    @IBOutlet weak var totalSelectedLabel : UILabel!
    
    /* MARK:- Properties */
    private var assets : [PHAsset]            = []
    private var photos : [UIImage]            = []
    private var albums : [PHAssetCollection]  = []
    private var albumNames : [String]  = []
    
    private var selectedAlbum   : [Bool] = []
    private var selectedPhotos  : [Bool] = []
    
    public var delegate: CBImagePickerDelegate?
    
    /* MARK:- Computed Properties */
    private var photosCellSize: CGSize  {
        get {
            let totalWidth = photosCV.frame.width * 0.95
            let width      = totalWidth/3
            let height     = width * 1.0
            
            return CGSize(width: width, height: height)
        }
    }
    
    private var albumsCellSize: CGSize  {
        get {
            let totalWidth = photosCV.frame.width * 0.95
            let width      = totalWidth/4
            let height     = CGFloat(20.0)
            
            return CGSize(width: width, height: height)
        }
    }
    
    private var photosCellLineSpacing: CGFloat {
        get {
            return photosCV.frame.width * 0.05
        }
    }
    
    private var albumsCellLineSpacing: CGFloat {
        get {
            return photosCV.frame.width * 0.05
        }
    }
    
    /* MARK:- Lazy Properties */
    private lazy var photosCellNib: UINib = {
        return UINib(
            nibName: CBImagePickerConstants.cellNib.CB_IMAGE_PICKER,
            bundle : nil
        )
    }()
    
    private lazy var albumsCellNib: UINib = {
        return UINib(
            nibName: CBImagePickerConstants.cellNib.CB_ALBUM_NAME,
            bundle : nil
        )
    }()
    
    /* MARK:- Life Cycle */
    override func viewDidLoad() {
        super.viewDidLoad()
        initVC()
    }

    deinit {
        Helper.debugLogs(any: "CBImagePickerVC deinit successfully")
    }
}

/* MARK:- Methods */
extension CBImagePickerVC {
    func initVC(){
        MAIN_QUEUE.async { [weak self] in
            guard let self = self else { return }
            self.totalSelectedView.layer.cornerRadius = 26
        }
        registerNib()
    }
    
    private func registerNib(){
        photosCV.register(
            photosCellNib,
            forCellWithReuseIdentifier: CBImagePickerConstants.cellNib.CB_IMAGE_PICKER
        )
        
        albumsCV.register(
            albumsCellNib,
            forCellWithReuseIdentifier: CBImagePickerConstants.cellNib.CB_ALBUM_NAME
        )
                
        /// Fetch collections name
        fetchAlbums()
    }
    
    private func fetchAlbums(){
        showSpinner(onView: view)
        albums.removeAll()
        albumNames.removeAll()
        selectedAlbum.removeAll()
        
        BG_QUEUE.async { [weak self] in
            guard let self = self else { return }
            let albums = PHAssetCollection.fetchAssetCollections(
                with    : .album,
                subtype : .any,
                options : nil
            )
            
            MAIN_QUEUE.async {
                albums.enumerateObjects { (object, count, stop) in
                    
                    if let name = object.localizedTitle {
                        self.albums.append(object)
                        self.albumNames.append(name)
                        self.selectedAlbum.append(false)
                    }
                }
                
                self.selectedAlbum.insert(true, at: 0)
                self.albumNames.insert("Camera Roll", at: 0)
                
                self.albumsCV.reloadData()
                
                /// Fetching assets to be shown in gallery
                self.fetchPhotos()
            }
        }
    }
    
    /// Fetch Photos from specific album/ all gallery
    /// - Parameter album: Collection of ablum to fetch images from (Pass nothing to get all)
    private func fetchPhotos(fromAlbum album: PHAssetCollection? = nil){
        let fetchOptions             = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        /// Removing old assets so that we've only new ones
        self.assets.removeAll()
        
        if let album = album {
            Helper.debugLogs(any: "Fetching From One Album")
            photos.removeAll()
            selectedPhotos.removeAll()
            
            photosCV.reloadData()
            
            BG_QUEUE.async { [weak self] in
                guard let self = self else {return}
                
                let results = PHAsset.fetchAssets(in: album, options: fetchOptions)
                
                results.enumerateObjects {(asset, _, _) in
                    self.assets.append(asset)
                }
                
                if self.assets.count > 0 {
                    self.requestImage(
                        atIndex : 0
                    )
                }
            }
        } else {
            Helper.debugLogs(any: "Fetching From All Album")
            photos.removeAll()
            selectedPhotos.removeAll()
            
            photosCV.reloadData()
            
            BG_QUEUE.async { [weak self] in
                guard let self = self else {return}
                
                let results = PHAsset.fetchAssets(with: .image, options: fetchOptions)
                
                results.enumerateObjects {(asset, _, _) in
                    self.assets.append(asset)
                }
                
                if self.assets.count > 0 {
                    self.requestImage(
                        atIndex : 0
                    )
                }
                
            }
            
        }
        
    }
    
    private func requestImage(atIndex index: Int){
        if index < assets.count && index < 200 {
            let requestOptions           = PHImageRequestOptions()
            requestOptions.isSynchronous = false
            requestOptions.deliveryMode  = .highQualityFormat
            
            let manager = PHImageManager.default()
            
            manager.requestImage(
                for         : assets[index]             ,
                targetSize  : PHImageManagerMaximumSize ,
                contentMode : .aspectFill               ,
                options     : requestOptions
            ) { image, _ in
                if let image = image {
                    self.photos.append(image)
                    self.selectedPhotos.append(false)
                } else {
                    Helper.debugLogs(any: "Converting asset to image", and: "Error")
                }
                
                /// Recursive Call
                self.requestImage(atIndex: index + 1)
            }
        } else {
            MAIN_QUEUE.async { [weak self] in
                guard let self = self else {return}
                
                self.photosCV.reloadData()
                self.removeSpinner()
            }
        }
    }
    
    func updateTotalSelected(){
        let count = selectedPhotos.filter({ $0 == true }).count
        if count > 0 {
            totalSelectedLabel.text    = "Selected(\(count))"
            totalSelectedView.isHidden = false
        } else {
            totalSelectedLabel.text    = "Selected(0)"
            totalSelectedView.isHidden = true
        }
        
    }
}

/* MARK:- Actions */
extension CBImagePickerVC {
    @IBAction func didTapCancel (_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didTapNext (_ sender: UIButton) {
        dismiss(animated: true) { [weak self] in
            guard let self = self else {return}
            
            if let delegate = self.delegate {
                var selectedImages: [UIImage] = []
                self.selectedPhotos.enumerated().forEach { (index,isSelected) in
                    if isSelected {
                        selectedImages.append(self.photos[index])
                    }
                }
                delegate.didFinishedPickingImage(selectedImages)
            }
        }
    }
}

/* MARK:- Collection View */

/// Datasource
extension CBImagePickerVC: UICollectionViewDataSource {
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        if collectionView == photosCV {
            return self.photos.count
        } else {
            return self.albumNames.count
        }
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        
        if collectionView == photosCV {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier : CBImagePickerConstants.cellNib.CB_IMAGE_PICKER,
                for                 : indexPath
            ) as! CBImagePickerCell
            
            let row = indexPath.row
            
            cell.isSelected           = selectedPhotos[row]
            cell.assetImageView.image = photos[row]
            
            cell.setSelected()
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier : CBImagePickerConstants.cellNib.CB_ALBUM_NAME,
                for                 : indexPath
            ) as! CBImagePickerAlbumCell
            
            let row = indexPath.row
            
            cell.isSelected     = selectedAlbum[row]
            cell.nameLabel.text = albumNames[row]
            
            cell.setSelected()
            
            return cell
        }
        
    }
    
}

/// Delegate
extension CBImagePickerVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == photosCV {
            let cell = collectionView.cellForItem(at: indexPath) as! CBImagePickerCell
            let row  = indexPath.row
            
            selectedPhotos[row] = !selectedPhotos[row]
            cell.isSelected     = selectedPhotos[row]
            
            updateTotalSelected()
            
            collectionView.reloadData()
        } else {
            for i in 0..<selectedAlbum.count {
                selectedAlbum[i] = false
            }
            
            let cell = collectionView.cellForItem(at: indexPath) as! CBImagePickerAlbumCell
            let row  = indexPath.row
            
            cell.isSelected    = true
            selectedAlbum[row] = true
            
            showSpinner(onView: view)
            
            if row != 0 {
                /// Because in album names we've
                /// added a custom name i.e. "Camera Roll"
                fetchPhotos(fromAlbum: albums[row - 1])  
            } else {
                fetchPhotos()
            }
            
            totalSelectedLabel.text    = "Selected(0)"
            totalSelectedView.isHidden = true
            
            collectionView.reloadData()
        }
    }
}

/// Flow Layout Delegate
extension CBImagePickerVC: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        
        if collectionView == photosCV {
            return photosCellSize
        } else {
            return albumsCellSize
        }
        
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        
        if collectionView == photosCV {
            return photosCellLineSpacing
        } else {
            return albumsCellLineSpacing
        }
        
    }
}
