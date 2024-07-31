//
//  SetSignatureVC.swift
//  Doc Scanner
//
//  Created by Umar Farooq on 17/10/2020.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import UIKit
import PDFKit

class SetSignatureVC: UIViewController {

    /* MARK:- IBOutlets */
    @IBOutlet weak var pdfImageView          : UIImageView!
    @IBOutlet weak var pdfImageContainerView : UIView!
    
    /* MARK:- Properties */
    var docVC         : DocVC!
    var page          : PagesModel!
    var originalImage : UIImage?
    
    /// Transformable View
    private var _selectedTransformableView:TransformableView?
    var selectedTransformableView:TransformableView? {
        get {
            return _selectedTransformableView
        }
        set {
            
            // if other sticker choosed then resign the handler
            if _selectedTransformableView != newValue {
                if let selectedTransformableView = _selectedTransformableView {
                    selectedTransformableView.showEditingHandlers = false
                }
                _selectedTransformableView = newValue
            }
            
            // assign handler to new sticker added
            if let selectedTransformableView = _selectedTransformableView {
                selectedTransformableView.showEditingHandlers = true
                selectedTransformableView.superview?.bringSubviewToFront(selectedTransformableView)
            }
        }
    }
    
    /* MARK:- Closures */
    var didMadeSigns: ((_ type: SignatureType, _ signature: Any)->())?
    
    /* MARK:- Lifecycle */
    override func viewDidLoad() {
        super.viewDidLoad()
        initVC()
    }

}

/* MARK:- Methods */
extension SetSignatureVC {
    func initVC() {
        originalImage = UIImage(data: page.croppedImage)
        if let image  = originalImage {
            pdfImageView.image = image
        }
        
        /// Setup Signature
        didMadeSigns = { [weak self] type, signature in
            guard let self = self else { return }
            
            if type == .draw {
                let sign = signature as! CGImage
                self.createSignatureView(fromImage: sign)
            } else {
                if let sign = signature as? String {
                    self.createSignatureView(fromString: sign)
                }
            }
        }
        
        let tapSelector = #selector(didTapView(_:))
        let tapGesture  = UITapGestureRecognizer(target: self, action: tapSelector)
        self.pdfImageView.addGestureRecognizer(tapGesture)
    }
    
    func moveToSignauteVC(){
        let signatureVC            = SignatureVC(nibName: Constants.VCID.SIGNATURE, bundle: nil)
        signatureVC.setSignatureVC = self
        
        self.navigationController?.pushViewController(
            signatureVC,
            animated: true
        )
    }
    
    /// Add Signature On PDF Page
    func addSignatureOnPdfPage(){
        guard let originalImage = self.originalImage else { return }
        showSpinner(onView: view)
        
        self.selectedTransformableView?.showEditingHandlers = false
        
        let image    = pdfImageContainerView.asImage() ///Getting Image from view so that sign can be merged.
        
        let page             = PDFPage()
        var bounds           = page.bounds(for: .mediaBox)
        
        var widthMultiplier  = CGFloat(0.0)
        var heightMultiplier = CGFloat(0.0)
        
        let pageSize         = PageSize(rawValue: self.page.pageSize)!
        let scannerType      = ScannerType(rawValue: self.page.scannerType)!
        
        switch scannerType {
        case .passport, .idCard:
            widthMultiplier  = 0.5
            heightMultiplier = 0.5
        case .batch, .single, .imageToText:
            widthMultiplier  = 1.0
            heightMultiplier = 1.0
        }
        
        switch pageSize {///Sizes At 100 PPI
        case .legal:
            bounds = CGRect(
                x       : 0,
                y       : 0,
                width   : 742.5,
                height  : 1000
            )
        case .original:
            widthMultiplier  = 1.0
            heightMultiplier = 1.0
            
            guard let width  = originalImage.cgImage?.width  else { return }
            guard let height = originalImage.cgImage?.height else { return }
            
            bounds = CGRect(
                x      : 0     ,
                y      : 0     ,
                width  : width ,
                height : height
            )
        case .a4:
            bounds = CGRect(
                x      : 0,
                y      : 0,
                width  : 818.4,
                height : 1157.64
            )
        case .a5:
            bounds = CGRect(
                x      : 0,
                y      : 0,
                width  : 576.84,
                height : 818.4
            )
        case .businessCard:
            bounds = CGRect(
                x      : 0,
                y      : 0,
                width  : 346.5,
                height : 200
            )
        }
        
        page.setBounds(bounds, for: .mediaBox)
                
        ///Initilizing the renderer
        let renderer = UIGraphicsImageRenderer(
            bounds: bounds,
            format: UIGraphicsImageRendererFormat.default()
        )
        ///Preparing image
        let finalImage = renderer.image { (context) in
            ///Declaring variables
            var width  = CGFloat(0.0)
            var height = CGFloat(0.0)
            ///Getiing original image size
            guard let originalWidth  = originalImage.cgImage?.width  else { return }
            guard let originalHeight = originalImage.cgImage?.height else { return }
            ///Getting multiplier
            var multiplier = CGFloat(0.0)
            
            ///If user has scanned a card and set the page size to business card
            ///then it should be stretch to fit the page
            if scannerType == .idCard && pageSize == .businessCard {
                width  = bounds.width
                height = bounds.height
            } else {
                if originalWidth > originalHeight {
                    multiplier = CGFloat(originalHeight)/CGFloat(originalWidth)
                    
                    width  = bounds.width * widthMultiplier
                    height = width * multiplier
                } else {
                    multiplier = CGFloat(originalWidth)/CGFloat(originalHeight)
                    
                    height = bounds.height * heightMultiplier
                    width  = height * multiplier
                }
            }
            
            ///Finding the center of the page
            let midX   = ((bounds.width/2 ) - (width/2))  - bounds.origin.x
            let midY   = ((bounds.height/2) - (height/2)) - bounds.origin.y
            
            context.cgContext.saveGState()
            
            context.cgContext.translateBy(x: 0, y: bounds.height)
            context.cgContext.concatenate(
                CGAffineTransform(
                    translationX: 1,
                    y           : -1
                )
            )
            page.draw(with: .mediaBox, to: context.cgContext)
            
            context.cgContext.restoreGState()
            ///Preparing image rect
            let imageRect = CGRect(
                x      : midX  ,
                y      : midY  ,
                width  : width ,
                height : height
            )
            
            ///Drawing the image
            image.draw(in: imageRect)
        }
        
        guard let pdfPage = PDFPage(image: finalImage) else { return }
        
        pdfPage.setBounds(
            bounds,
            for: .mediaBox
        )
        
        if let pageData = pdfPage.dataRepresentation {
            var entries : [String: Any] = [:]
            entries["enhanced_image"]   = pageData
            
            CBFileManager.sharedInstance.upateData(
                withId      : self.page.id ,
                forEntity   : PAGES        ,
                withEntries : entries
            ) { [weak self] (isCompleted) in
                guard let self = self else { return }
                
                self.removeSpinner()
                
                self.navigationController?.popViewController(animated: true, completion: {
                    self.docVC.navigationController?.popViewController(animated: true)
                })
            }
        }
    }
    
    /// Creating Signature View
    func createSignatureView(fromString signature: String){
        let signatureLabel          = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
        signatureLabel.text         = signature
        
        let transformableView       = TransformableView(contentView: signatureLabel)
        transformableView.center    = CGPoint(x: 200, y: 100)
        transformableView.delegate  = self
        
        transformableView.setImage(UIImage(named: "tv-cross")!, forHandler: TransformableViewHandler.close)
        transformableView.setImage(UIImage(named: "tv-rotate")!, forHandler: TransformableViewHandler.rotate)
        transformableView.setImage(UIImage(named: "tv-flip")!, forHandler: TransformableViewHandler.flip)
        
        transformableView.showEditingHandlers = false
        self.view.addSubview(transformableView)
        
        // first off assign handler to stickerView
        self.selectedTransformableView = transformableView
    }
    
    func createSignatureView(fromImage signature: CGImage) {
        let imageView               = UIImageView(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
        imageView.image             = UIImage(cgImage: signature)
        
        let transformableView       = TransformableView(contentView: imageView)
        transformableView.center    = CGPoint(x: 200, y: 100)
        transformableView.delegate  = self
        
        transformableView.setImage(UIImage(named: "tv-cross")!, forHandler: TransformableViewHandler.close)
        transformableView.setImage(UIImage(named: "tv-rotate")!, forHandler: TransformableViewHandler.rotate)
        transformableView.setImage(UIImage(named: "tv-flip")!, forHandler: TransformableViewHandler.flip)
        
        transformableView.showEditingHandlers = false
        self.pdfImageView.addSubview(transformableView)
        
        // first off assign handler to stickerView
        self.selectedTransformableView = transformableView
    }
}

/* MARK:- Objective C Interface */
extension SetSignatureVC {
    @objc func didTapView(_ sender:UITapGestureRecognizer) {
        self.selectedTransformableView?.showEditingHandlers = false
    }
}

/* MARK:- Actions */
extension SetSignatureVC {
    @IBAction func didTapCancel(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func didTapDone(_ sender: UIButton) {
        addSignatureOnPdfPage()
    }
    
    @IBAction func didTapNewSignature(_ sender: UIButton) {
        moveToSignauteVC()
    }
}

/* MARK:- Transformable View */

///Delegate
extension SetSignatureVC: TransformableViewDelegate {
    func transformableViewDidBeginMoving(_ transformableView: TransformableView) {
            
    }
    
    func transformableViewDidChangeMoving(_ transformableView: TransformableView) {
        
    }
    
    func transformableViewDidEndMoving(_ transformableView: TransformableView) {
        
    }
    
    func transformableViewDidBeginRotating(_ transformableView: TransformableView) {
        
    }
    
    func transformableViewDidChangeRotating(_ transformableView: TransformableView) {
     
    }
    
    func transformableViewDidEndRotating(_ transformableView: TransformableView) {
     
    }
    
    func transformableViewDidClose(_ transformableView: TransformableView) {
     
    }
    
    func transformableViewDidTap(_ transformableView: TransformableView) {
        self.selectedTransformableView = transformableView
    }
}
