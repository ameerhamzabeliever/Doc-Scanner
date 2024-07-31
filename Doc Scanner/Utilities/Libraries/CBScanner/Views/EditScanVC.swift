//
//  EditScanVC.swift
//  Doc Scanner
//
//  Created by M Farhan on 8/25/20.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import UIKit
import AVKit

class EditScanVC: UIViewController {

    /* MARK:- @IBOutlet */
    @IBOutlet weak var scanedImageContainerView: UIView!
    
    /* MARK:- Properties */
    private let image                 : UIImage
    private var quad                  : Quadrilateral
    private var zoomGestureController : ZoomGestureController!
    
    private var quadViewWidthConstraint  = NSLayoutConstraint()
    private var quadViewHeightConstraint = NSLayoutConstraint()
    
    private var datasource: [String] = [
        "Legal"         ,
        "Original"      ,
        "A4"            ,
        "A5"            ,
        "Business Card"
    ]
    
    /* MARK:- Lazy Properties */
    private lazy var imageView: UIImageView = {
        let imageView               = UIImageView()
        imageView.clipsToBounds     = true
        imageView.isOpaque          = true
        imageView.image             = image
        imageView.backgroundColor   = .black
        imageView.contentMode       = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var quadView: QuadrilateralView = {
        let quadView      = QuadrilateralView()
        quadView.editable = true
        quadView.translatesAutoresizingMaskIntoConstraints = false
        return quadView
    }()
    
    init(image: UIImage, quad: Quadrilateral?, rotateImage: Bool = true) {
        self.image = rotateImage ? image.applyingPortraitOrientation() : image
        self.quad  = quad ?? EditScanVC.defaultQuad(forImage: image)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /* MARK:- Life Cycle */
    override func viewDidLoad() {
        super.viewDidLoad()
        initVC()
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        adjustQuadViewConstraints()
        displayQuad()
    }
    
}

/* MARK:- Methods */
extension EditScanVC {
    func initVC(){
        scanedImageContainerView.addSubview(imageView)
        scanedImageContainerView.addSubview(quadView)
        
        setupConstraints()
        
        zoomGestureController = ZoomGestureController(
            image    : image,
            quadView : quadView
        )
        
        let touchDown = UILongPressGestureRecognizer(
            target: zoomGestureController,
            action: #selector(zoomGestureController.handle(pan:))
        )
        
        touchDown.minimumPressDuration = 0
        scanedImageContainerView.addGestureRecognizer(touchDown)
    }
    
    private func setupConstraints() {
        let imageViewConstraints = [
            imageView.topAnchor.constraint(
                equalTo: scanedImageContainerView.topAnchor
            ),
            imageView.trailingAnchor.constraint(
                equalTo: scanedImageContainerView.trailingAnchor
            ),
            imageView.bottomAnchor.constraint(
                equalTo: scanedImageContainerView.bottomAnchor
            ),
            imageView.leadingAnchor.constraint(
                equalTo: scanedImageContainerView.leadingAnchor
            )
        ]
        
        quadViewWidthConstraint  = quadView.widthAnchor.constraint(
            equalToConstant: 0.0
        )
        quadViewHeightConstraint = quadView.heightAnchor.constraint(
            equalToConstant: 0.0
        )
        
        let quadViewConstraints = [
            quadView.centerXAnchor.constraint(
                equalTo: scanedImageContainerView.centerXAnchor
            ),
            quadView.centerYAnchor.constraint(
                equalTo: scanedImageContainerView.centerYAnchor
            ),
            quadViewWidthConstraint,
            quadViewHeightConstraint
        ]
        
        NSLayoutConstraint.activate(quadViewConstraints + imageViewConstraints)
    }
    
    private func displayQuad() {
        let imageSize  = image.size
        let imageFrame = CGRect(
            origin: quadView.frame.origin,
            size  : CGSize(
                width : quadViewWidthConstraint.constant,
                height: quadViewHeightConstraint.constant
            )
        )
        
        let scaleTransform = CGAffineTransform.scaleTransform(
            forSize          : imageSize,
            aspectFillInSize : imageFrame.size
        )
        
        let transforms      = [scaleTransform]
        let transformedQuad = quad.applyTransforms(transforms)
        
        quadView.drawQuadrilateral(quad: transformedQuad, animated: false)
    }
    
    private func adjustQuadViewConstraints() {
        let frame = AVMakeRect(
            aspectRatio: image.size,
            insideRect : imageView.bounds
        )
        
        quadViewWidthConstraint.constant  = frame.size.width
        quadViewHeightConstraint.constant = frame.size.height
    }
 
    private static func defaultQuad(forImage image: UIImage) -> Quadrilateral {
        let topLeft = CGPoint(
            x: image.size.width * 0.05,
            y: image.size.height * 0.05
        )
        let topRight = CGPoint(
            x: image.size.width * 0.95,
            y: image.size.height * 0.05
        )
        let bottomRight = CGPoint(
            x: image.size.width * 0.95,
            y: image.size.height * 0.95
        )
        let bottomLeft = CGPoint(
            x: image.size.width * 0.05,
            y: image.size.height * 0.95
        )
        
        let quad = Quadrilateral(
            topLeft     : topLeft,
            topRight    : topRight,
            bottomRight : bottomRight,
            bottomLeft  : bottomLeft
        )
        
        return quad
    }
}

/* MARK:- Actions */
extension EditScanVC {
    @IBAction func didTapBackRetake(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func didTapDelete(_ sender: UIButton) {
        if let imageScannerController = navigationController as? ImageScannerController {
            imageScannerController.imageScannerDelegate?.imageScannerControllerDidCancel(
                imageScannerController
            )
        }
    }
    
    @IBAction func didTapDone(_ sender: UIButton) {
        guard let quad  = quadView.quad,
            let ciImage = CIImage(image: image) else {
                if let imageScannerController = navigationController as? ImageScannerController {
                    let error = ImageScannerControllerError.ciImageCreation
                    imageScannerController.imageScannerDelegate?.imageScannerController(
                        imageScannerController,
                        didFailWithError: error
                    )
                }
                return
        }
        let cgOrientation = CGImagePropertyOrientation(image.imageOrientation)
        let orientedImage = ciImage.oriented(forExifOrientation: Int32(cgOrientation.rawValue))
        let scaledQuad = quad.scale(quadView.bounds.size, image.size)
        self.quad = scaledQuad
        
        // Cropped Image
        var cartesianScaledQuad = scaledQuad.toCartesian(withHeight: image.size.height)
        cartesianScaledQuad.reorganize()
        
        let filteredImage = orientedImage.applyingFilter("CIPerspectiveCorrection", parameters: [
            "inputTopLeft": CIVector(cgPoint: cartesianScaledQuad.bottomLeft),
            "inputTopRight": CIVector(cgPoint: cartesianScaledQuad.bottomRight),
            "inputBottomLeft": CIVector(cgPoint: cartesianScaledQuad.topLeft),
            "inputBottomRight": CIVector(cgPoint: cartesianScaledQuad.topRight)
        ])
        
        let croppedImage = UIImage.from(ciImage: filteredImage)
        // Enhanced Image
        let enhancedImage = filteredImage.applyingAdaptiveThreshold()?.withFixedOrientation()
        let enhancedScan = enhancedImage.flatMap { ImageScannerScan(image: $0) }
        
        let results = ImageScannerResults(
            detectedRectangle : scaledQuad,
            originalScan      : ImageScannerScan(image: image),
            croppedScan       : ImageScannerScan(image: croppedImage),
            enhancedScan      : enhancedScan
        )
        
        let reviewViewController = ReviewViewController(results: results)
        
        navigationController?.pushViewController(
            reviewViewController,
            animated: true
        )
    }
}

/* MARK:- Collection View */

///DataSource
extension EditScanVC: UICollectionViewDataSource {
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        return datasource.count
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        
    }
}


