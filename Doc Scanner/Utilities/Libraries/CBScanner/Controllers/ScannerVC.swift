//
//  ScannerVC.swift
//  Doc Scanner
//
//  Created by M Farhan on 8/25/20.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import UIKit
import AVKit

class ScannerVC: UIViewController {
    
    /* MARK:- @IBOutlet */
    @IBOutlet weak var flashButton            : UIButton!
    @IBOutlet weak var shutterButton          : UIButton!
    @IBOutlet weak var imagesCounterView      : UIView!
    @IBOutlet weak var cameraPreviewView      : UIView!
    @IBOutlet weak var imagesCounterLabel     : UILabel!
    @IBOutlet weak var cameraGalleryIconView  : UIView!
    @IBOutlet weak var cameraGalleryImageView : UIImageView!
    @IBOutlet weak var scanTypeCollectionView : UICollectionView!
        
    /* MARK:- Properties */
    private var focusRectangle        : FocusRectangleView!
    private var originalBarStyle      : UIBarStyle?
    private var captureSessionManager : CaptureSessionManager?
    
    private let quadView          = QuadrilateralView()
    private var lastIndex         = IndexPath(row: 0, section: 0)
    private var flashEnabled      = false
    private let videoPreviewLayer = AVCaptureVideoPreviewLayer()
    
    public var datasource  : [String]    = [
        "Passport"      ,
        "ID Card"       ,
        "Batch"         ,
        "Single"        ,
//        "Image to Text"
    ]
    private var scannerType : ScannerType = .single
    private var isFirstLoad : Bool        = true
    
    /* MARK:- Batch mode only properties Start */
    private var quads       : [Quadrilateral] = []
    private var images      : [UIImage]       = []
    /* MARK:- END */
    
    /* MARK:- Batch mode only properties Start */
    public var isRetake     : Bool            = false
    public var eQuads       : [Quadrilateral] = []
    public var eImages      : [UIImage]       = []
    public var eIndex       : Int             = 0
    /* MARK:- Retake */
    
    /* MARK:- Add another Start */
    public var editFile     : DocumentsModel = DocumentsModel()
    public var isEditOrAdd  : Int            = 0 /// 0 Means new doc is being scanned
    /* MARK:- END */
    
    ///Type Layers
    var idCardLayer     = CAShapeLayer()
    var passportLayer   = CAShapeLayer()
    var dottedLineLayer = CAShapeLayer()
    
    ///Type Quads
    var idCardQuad  : Quadrilateral = Quadrilateral(
        topLeft     : CGPoint(x: 0.0, y: 0.0),
        topRight    : CGPoint(x: 0.0, y: 0.0),
        bottomRight : CGPoint(x: 0.0, y: 0.0),
        bottomLeft  : CGPoint(x: 0.0, y: 0.0)
    )
    
    var passportQuad : Quadrilateral = Quadrilateral(
        topLeft      : CGPoint(x: 0.0, y: 0.0),
        topRight     : CGPoint(x: 0.0, y: 0.0),
        bottomRight  : CGPoint(x: 0.0, y: 0.0),
        bottomLeft   : CGPoint(x: 0.0, y: 0.0)
    )
    
    /* MARK:- Lazy Properties */
    private lazy var activityIndicator: UIActivityIndicatorView = {
        if #available(iOS 13.0, *) {
            let activityIndicator = UIActivityIndicatorView(style: .medium)
            activityIndicator.hidesWhenStopped = true
            activityIndicator.translatesAutoresizingMaskIntoConstraints = false
            return activityIndicator
        } else {
            let activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
            activityIndicator.hidesWhenStopped = true
            activityIndicator.translatesAutoresizingMaskIntoConstraints = false
            return activityIndicator
        }
        
    }()
    
    private lazy var scanTypeCellNib: UINib = {
        return UINib(nibName: Constants.cellNib.SCAN_TYPE, bundle: nil)
    }()
    
    /* MARK:- Lifecycle */
    override func viewDidLoad() {
        super.viewDidLoad()
        initVC()
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.quads  = []
        self.images = []
        
        imagesCounterView.isHidden               = true 
        
        CaptureSession.current.isEditing         = false
        CaptureSession.current.isAutoScanEnabled = false
        
        quadView.removeQuadrilateral()
        captureSessionManager?.start()
        
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if isFirstLoad {
            isFirstLoad = false
            
            if datasource.count == 1 {
                lastIndex = IndexPath(row: 0, section: 0)
            } else {
                ///Setting up collection view centered
                lastIndex = IndexPath(row: 3, section: 0)
            }
            
            ///Preview view frame setup
            videoPreviewLayer.frame = cameraPreviewView.layer.bounds
            ///Setting up collection view centered
            scanTypeCollectionView.scrollToItem(
                at       : lastIndex,
                at       : .centeredHorizontally,
                animated : true
            )
            
        }
        
        setupSelectedCell()
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
        
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barStyle = originalBarStyle ?? .default
        captureSessionManager?.stop()
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else { return }
        if device.torchMode == .on {
            didTapFlash(flashButton)
        }
    }
    
    override public func touchesBegan(
        _ touches : Set<UITouch>,
        with event: UIEvent?
    ) {
        super.touchesBegan(touches, with: event)
        
        guard  let touch = touches.first, touch.view?.superview == quadView else {
            return
        }
        
        let touchPoint   = touch.location(in: view)
        let convertedTouchPoint: CGPoint = videoPreviewLayer.captureDevicePointConverted(
            fromLayerPoint: touchPoint
        )
        
        CaptureSession.current.removeFocusRectangleIfNeeded(
            focusRectangle,
            animated: false
        )
        
        focusRectangle = FocusRectangleView(touchPoint: touchPoint)
        view.addSubview(focusRectangle)
        
        do {
            try CaptureSession.current.setFocusPointToTapPoint(convertedTouchPoint)
        } catch {
            let error = ImageScannerControllerError.inputDevice
            guard let captureSessionManager = captureSessionManager else { return }
            captureSessionManager.delegate?.captureSessionManager(
                captureSessionManager,
                didFailWithError: error
            )
            return
        }
    }

    deinit {
        Helper.debugLogs(any: "Deinit Scanner VC Successful")
    }
}

/* MARK:- Methods */
extension ScannerVC {
    private func initVC() {
        ///Setting up corner radius
        MAIN_QUEUE.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self = self else { return }
            self.imagesCounterView.layer.cornerRadius = self.imagesCounterView.frame.height/2
            self.cameraGalleryIconView.layer.cornerRadius = self.cameraGalleryIconView.frame.height/2
        }
        ///Initilizing Capture session manager
        captureSessionManager = CaptureSessionManager(
            videoPreviewLayer : videoPreviewLayer,
            delegate          : self
        )
        
        ///Adding subject area change observer
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(subjectAreaDidChange),
            name    : Notification.Name.AVCaptureDeviceSubjectAreaDidChange,
            object  : nil
        )
        
        ///Adding camera preview layer
        cameraPreviewView.layer.addSublayer(videoPreviewLayer)
        
        quadView.editable                                  = false
        quadView.translatesAutoresizingMaskIntoConstraints = false
        
        ///Adding quad view and activity indicator
        cameraPreviewView.addSubview(quadView)
        cameraPreviewView.addSubview(activityIndicator)
        
        ///Adding Constraints
        setupConstraints()
        
        ///Adding Swipe Gestures
        let rightSwipeSelector = #selector(didSwipeRight(_:))
        let rightSwipeGesture  = UISwipeGestureRecognizer(
            target: self,
            action: rightSwipeSelector
        )
        
        let leftSwipeSelector = #selector(didSwipeLeft(_:))
        let leftSwipeGesture  = UISwipeGestureRecognizer(
            target: self,
            action: leftSwipeSelector
        )
        
        rightSwipeGesture.direction = .right
        leftSwipeGesture.direction  = .left
        
        scanTypeCollectionView.addGestureRecognizer(rightSwipeGesture)
        scanTypeCollectionView.addGestureRecognizer(leftSwipeGesture)
                
        registerNib()
    }
    
    private func registerNib(){
        scanTypeCollectionView.register(
            scanTypeCellNib,
            forCellWithReuseIdentifier: Constants.cellNib.SCAN_TYPE
        )
    }
    
    private func resetCells(){
        for i in 0..<datasource.count {
            let indexPath  = IndexPath(row: i, section: 0)
            if let cell = scanTypeCollectionView.cellForItem(
                at: indexPath
            ) as? ScanTypeCell {
                cell.transform           = .identity
                cell.nameLabel.textColor = #colorLiteral(red: 0.5803921569, green: 0.5803921569, blue: 0.5803921569, alpha: 1)
            }
        }
    }
    
    private func setupSelectedCell(){
        ///Resetting cell to original state
        resetCells()
        ///Batch Setup
        if lastIndex.row == 2 {
            cameraGalleryIconView.isHidden = false
        } else {
            images.removeAll()
            quads.removeAll()
            
            cameraGalleryImageView.image   = UIImage(named: "camera-gallery")
            
            imagesCounterView.isHidden     = true
            cameraGalleryIconView.isHidden = true
        }
        
        ///Setting up selected cell
        guard let cell = scanTypeCollectionView.cellForItem(
            at: lastIndex
        ) as? ScanTypeCell else {
            return
        }
        
        cell.transform           = CGAffineTransform(scaleX: 1.5, y: 1.5)
        cell.nameLabel.textColor = #colorLiteral(red: 0.03137254902, green: 0.5647058824, blue: 0.9725490196, alpha: 1)
    }
    
    private func setupConstraints() {
        var quadViewConstraints          = [NSLayoutConstraint]()
        var activityIndicatorConstraints = [NSLayoutConstraint]()
        
        quadViewConstraints = [
            quadView.topAnchor.constraint(
                equalTo: cameraPreviewView.topAnchor
            ),
            quadView.bottomAnchor.constraint(
                equalTo: cameraPreviewView.bottomAnchor
            ),
            quadView.trailingAnchor.constraint(
                equalTo: cameraPreviewView.trailingAnchor
            ),
            quadView.leadingAnchor.constraint(
                equalTo: cameraPreviewView.leadingAnchor
            )
        ]
        
        activityIndicatorConstraints = [
            activityIndicator.centerXAnchor.constraint(
                equalTo: cameraPreviewView.centerXAnchor
            ),
            activityIndicator.centerYAnchor.constraint(
                equalTo: cameraPreviewView.centerYAnchor
            )
        ]
        
        NSLayoutConstraint.activate(
            quadViewConstraints          +
            activityIndicatorConstraints
        )
    }
    
    private func drawPathOnQuadView(){
        removeAllTypeLayers()
        
        let index = lastIndex.row
        
        if index == 0 {///Passport
            passportView()
            scannerType       = .passport
            quadView.isHidden = true
        } else if index == 1 {///Id Card
            createIdCardView()
            scannerType       = .idCard
            quadView.isHidden = true
        } else if index == 2 {///Batch
            scannerType       = .batch
            quadView.isHidden = false
        } else if index == 3 {///Single
            scannerType       = .single
            quadView.isHidden = false
        } else if index == 4 {///Image To Text
            scannerType       = .imageToText
            quadView.isHidden = true
        }
    }
    
    ///Views for scanner types
    private func removeAllTypeLayers(){
        idCardLayer.removeFromSuperlayer()
        passportLayer.removeFromSuperlayer()
        dottedLineLayer.removeFromSuperlayer()
    }
    
    private func passportView(){
        let overlayPath         = UIBezierPath(rect: cameraPreviewView.bounds)
        let width               = SCREEN_WIDTH * 0.77777778
        let height              = SCREEN_HEIGHT * 0.50446429
        let transparentPathMidX = (cameraPreviewView.bounds.width/2)  - (width/2)
        let transparentPathMidY = (cameraPreviewView.bounds.height/2) - (height/2)
        
        let transparentPath = UIBezierPath(
            roundedRect:  CGRect(
                x      : transparentPathMidX,
                y      : transparentPathMidY,
                width  : width              ,
                height : height
            ),
            cornerRadius: 6.0
        )
        
        let passportFrame = transparentPath.bounds
        passportQuad      = Quadrilateral(
            topLeft     : CGPoint(x: passportFrame.minX, y: passportFrame.minY),
            topRight    : CGPoint(x: passportFrame.maxX, y: passportFrame.minY),
            bottomRight : CGPoint(x: passportFrame.maxX, y: passportFrame.maxY),
            bottomLeft  : CGPoint(x: passportFrame.minX, y: passportFrame.maxY)
        )
        
        drawDottedLine(
            start: CGPoint(
                x: transparentPath.bounds.minX,
                y: transparentPath.bounds.midY
            ),
            end  : CGPoint(
                x: transparentPath.bounds.maxX,
                y: transparentPath.bounds.midY
            ),
            view: cameraPreviewView
        )
        
        overlayPath.append(transparentPath)
        overlayPath.usesEvenOddFillRule = true

        passportLayer.path      = overlayPath.cgPath
        passportLayer.fillRule  = .evenOdd
        passportLayer.fillColor = #colorLiteral(red: 0.1803921569, green: 0.7647058824, blue: 0.9882352941, alpha: 0.5)

        cameraPreviewView.layer.addSublayer(passportLayer)
    }
    
    private func createIdCardView(){
        let overlayPath     = UIBezierPath(rect: cameraPreviewView.bounds)
        
        let width               = SCREEN_WIDTH  * 0.84541063
        let height              = SCREEN_HEIGHT * 0.27901786
        let transparentPathMidX = (cameraPreviewView.bounds.width/2)  - (width/2)
        let transparentPathMidY = (cameraPreviewView.bounds.height/2) - (height/2)
        
        let transparentPath = UIBezierPath(
            roundedRect:  CGRect(
                x      : transparentPathMidX,
                y      : transparentPathMidY,
                width  : width              ,
                height : height
            ),
            cornerRadius: 6.0
        )
        
        let cardFrame = transparentPath.bounds
        idCardQuad    = Quadrilateral(
            topLeft     : CGPoint(x: cardFrame.minX, y: cardFrame.minY),
            topRight    : CGPoint(x: cardFrame.maxX, y: cardFrame.minY),
            bottomRight : CGPoint(x: cardFrame.maxX, y: cardFrame.maxY),
            bottomLeft  : CGPoint(x: cardFrame.minX, y: cardFrame.maxY)
        )
        
        overlayPath.append(transparentPath)
        overlayPath.usesEvenOddFillRule = true

        idCardLayer.path      = overlayPath.cgPath
        idCardLayer.fillRule  = .evenOdd
        idCardLayer.fillColor = #colorLiteral(red: 0.1803921569, green: 0.7647058824, blue: 0.9882352941, alpha: 0.5)

        cameraPreviewView.layer.addSublayer(idCardLayer)
    }
    
    func drawDottedLine(start p0: CGPoint, end p1: CGPoint, view: UIView) {
        dottedLineLayer                 = CAShapeLayer()
        dottedLineLayer.lineWidth       = 2.0
        dottedLineLayer.strokeColor     = #colorLiteral(red: 0.1803921569, green: 0.7647058824, blue: 0.9882352941, alpha: 0.5)
        dottedLineLayer.lineDashPattern = [7, 3] ///7 is the length of dash,
                                            ///3 is length of the gap.
        let path = CGMutablePath()
        
        path.addLines(
            between: [
                p0,
                p1
            ]
        )
        
        dottedLineLayer.path = path
        
        cameraPreviewView.layer.addSublayer(dottedLineLayer)
    }
}

/* MARK:- objc-interface */
extension ScannerVC {
    @objc private func subjectAreaDidChange() {
        /// Reset the focus and exposure back to automatic
        do {
            try CaptureSession.current.resetFocusToAuto()
        } catch {
            let error = ImageScannerControllerError.inputDevice
            guard let captureSessionManager = captureSessionManager else { return }
            
            captureSessionManager.delegate?.captureSessionManager(
                captureSessionManager,
                didFailWithError: error
            )
            
            return
        }
        
        /// Remove the focus rectangle if one exists
        CaptureSession.current.removeFocusRectangleIfNeeded(
            focusRectangle,
            animated: true
        )
    }
    
    @objc func didSwipeRight(_ sender: UISwipeGestureRecognizer){
        if sender.direction == .right {
            if lastIndex.row > -1 {
                lastIndex = IndexPath(row: lastIndex.row - 1, section: 0)
                scanTypeCollectionView.scrollToItem(
                    at       : lastIndex            ,
                    at       : .centeredHorizontally,
                    animated : true
                )
                
                setupSelectedCell()
                drawPathOnQuadView()
            }
        }
    }
    
    @objc func didSwipeLeft(_ sender: UISwipeGestureRecognizer){
        if sender.direction == .left {
            if lastIndex.row < datasource.count {
                lastIndex = IndexPath(row: lastIndex.row + 1, section: 0)
                scanTypeCollectionView.scrollToItem(
                    at       : lastIndex            ,
                    at       : .centeredHorizontally,
                    animated : true
                )
                
                setupSelectedCell()
                drawPathOnQuadView()
            }
        }
    }
}

/* MARK:- Actions */
extension ScannerVC {
    @IBAction func didTapShutter(_ sender: UIButton) {
        (navigationController as? ImageScannerController)?.flashToBlack()
        shutterButton.isUserInteractionEnabled = false
        captureSessionManager?.capturePhoto()
    }
    
    @IBAction func didTapFlash(_ sender: UIButton) {
        let state = CaptureSession.current.toggleFlash()
        
        switch state {
        case .on:
            flashEnabled      = true
            sender.isSelected = true
        case .off:
            flashEnabled      = false
            sender.isSelected = false
        case .unknown, .unavailable:
            flashEnabled      = false
            sender.isSelected = false
        }
    }
    
    @IBAction func didTapClose(_ sender: UIButton) {
        guard let imageScannerController = navigationController as? ImageScannerController else {return}
        imageScannerController.imageScannerDelegate?.imageScannerControllerDidCancel(
            imageScannerController
        )
    }
    
    ///Batch Only
    @IBAction func didTapNext(_ sender: UIButton) {
        guard images.count > 0 else {
            return
        }
        
        let editVC = EditScanVC(
            images      : images,
            quads       : quads ,
            rotateImage : true  ,
            scannerType : scannerType
        )
        
        navigationController?.pushViewController(editVC, animated: false)
        
        shutterButton.isUserInteractionEnabled = true
    }
}

/* MARK:- Rectangle Detector */
extension ScannerVC: RectangleDetectionDelegateProtocol {
    func captureSessionManager(
        _ captureSessionManager: CaptureSessionManager,
        didFailWithError error : Error
    ) {
        activityIndicator.stopAnimating()
        shutterButton.isUserInteractionEnabled = true
        
        guard let imageScannerController = navigationController as? ImageScannerController else { return }
        
        imageScannerController.imageScannerDelegate?.imageScannerController(
            imageScannerController,
            didFailWithError: error
        )
    }
    
    func didStartCapturingPicture(
        for captureSessionManager: CaptureSessionManager
    ) {
        activityIndicator.startAnimating()
        captureSessionManager.stop()
        
        ///We've to restart the session manager for batch
        ///so that we can re-draw the quads
        if scannerType == .batch {
            captureSessionManager.start()
        }
        
        shutterButton.isUserInteractionEnabled = false
    }
    
    func captureSessionManager(
        _ captureSessionManager: CaptureSessionManager,
        didCapturePicture picture: UIImage,
        withQuad quad: Quadrilateral?
    ) { 
        activityIndicator.stopAnimating()
                
        switch scannerType {
        case .passport:
            let editVC = EditScanVC(
                image       : picture     ,
                quad        : passportQuad,
                scannerType : scannerType
            )
            navigationController?.pushViewController(
                editVC,
                animated: false
            )
        case .idCard:
            let editVC = EditScanVC(
                image       : picture   ,
                quad        : idCardQuad,
                scannerType : scannerType
            )
            navigationController?.pushViewController(
                editVC,
                animated: false
            )
        case .batch:
            self.quads.append(quad ?? EditScanVC.defaultQuad(forImage: picture))
            self.images.append(picture)
            if self.images.count > 0 {
                self.imagesCounterLabel.text    = "\(self.images.count)"
                self.imagesCounterView.isHidden = false
            }
            
            cameraGalleryImageView.image = picture
        case .single:
            
            if isRetake {
                eImages.insert(picture, at: eIndex)
                eQuads.insert(quad ?? EditScanVC.defaultQuad(forImage: picture), at: eIndex)
                
                let editVC = EditScanVC(
                    images      : eImages,
                    quads       : eQuads ,
                    rotateImage : true   ,
                    scannerType : .batch
                )
                
                navigationController?.pushViewController(
                    editVC,
                    animated: false
                )
            } else {
                let editVC = EditScanVC(
                    image       : picture   ,
                    quad        : quad      ,
                    scannerType : scannerType
                )
                
                /// Means that the user wants to add a new scan in the old doc
                /// so, We'll send the old doc data as-well.
                if isEditOrAdd == 1 {
                    editVC.editFile    = self.editFile
                    editVC.isEditOrAdd = self.isEditOrAdd
                }
                
                navigationController?.pushViewController(
                    editVC,
                    animated: false
                )
            }
    
        case .imageToText:
            break
        }
                
        shutterButton.isUserInteractionEnabled = true
    }
    
    func captureSessionManager(
        _ captureSessionManager : CaptureSessionManager,
        didDetectQuad quad      : Quadrilateral?,
        _ imageSize             : CGSize
    ) {
        guard let quad = quad else {
            quadView.removeQuadrilateral()
            return
        }
        
        let portraitImageSize = CGSize(
            width : imageSize.height,
            height: imageSize.width
        )
        
        let scaleTransform = CGAffineTransform.scaleTransform(
            forSize         : portraitImageSize,
            aspectFillInSize: quadView.bounds.size
        )
        
        let scaledImageSize = imageSize.applying(scaleTransform)
        
        let rotationTransform = CGAffineTransform(rotationAngle: CGFloat.pi / 2.0)

        let imageBounds = CGRect(
            origin: .zero,
            size: scaledImageSize
        ).applying(rotationTransform)

        let translationTransform = CGAffineTransform.translateTransform(
            fromCenterOfRect: imageBounds,
            toCenterOfRect  : quadView.bounds
        )
        
        let transforms = [scaleTransform, rotationTransform, translationTransform]
        
        let transformedQuad = quad.applyTransforms(transforms)
        
        quadView.drawQuadrilateral(quad: transformedQuad, animated: true)
    }
}


/* MARK:- Collection View */

///DataSource
extension ScannerVC: UICollectionViewDataSource {
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
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier : Constants.cellNib.SCAN_TYPE,
            for                 : indexPath
        ) as! ScanTypeCell
        
        let index = indexPath.row
        let name  = datasource[index]
        
        cell.name = name
        
        if index == 0 {
            cell.transform           = CGAffineTransform(scaleX: 1.5, y: 1.5)
            cell.nameLabel.textColor = #colorLiteral(red: 0.03137254902, green: 0.5647058824, blue: 0.9725490196, alpha: 1)
        }
        
        return cell
    }
}

///Delegate
extension ScannerVC: UICollectionViewDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        lastIndex = indexPath
        
        scanTypeCollectionView.scrollToItem(
            at       : indexPath,
            at       : .centeredHorizontally,
            animated : true
        )
        
        setupSelectedCell()
        drawPathOnQuadView()
    }
}

///Delegate FlowLayout
extension ScannerVC: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView            : UICollectionView,
        layout collectionViewLayout : UICollectionViewLayout,
        sizeForItemAt indexPath     : IndexPath
    ) -> CGSize {
        
        let index = indexPath.row
        let name  = datasource[index]
        let size  = name.size(
            withAttributes: [
                NSAttributedString.Key.font : UIFont(
                    name: "Roboto-Regular",
                    size: 10.0
                )!
            ]
        )
        
        let width  = size.width
        let height = scanTypeCollectionView.frame.height
        
        return CGSize(width: width, height: height)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        
        let width = scanTypeCollectionView.frame.width
        
        return UIEdgeInsets(top: 0.0, left: width/2, bottom: 0.0, right: width/2)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        return 40.0
    }
}
