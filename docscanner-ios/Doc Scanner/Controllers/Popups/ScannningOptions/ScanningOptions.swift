//
//  ScanningOptions.swift
//  Doc Scanner
//
//  Created by M Farhan on 7/27/20.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import VisionKit

class ScanningOptions: UIViewController {
    
    /* MARK:- IBOutlets  */
    @IBOutlet weak var gradientView             : UIView!
    @IBOutlet weak var multiPhotoCrownImageView : UIImageView!
    ///Labels Outlets
    @IBOutlet weak var cameralabel     : UILabel!
    @IBOutlet weak var multiImageslabel: UILabel!
    ///Constraints Outlets
    @IBOutlet weak var cameraWidth      : NSLayoutConstraint!
    @IBOutlet weak var closeBtnWidth    : NSLayoutConstraint!
    @IBOutlet weak var multiImagesWidth : NSLayoutConstraint!
    @IBOutlet weak var crownImagesWidth : NSLayoutConstraint!
    
    /* MARK:- Properties */
    var colors: [CGColor] = [#colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.5).cgColor, #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1).cgColor, #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1).cgColor]
    var docsVC: DocsVC?
    
    /* MARK:- LifeCycle */
    override func viewDidLoad() {
        super.viewDidLoad()
        initView()
    }
}

/* MARK:- Methods */
extension ScanningOptions {
    func initView(){
        MAIN_QUEUE.asyncAfter(deadline: .now() + 0.05) {
            ///Setting Up Images Proportional Sizes
            switch Helper.device() {
            case .iPad:
                self.cameraWidth.constant      = 30.0
                self.closeBtnWidth.constant    = 110.0
                self.crownImagesWidth.constant = 26.0
                self.multiImagesWidth.constant = 30.0
                
                ///Setting Up Font Size
                let font1                      = self.cameralabel.font
                self.cameralabel.font          = font1?.withSize(26.0)
                
                let font2                      = self.multiImageslabel.font
                self.multiImageslabel.font     = font2?.withSize(26.0)
            case .bezeliPhone, .bezelLessiPhone:
                self.cameraWidth.constant      = 18.0
                self.closeBtnWidth.constant    = 80.0
                self.crownImagesWidth.constant = 10.0
                self.multiImagesWidth.constant = 18.0
                
                ///Setting Up Font Size
                let font1                      = self.cameralabel.font
                self.cameralabel.font          = font1?.withSize(18.0)
                
                let font2                      = self.multiImageslabel.font
                self.multiImageslabel.font     = font2?.withSize(18.0)
            }
            ///Setting Up Gradient
            let gradientLayer = Helper.getGradientLayer(
                inView      : self.gradientView,
                withColors  : self.colors,
                atLocations : [0.0, 0.8, 1.0]
            )
            
            self.gradientView.layer.addSublayer(gradientLayer)
        }
        
        /* Uncomment the commented code to make this a premium feature. */
//        setCrownImage(forPremiumUser: Constants.sharedInstance.isPremiumUser)
    }
    
    func configureScannerVC(){
        ///Opening Scanner VC
        if let docsVC = self.docsVC {
            self.dismiss(animated: true) {
                docsVC.didTapScannerButton?()
            }
        }
    }
    
    /// Not in use right now as this feature is made free for all users
    func verifyPurchase(){
        showSpinner(onView: view)
        if let rawValue = Constants.sharedInstance.purchasedIdentifier {
            if let identifier = IAPIdentifiers(rawValue: rawValue) {
                IAPManager.sharedInstance.verifyReceipt(withIdentifier: identifier) { [weak self] state in
                    guard let self = self else { return }
                    
                    self.removeSpinner()
                    
                    switch state {
                    case .purchased:
                        self.openGallery()
                    case .expired, .notPurchased:
                        self.setCrownImage(forPremiumUser: false)
                        self.presentPremiumVC(fromVC: .scanningOptionsVC, andRefrence: self as Any)
                    }
                }
            } else {
                removeSpinner()
                setCrownImage(forPremiumUser: false)
                presentPremiumVC(fromVC: .scanningOptionsVC, andRefrence: self as Any)
            }
        } else {
            removeSpinner()
            setCrownImage(forPremiumUser: false)
            presentPremiumVC(fromVC: .scanningOptionsVC, andRefrence: self as Any)
        }
    }
    
    func checkUserStatusForSelectingMultipleImages() {
        /* Uncomment the commented code to make this a premium feature. */
//        #if DEBUG
        openGallery()
//        #else
//        if Constants.sharedInstance.isPremiumUser {
//            if let expiryDate = Constants.sharedInstance.subscriptionExpiryDate {
//                if Date() < expiryDate {
//                    openGallery()
//                } else {
//                    setCrownImage(forPremiumUser: false)
//                    Constants.sharedInstance.isPremiumUser = false
//                    self.presentPremiumVC(fromVC: .scanningOptionsVC, andRefrence: self as Any)
//                }
//            } else {
//                verifyPurchase()
//            }
//        } else {
//            setCrownImage(forPremiumUser: false)
//            self.presentPremiumVC(fromVC: .scanningOptionsVC, andRefrence: self as Any)
//        }
//        #endif
    }
    
    func openGallery(){
        let cbImagePickerVC = CBImagePickerVC(
            nibName: Constants.VCID.IMAGE_PICKER,
            bundle: nil
        )
        
        cbImagePickerVC.delegate               = self
        
        cbImagePickerVC.modalTransitionStyle   = .coverVertical
        cbImagePickerVC.modalPresentationStyle = .overFullScreen
        
        present(cbImagePickerVC, animated: true, completion: nil)
    }
    
    func setCrownImage(forPremiumUser isPremium: Bool) {
        /* Uncomment the commented code to make this a premium feature. */
//        multiPhotoCrownImageView.isHidden = isPremium
    }
}

/* MARK:- Actions */
extension ScanningOptions {
    @IBAction func didTapScanWithCamera(_ sender: UIButton){
        if Constants.sharedInstance.cameraPermission {
            configureScannerVC()
        } else {
            Helper.checkCameraPermission { [weak self] (isGranted) in
                guard let self = self else {return}
                if isGranted {
                    self.configureScannerVC()
                }
            }
        }
    }
    
    @IBAction func didTapSelectMultiplePhotos(_ sender: UIButton){
        if Constants.sharedInstance.photoGalleryPermission {
            checkUserStatusForSelectingMultipleImages()
        } else {
            Helper.checkPhotoGalleryPermission { [weak self] (isGranted) in
                guard let self = self else { return }
                if isGranted {
                    self.checkUserStatusForSelectingMultipleImages()
                }
            }
        }
    }
    
    @IBAction func didTapCancel (_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}

/* MARK:- CBImage Picker */

/// Delegate
extension ScanningOptions: CBImagePickerDelegate {
    func didFinishedPickingImage(_ images: [UIImage]) {
        guard images.count > 0 else { return }
        
        var scannerType: ScannerType = .batch
        
        if images.count == 1 {
            scannerType = .single
        } else {
            scannerType = .batch
        }
        
        var quads: [Quadrilateral] = []
        
        images.forEach { (image) in
            quads.append(EditScanVC.defaultQuad(forImage: image))
        }
        
        let  editVC = EditScanVC(
            images      : images,
            quads       : quads ,
            rotateImage : false ,
            scannerType : scannerType
        )
        
        editVC.isFromGallery = true
        
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            
            if let docsVC = self.docsVC {
                docsVC.navigationController?.pushViewController(
                    editVC,
                    animated: false
                )
            }
        }
    }
}
