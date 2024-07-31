//
//  DocOptions.swift
//  Doc Scanner
//
//  Created by M Farhan on 8/19/20.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import UIKit
import PDFKit
import Vision
import VisionKit

class DocOptions: UIView {
    /* MARK:- IBOutlets  */
    @IBOutlet weak var gradientView            : UIView!
    @IBOutlet weak var ocrCrownImageView       : UIImageView!
    @IBOutlet weak var signatureCrownImageView : UIImageView!

    /* MARK:- Properties */
    var colors : [CGColor]     = [#colorLiteral(red: 0.03137254902, green: 0.6117647059, blue: 0.9725490196, alpha: 1).cgColor, #colorLiteral(red: 0.03137254902, green: 0.5176470588, blue: 0.9725490196, alpha: 1).cgColor]
    var docVC  : DocVC!
}

/* MARK:- Methods */
extension DocOptions {
    func initView() {
        MAIN_QUEUE.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self = self else { return }
            
            ///Setting Up Gradient
            let gradientLayer = Helper.getGradientLayer(
                inView      : self.gradientView,
                withColors  : self.colors,
                atLocations : [0.0, 1.0]
            )
            
            self.gradientView.layer.addSublayer(gradientLayer)
            
            self.setCrownImage(forPremiumUser: Constants.sharedInstance.isPremiumUser)
        }
    }
    
    func configureScannerVC() {
        let scannerVC = ImageScannerController(
            dataSource  : ["Single"]     ,
            document    : docVC.document ,
            isEditOrAdd : 1              ,
            delegate    : self
        )
        scannerVC.modalPresentationStyle = .fullScreen
        
        if #available(iOS 13.0, *) {
            scannerVC.navigationBar.tintColor = .label
        } else {
            scannerVC.navigationBar.tintColor = .black
        }
        
        docVC.present(scannerVC, animated: true)
    }
    
    //// SHARING START
    func checkSharingTimes(){
        if let timesShared = Constants.sharedInstance.timesShared["number"] as? Int {
            if timesShared < 3 {
                prepareForShare()
            } else {
                docVC.presentPremiumVC(fromVC: .docVC, andRefrence: docVC as Any)
            }
        } else {
            var timesShared : [String: Any] = [:]
            
            timesShared["date"]   = Date()
            timesShared["number"] = 0
            
            Constants.sharedInstance.timesShared = timesShared
            
            prepareForShare()
        }
    }
    
    func prepareForShare(){
        var pageNo : Int         = 0
        let pdfDoc : PDFDocument = PDFDocument()
        
        docVC.document.pages.forEach { (page) in
            if let docImage = PDFDocument(data: page.enhancedImage) {
                
                if !Constants.sharedInstance.isPremiumUser {
                    docImage.delegate = self
                }
                
                if let page = docImage.page(at: 0) {
                    pdfDoc.insert(
                        page,
                        at: pageNo
                    )
                    
                    pageNo += 1
                }
            }
        }
        
        if let pdfData = pdfDoc.dataRepresentation() {
            self.share(PdfFiles: [pdfData])
        }
    }
    
    func share(PdfFiles files: [Any]){
        let activityVC = UIActivityViewController(activityItems: files, applicationActivities: nil)
        
        activityVC.completionWithItemsHandler = { (_, isCompleted, _, _) in
            
            if isCompleted {
                if let timesShared = Constants.sharedInstance.timesShared["number"] as? Int {
                    Constants.sharedInstance.timesShared["number"] = timesShared + 1
                }
            }
            
        }
        
        docVC.present(activityVC, animated: true, completion: nil)
    }
    /// SHARING END
    
    func startOCR(){
        if let document = docVC.document {
            let page    = document.pages[docVC.currentPage]
            let data    = page.croppedImage
            
            if let image = UIImage(data: data) {
                guard let cgImage = image.cgImage else {
                    Helper.debugLogs(any: "Failed to get cgimage from input image.", and: "Error")
                    return
                }
                
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                do {
                    try handler.perform([docVC.ocrRequest])
                } catch {
                    Helper.debugLogs(any: error.localizedDescription, and: "Error")
                }
            } else {
                Helper.debugLogs(any: "Can't get image from data.", and: "Error")
            }
        }
    }
    
    func deletePage(){
        if let document = docVC.document {
            let page    = document.pages[docVC.currentPage]
            
            if document.pages.count > 1 {
                CBFileManager.sharedInstance.deleteData(
                    key: "id",
                    value: page.id,
                    entity: PAGES
                ) { [weak self] isSuccess in
                    guard let self = self else { return }
                    
                    if isSuccess {
                        ///Deleting Quad of the Page
                        CBFileManager.sharedInstance.deleteData(
                            key   : "id",
                            value : page.quad.id,
                            entity: QUADS
                        ) { (isFinished) in
                            if isFinished {
                                self.docVC.navigationController?.popViewController(animated: true)
                            }
                        }
                    }
                    
                }
            } else {
                CBFileManager.sharedInstance.deleteData(
                    key: "id",
                    value: document.id,
                    entity: DOCUMENTS
                ) { [weak self] isSuccess in
                    guard let self = self else { return }
                    
                    if isSuccess {
                       
                        CBFileManager.sharedInstance.deleteData(
                            key: "id",
                            value: page.id,
                            entity: PAGES
                        ) { [weak self] isSuccess in
                            guard let self = self else { return }
                            
                            if isSuccess {
                                ///Deleting Quad of the Page
                                CBFileManager.sharedInstance.deleteData(
                                    key   : "id",
                                    value : page.quad.id,
                                    entity: QUADS
                                ) { (isFinished) in
                                    if isFinished {
                                        self.docVC.navigationController?.popViewController(animated: true)
                                    }
                                }
                            }
                            
                        }
                        
                    }
                    
                }

            }
            
        }
    }
    
    func openSetSignature(){
        let page = docVC.document.pages[docVC.currentPage]
        
        let setSignatureVC   = SetSignatureVC(nibName: Constants.VCID.SET_SIGNATURE, bundle: nil)
        setSignatureVC.page  = page
        setSignatureVC.docVC = docVC
        docVC.navigationController?.pushViewController(
            setSignatureVC,
            animated: true
        )
    }
    
    func verifyPurchase(forOCR isOCR: Bool = false){
        docVC.showSpinner(onView: docVC.view)
        if let rawValue = Constants.sharedInstance.purchasedIdentifier {
            if let identifier = IAPIdentifiers(rawValue: rawValue) {
                IAPManager.sharedInstance.verifyReceipt(withIdentifier: identifier) { [weak self] state in
                    guard let self = self else { return }
                    
                    self.docVC.removeSpinner()
                    
                    switch state {
                    case .purchased:
                        if isOCR {
                            self.startOCR()
                        } else {
                            self.prepareForShare()
                        }
                    case .expired, .notPurchased:
                        if isOCR {
                            self.docVC.presentPremiumVC(
                                fromVC      : .docVC,
                                andRefrence : self.docVC as Any
                            )
                        } else {
                            self.checkSharingTimes()
                        }
                    }
                }
            } else {
                docVC.removeSpinner()
                setCrownImage(forPremiumUser: false)
                
                if isOCR {
                    docVC.presentPremiumVC(fromVC: .docVC, andRefrence: docVC as Any)
                } else {
                    checkSharingTimes()
                }
            }
        } else {
            docVC.removeSpinner()
            setCrownImage(forPremiumUser: false)
            
            if isOCR {
                docVC.presentPremiumVC(fromVC: .docVC, andRefrence: docVC as Any)
            } else {
                checkSharingTimes()
            }
        }
    }
    
    func setCrownImage(forPremiumUser isPremium: Bool) {
        ocrCrownImageView.isHidden       = isPremium
        signatureCrownImageView.isHidden = isPremium
    }
}

/* MARK:- Actions */
extension DocOptions {
    @IBAction func didTapShare(_ sender: UIButton) {
        #if DEBUG
        prepareForShare()
        #else
        if Constants.sharedInstance.isPremiumUser {
            if let expiryDate = Constants.sharedInstance.subscriptionExpiryDate {
                if Date() < expiryDate {
                    prepareForShare()
                } else {
                    checkSharingTimes()
                    setCrownImage(forPremiumUser: false)
                    Constants.sharedInstance.isPremiumUser = false
                }
            } else {
                verifyPurchase()
            }
        } else {
            checkSharingTimes()
            setCrownImage(forPremiumUser: false)
            docVC.presentPremiumVC(fromVC: .docVC, andRefrence: docVC as Any)
        }
        #endif
    }
    
    @IBAction func didTapAdd(_ sender: UIButton) {
        if Constants.sharedInstance.cameraPermission {
            configureScannerVC()
        } else {
            Helper.checkCameraPermission { (isGranted) in
                self.configureScannerVC()
            }
        }
    }
    
    @IBAction func didTapEdit(_ sender: UIButton) {
        if let document = docVC.document {
            let page        = document.pages[docVC.currentPage]
            let scannerType = ScannerType(rawValue: "Single")!
            
            let quad = Quadrilateral(
                topLeft     : page.quad.topLeft     ,
                topRight    : page.quad.topRight    ,
                bottomRight : page.quad.bottomRight ,
                bottomLeft  : page.quad.bottomLeft
            )
            
            if let image = UIImage(data: page.originalImage) {
                let editVC = EditScanVC(
                    image       : image       ,
                    quad        : quad        ,
                    rotateImage : false       ,
                    scannerType : scannerType
                )
                
                editVC.docVC       = docVC
                editVC.pageId      = page.id
                editVC.editFile    = document
                editVC.isEditOrAdd = 2 /// Means user want's to edit the already scanned image
                
                docVC.navigationController?.pushViewController(
                    editVC,
                    animated: false
                )
            }
        }
    }
    
    @IBAction func didTapSignature(_ sender: UIButton) {
        #if DEBUG
        openSetSignature()
        #else
        if Constants.sharedInstance.isPremiumUser {
            if let expiryDate = Constants.sharedInstance.subscriptionExpiryDate {
                if Date() < expiryDate {
                    openSetSignature()
                } else {
                    setCrownImage(forPremiumUser: false)
                    Constants.sharedInstance.isPremiumUser = false
                    docVC.presentPremiumVC(fromVC: .docVC, andRefrence: docVC as Any)
                }
            } else {
                verifyPurchase()
            }
        } else {
            setCrownImage(forPremiumUser: false)
            docVC.presentPremiumVC(fromVC: .docVC, andRefrence: docVC as Any)
        }
        #endif
    }
    
    @IBAction func didTapOCR(_ sender: UIButton) {
        #if DEBUG
        startOCR()
        #else
        if Constants.sharedInstance.isPremiumUser {
            if let expiryDate = Constants.sharedInstance.subscriptionExpiryDate {
                if Date() < expiryDate {
                    startOCR()
                } else {
                    setCrownImage(forPremiumUser: false)
                    Constants.sharedInstance.isPremiumUser = false
                    docVC.presentPremiumVC(fromVC: .docVC, andRefrence: docVC as Any)
                }
            } else {
                verifyPurchase(forOCR: true)
            }
        } else {
            setCrownImage(forPremiumUser: false)
            docVC.presentPremiumVC(fromVC: .docVC, andRefrence: docVC as Any)
        }
        #endif
    }
    
    @IBAction func didTapDelete(_ sender: UIButton) {
        let alert = UIAlertController(
            title          : APP_NAME,
            message        : "Are you sure you want to delete this page?",
            preferredStyle : .alert
        )
        
        let yesAction = UIAlertAction(
            title: "Yes",
            style: .destructive
        ) { [weak self] _ in
            guard let self = self else { return }
            
            self.deletePage()
        }
        
        let noAction  = UIAlertAction(title: "No", style: .cancel, handler: nil)
        
        alert.addAction(yesAction)
        alert.addAction(noAction)
        
        docVC.present(alert, animated: true, completion: nil)
    }
}

/* MARK:- PDF Document */

//Delegate
extension DocOptions: PDFDocumentDelegate {
    func classForPage() -> AnyClass {
        return WatermarkPage.self
    }
}

/* MARK:- Scanner */

///Delegate
extension DocOptions: ImageScannerControllerDelegate {
    func imageScannerControllerShouldOpenDoc(_ scanner: ImageScannerController) {
        scanner.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.docVC.shouldAddNewPage()
        }
    }
    
    func imageScannerController(
        _ scanner: ImageScannerController,
        didFinishScanningWithResults results: ImageScannerResults
    ) {
        scanner.dismiss(animated: true, completion: nil)
    }
    
    func imageScannerControllerDidCancel(
        _ scanner: ImageScannerController
    ) {
        scanner.dismiss(animated: true, completion: nil)
    }
    
    func imageScannerController(
        _ scanner: ImageScannerController,
        didFailWithError error: Error
    ) {
        scanner.dismiss(animated: true, completion: nil)
    }
}
