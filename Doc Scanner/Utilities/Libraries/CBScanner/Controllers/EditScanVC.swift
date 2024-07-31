//
//  EditScanVC.swift
//  Doc Scanner
//
//  Created by M Farhan on 8/25/20.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import UIKit
import AVKit
import PDFKit

class EditScanVC: UIViewController {

    /* MARK:- @IBOutlet */
    @IBOutlet weak var filterNameView           : UIView!
    @IBOutlet weak var filterNameLabel          : UILabel!
    @IBOutlet weak var filterImageView          : UIImageView!
    @IBOutlet weak var filterCollectionView     : UICollectionView!
    @IBOutlet weak var imageSizeCollectionView  : UICollectionView!
    @IBOutlet weak var scanedImageContainerView : UIView!
    @IBOutlet weak var scanedImageCollectionView: UICollectionView!
    
    /* MARK:- Properties */
    private var quad                  : Quadrilateral
    private var oQuad                 : Quadrilateral
    private var image                 : UIImage
    private var oImage                : UIImage
    private var lastQuad              : Quadrilateral
    private let scannerType           : ScannerType
    private var zoomGestureController : ZoomGestureController!
    
    /* MARK:- Batch mode only properties Start */
    private var quads            : [Quadrilateral]       = []
    private var oQuads           : [Quadrilateral]       = []
    private var images           : [UIImage]             = []
    private var oImages          : [UIImage]             = []
    private var results          : [ImageScannerResults] = []
    private var quadViews        : [QuadrilateralView]   = []
    private var rotationAngles   : [CGFloat]             = []
    private let dispachGroup     : DispatchGroup         = DispatchGroup()
    
    private var scannedImageIndex : IndexPath = IndexPath(row: 0, section: 0) /// Index for scanned Image
    /* MARK:- END */
    
    /* MARK:- Add another Start */
    public var docVC       : DocVC?
    public var docFolderVC : DocFolderVC?
    public var pageId      : Int32          = 0
    public var editFile    : DocumentsModel = DocumentsModel()
    public var isEditOrAdd : Int            = 0 /// 0 Means new doc is being scanned
    /* MARK:- END */
    
    private var quadViewWidthConstraint  = NSLayoutConstraint()
    private var quadViewHeightConstraint = NSLayoutConstraint()
    
    private var rotationAngle : CGFloat = 0.0
    
    private var datasource: [String] = [
        "Legal"    ,
        "Original" ,
        "A4"       ,
        "A5"       ,
        "Business Card"
    ]
    
    private var shouldSetCellBorder  = true /// filterCollectionView first cell selection by default
    private var lastIndex: IndexPath = IndexPath(row: 0, section: 0) /// Index for selected page size
    private var pageSize : PageSize  = .a4
    
    /// Flag
    var isFromGallery: Bool = false
    
    ///Filter
    private var selectedFilterIndex = 0
    private var smallImage          = UIImage()
    
    /* MARK:- Lazy Properties */
    private lazy var imageView: UIImageView = {
        let imageView               = UIImageView()
        imageView.clipsToBounds     = true
        imageView.isOpaque          = true
        imageView.image             = image
        imageView.backgroundColor   = #colorLiteral(red: 0.9568627451, green: 0.9568627451, blue: 0.9725490196, alpha: 1)
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
    
    private lazy var imageTypeCellNib: UINib = {
        return UINib(nibName: Constants.cellNib.IMAGE_SIZE, bundle: nil)
    }()
    
    private lazy var filterCellNib: UINib = {
        return UINib(nibName: Constants.cellNib.FILTER, bundle: nil)
    }()
    
    private lazy var scanedImageCellNib: UINib = {
        return UINib(nibName: Constants.cellNib.EDIT_IMAGE, bundle: nil)
    }()
    
    /* MARK:- Closure */
    var didSetQuadView: ((_ index: Int, _ quadView: QuadrilateralView)->())?
    
    ///Initilizar
    init(
        image       : UIImage              ,
        quad        : Quadrilateral?       ,
        rotateImage : Bool        = true   ,
        scannerType : ScannerType = .batch
    ) {
        self.quad        = quad ?? EditScanVC.defaultQuad(forImage: image)
        self.oQuad       = quad ?? EditScanVC.defaultQuad(forImage: image)
        self.image       = rotateImage ? image.applyingPortraitOrientation() : image
        self.oImage      = image
        
        self.scannerType = scannerType
        
        self.lastQuad = Quadrilateral(
            topLeft     : CGPoint(x: 0.0, y: 0.0),
            topRight    : CGPoint(x: 0.0, y: 0.0),
            bottomRight : CGPoint(x: 0.0, y: 0.0),
            bottomLeft  : CGPoint(x: 0.0, y: 0.0)
        )
                
        super.init(nibName: nil, bundle: nil)
    }
    ///Initilizar for scanner type batch
    init(
        images      : [UIImage]           ,
        quads       : [Quadrilateral]     ,
        rotateImage : Bool        = true  ,
        scannerType : ScannerType = .batch
    ) {
        self.quad   = quads[0]
        self.oQuad  = quads[0]
        self.image  = images[0]
        self.oImage = images[0]
        
        for quad in quads {
            self.quads.append(quad)
            self.oQuads.append(quad)
        }
        
        self.scannerType = scannerType
        
        self.lastQuad = Quadrilateral(
            topLeft     : CGPoint(x: 0.0, y: 0.0),
            topRight    : CGPoint(x: 0.0, y: 0.0),
            bottomRight : CGPoint(x: 0.0, y: 0.0),
            bottomLeft  : CGPoint(x: 0.0, y: 0.0)
        )
                
        super.init(nibName: nil, bundle: nil)
        
        for image in images {
            autoreleasepool { [weak self] in
                oImages.append(image)
                let image = rotateImage ? image.applyingPortraitOrientation() : image
                self?.images.append(image)
                self?.rotationAngles.append(0.0)
                
                let quadView = QuadrilateralView(frame: .zero)
                self?.quadViews.append(quadView)
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /* MARK:- Life Cycle */
    override func viewDidLoad() {
        super.viewDidLoad()
        didSetQuadView = { [weak self] (index, quadView) in
            self?.quadViews.remove(at: index)
            self?.quadViews.insert(quadView, at: index)
        }
        
        initVC()
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        adjustQuadViewConstraints()
        displayQuad()
        
        ///Setting up collection view centered
        lastIndex = IndexPath(row: 2, section: 0)
        imageSizeCollectionView.scrollToItem(
            at       : lastIndex,
            at       : .centeredHorizontally,
            animated : true
        )
        
        setupSelectedCell()
    }
    
    deinit {
        Helper.debugLogs(any: "Deinit Edit Scan VC Successful")
    }
}

/* MARK:- Methods */
extension EditScanVC {
    private func initVC(){
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
        
        if scannerType != .batch {
            scanedImageContainerView.isHidden  = false
            scanedImageCollectionView.isHidden = true
        } else {
            scanedImageContainerView.isHidden  = true
            scanedImageCollectionView.isHidden = false
        }
        
        ///Filter image Setup
        smallImage = UIImage.resize(with: image, ratio: 0.2)
        
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
        
        imageSizeCollectionView.addGestureRecognizer(rightSwipeGesture)
        imageSizeCollectionView.addGestureRecognizer(leftSwipeGesture)
        
        ///Register collection view nibs
        registerNib()
    }
    
    private func registerNib(){
        imageSizeCollectionView.register(
            imageTypeCellNib,
            forCellWithReuseIdentifier: Constants.cellNib.IMAGE_SIZE
        )
        
        filterCollectionView.register(
            filterCellNib,
            forCellWithReuseIdentifier: Constants.cellNib.FILTER
        )
        
        scanedImageCollectionView.register(
            scanedImageCellNib,
            forCellWithReuseIdentifier: Constants.cellNib.EDIT_IMAGE
        )
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
        let imageSize = image.size
        
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
        
        switch scannerType {
        case .passport:
            quadView.drawQuadrilateral(quad: passportQuad()  , animated: true)
        case .idCard:
            quadView.drawQuadrilateral(quad: idCardQuad()    , animated: true)
        case .batch:
            quadView.drawQuadrilateral(quad: transformedQuad , animated: true)
        case .single:
            quadView.drawQuadrilateral(quad: transformedQuad , animated: true)
        case .imageToText:
            break
        }
    }
    
    private func adjustQuadViewConstraints() {
        let frame = AVMakeRect(
            aspectRatio: image.size,
            insideRect : imageView.bounds
        )
        
        quadViewWidthConstraint.constant  = frame.size.width
        quadViewHeightConstraint.constant = frame.size.height
    }
    
    private func resetCells(withType type: String = "imageSize"){
        if type == "imageSize" {
            for i in 0..<datasource.count {
                let indexPath  = IndexPath(row: i, section: 0)
                if let cell = imageSizeCollectionView.cellForItem(
                    at: indexPath
                ) as? ImageSizeCell {
                    cell.transform           = .identity
                    cell.nameLabel.textColor = #colorLiteral(red: 0.5803921569, green: 0.5803921569, blue: 0.5803921569, alpha: 1)
                }
            }
        } else {
            for i in 0..<5 {
                let indexPath  = IndexPath(row: i, section: 0)
                if let cell = filterCollectionView.cellForItem(
                    at: indexPath
                ) as? FilterCell {
                    
                    cell.isSelected = false
                    
                }
            }
        }
    }
    
    private func setupSelectedCell(){
        let index = lastIndex.row
        
        if index == 0 {///Legal
            pageSize = .legal
        } else if index == 1 {///Original
            pageSize = .original
        } else if index == 2 {///A4
            pageSize = .a4
        } else if index == 3 {///A5
            pageSize = .a5
        } else if index == 4 {///Business Card
            pageSize = .businessCard
        }
        
        ///Resetting cell to original state
        resetCells()
        ///Setting up selected cell
        guard let cell = imageSizeCollectionView.cellForItem(
            at: lastIndex
        ) as? ImageSizeCell else {
            return
        }
        
        cell.transform           = CGAffineTransform(scaleX: 1.5, y: 1.5)
        cell.nameLabel.textColor = #colorLiteral(red: 0.03137254902, green: 0.5647058824, blue: 0.9725490196, alpha: 1)
    }
    
    ///Filters
    private func applyFilterImageView() {
        let filter = Filter.all[selectedFilterIndex]
        DispatchQueue.global().async { [weak self] in
            if self?.scannerType == .batch {
                let index = self?.scannedImageIndex.row ?? 0
                self?.images[index] = CIFilterService.shared.applyFilter(
                    with    : self?.images[index] ?? UIImage(),
                    filter  : filter
                )
                DispatchQueue.main.async {
                    guard let cell = self?.scanedImageCollectionView.cellForItem(at: self?.scannedImageIndex ?? IndexPath(row: 0, section: 0)
                    ) as? EditImageCell else {
                        return
                    }
                    
                    cell.imageView.image        = self?.images[index]
                    self?.filterNameLabel.text  = "  \(filter.name)  "
                }
            } else {
                self?.image = CIFilterService.shared.applyFilter(
                    with    : self?.image ?? UIImage(),
                    filter  : filter
                )
                
                DispatchQueue.main.async {
                    self?.imageView.image       = self?.image
                    self?.filterNameLabel.text  = "  \(filter.name)  "
                }
            }
        }
    }
    
    ///Quad Creation
    private func idCardQuad() -> Quadrilateral {
        let width  = SCREEN_WIDTH  * 0.84541063
        let height = SCREEN_HEIGHT * 0.27901786
        let midX   = (quadView.frame.width/2)  - (width/2)
        let midY   = (quadView.frame.height/2) - (height/2)
        
        let cardFrame = CGRect(
            x      : midX ,
            y      : midY ,
            width  : width,
            height : height
        )
        
        let quad = Quadrilateral(
            topLeft     : CGPoint(x: cardFrame.minX, y: cardFrame.minY),
            topRight    : CGPoint(x: cardFrame.maxX, y: cardFrame.minY),
            bottomRight : CGPoint(x: cardFrame.maxX, y: cardFrame.maxY),
            bottomLeft  : CGPoint(x: cardFrame.minX, y: cardFrame.maxY)
        )
        
        return quad
    }
    
    private func passportQuad() -> Quadrilateral {
        let width  = SCREEN_WIDTH * 0.77777778
        let height = SCREEN_HEIGHT * 0.50446429
        let midX   = (quadView.frame.width/2)  - (width/2)
        let midY   = (quadView.frame.height/2) - (height/2)
        
        let cardFrame = CGRect(
            x      : midX ,
            y      : midY ,
            width  : width,
            height : height
        )
        
        let quad = Quadrilateral(
            topLeft     : CGPoint(x: cardFrame.minX, y: cardFrame.minY),
            topRight    : CGPoint(x: cardFrame.maxX, y: cardFrame.minY),
            bottomRight : CGPoint(x: cardFrame.maxX, y: cardFrame.maxY),
            bottomLeft  : CGPoint(x: cardFrame.minX, y: cardFrame.maxY)
        )
        
        return quad
    }
    
    public static func defaultQuad(forImage image: UIImage) -> Quadrilateral {
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
    
    ///Done Methods
    
    /// SINGLE SCANS i.e. Passport, ID Card, Single and Image To Text
    func singleScanDone(){
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
        let orientedImage = ciImage.oriented(
            forExifOrientation: Int32(cgOrientation.rawValue)
        )
        
        let scaledQuad = quad.scale(quadView.bounds.size, image.size)
        self.quad  = scaledQuad
        
        // Cropped Image
        var cartesianScaledQuad = scaledQuad.toCartesian(
            withHeight: image.size.height
        )
        cartesianScaledQuad.reorganize()
        
        let filteredImage = orientedImage.applyingFilter(
            "CIPerspectiveCorrection",
            parameters: [
                "inputTopLeft"    : CIVector(cgPoint: cartesianScaledQuad.bottomLeft ),
                "inputTopRight"   : CIVector(cgPoint: cartesianScaledQuad.bottomRight),
                "inputBottomLeft" : CIVector(cgPoint: cartesianScaledQuad.topLeft    ),
                "inputBottomRight": CIVector(cgPoint: cartesianScaledQuad.topRight   )
            ]
        )
        
        let croppedImage = UIImage.from(ciImage: filteredImage)
        // Enhanced Image
        let enhancedImage = filteredImage.applyingAdaptiveThreshold()?.withFixedOrientation()
        let enhancedScan = enhancedImage.flatMap { ImageScannerScan(image: $0) }
        
        let result = ImageScannerResults(
            detectedRectangle : scaledQuad,
            originalScan      : ImageScannerScan(image: image),
            croppedScan       : ImageScannerScan(image: croppedImage),
            enhancedScan      : enhancedScan
        )
        
        if isEditOrAdd == 1 { /// When the user want to add a new scan to old doc.
            addPDFPage(
                result       : result        ,
                PageSize     : pageSize      ,
                ScannerType  : scannerType   ,
                RotatedAngle : rotationAngle ,
                andQuad      : oQuad
            )
        } else if isEditOrAdd == 2 { /// When the user want to edit an old page from doc.
            updatePDFPage(
                result       : result        ,
                PageSize     : pageSize      ,
                ScannerType  : scannerType   ,
                RotatedAngle : rotationAngle ,
                andQuad      : oQuad
            )
        } else {
            createPDFPage(
                result       : result        ,
                PageSize     : pageSize      ,
                ScannerType  : scannerType   ,
                RotatedAngle : rotationAngle ,
                andQuad      : oQuad
            )
        }
    }
    
    /// Create single page document
    /// - Parameters:
    ///   - results: Cropped and enhanced images
    ///   - size: Size of the page
    ///   - scannerType: Type of scanning we're using
    ///   - rotatedAngle: Rotation angle of images
    ///   - quad: Quad of the images
    func createPDFPage(
        result: ImageScannerResults,
        PageSize size: PageSize,
        ScannerType scannerType: ScannerType,
        RotatedAngle rotatedAngle: CGFloat,
        andQuad quad: Quadrilateral
    ){
        let angle = Measurement<UnitAngle>(
            value: Double(rotatedAngle),
            unit: .degrees
        )
        
        if let image  = result.croppedScan.image.rotated(by: angle),
           let oImage = result.originalScan.image.rotated(by: angle) {
            
            let page             = PDFPage()
            var bounds           = page.bounds(for: .mediaBox)
            var widthMultiplier  = CGFloat(0.0)
            var heightMultiplier = CGFloat(0.0)
            
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
                
                guard let width  = image.cgImage?.width  else { return }
                guard let height = image.cgImage?.height else { return }
                
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
                guard let originalWidth  = image.cgImage?.width  else { return }
                guard let originalHeight = image.cgImage?.height else { return }
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
                ///Saving Document
                if let documentId = CBFileManager.sharedInstance.nextId(
                    "id",
                    forEntityName: DOCUMENTS
                ) as? Int32 {
                    var entries : [String: Any] = [:]
                    entries["id"]               = documentId
                    entries["type"]             = DataType.file.rawValue
                    entries["name"]             = "PDF - \(documentId)"
                    entries["folder_id"]        = Int32(0)
                    entries["password"]         = ""
                    entries["created_at"]       = Date()
                    
                    CBFileManager.sharedInstance.createData(
                        withEntries : entries,
                        forEntity   : DOCUMENTS
                    ) { [weak self] (isFinished) in
                        guard let self = self else { return }
                        
                        if isFinished {
                            ///Saving Page
                            if let pageId = CBFileManager.sharedInstance.nextId(
                                "id",
                                forEntityName: PAGES
                            ) as? Int32 {
                                var entries : [String: Any] = [:]
                                entries["id"]               = pageId
                                entries["file_id"]          = documentId
                                entries["cropped_image"]    = image.jpegData(compressionQuality: 1.0)
                                entries["original_image"]   = oImage.jpegData(compressionQuality: 1.0)
                                entries["enhanced_image"]   = pageData
                                entries["page_size"]        = self.pageSize.rawValue
                                entries["scanner_type"]     = scannerType.rawValue
                                
                                CBFileManager.sharedInstance.createData(
                                    withEntries : entries,
                                    forEntity   : PAGES
                                ) { (isFinished) in
                                    
                                    if isFinished {
                                        ///Saving Quads
                                        if let quadId = CBFileManager.sharedInstance.nextId(
                                            "id",
                                            forEntityName: QUADS
                                        ) as? Int32 {
                                            var entries : [String: Any] = [:]
                                            entries["id"]               = quadId
                                            entries["page_id"]          = pageId
                                            entries["top_left_x"]       = quad.topLeft.x
                                            entries["top_left_y"]       = quad.topLeft.y
                                            entries["top_right_x"]      = quad.topRight.x
                                            entries["top_right_y"]      = quad.topRight.y
                                            entries["bottom_left_x"]    = quad.bottomLeft.x
                                            entries["bottom_left_y"]    = quad.bottomLeft.y
                                            entries["bottom_right_x"]   = quad.bottomRight.x
                                            entries["bottom_right_y"]   = quad.bottomRight.y
                                            
                                            CBFileManager.sharedInstance.createData(
                                                withEntries : entries,
                                                forEntity   : QUADS
                                            ) { (isFinished) in
                                                ///Dismissing View
                                                if let imageScannerController = self.navigationController as? ImageScannerController {
                                                    imageScannerController.imageScannerDelegate?.imageScannerControllerShouldOpenDoc(imageScannerController)
                                                } else {
                                                    if self.isFromGallery {
                                                        Helper.popToViewController(ofKind: BaseVC.self)
                                                    } else {
                                                        Helper.popToViewController(ofKind: DocVC.self)
                                                    }
                                                }
                                                
                                            }
                                            
                                        }
                                    }
                                    
                                }
                                
                            }
                        }
                        
                    }
                }
            }
            
        }
    }
    
    /// Add a new page in the already created document
    /// - Parameters:
    ///   - results: Cropped and enhanced images
    ///   - size: Size of the page
    ///   - scannerType: Type of scanning we're using
    ///   - rotatedAngle: Rotation angle of images
    ///   - quad: Quad of the images
    func addPDFPage(
        result: ImageScannerResults,
        PageSize size: PageSize,
        ScannerType scannerType: ScannerType,
        RotatedAngle rotatedAngle: CGFloat,
        andQuad quad: Quadrilateral
    ){
        let angle = Measurement<UnitAngle>(
            value: Double(rotatedAngle),
            unit: .degrees
        )
        
        if let image  = result.croppedScan.image.rotated(by: angle),
           let oImage = result.originalScan.image.rotated(by: angle) {
            
            let page             = PDFPage()
            var bounds           = page.bounds(for: .mediaBox)
            var widthMultiplier  = CGFloat(0.0)
            var heightMultiplier = CGFloat(0.0)
            
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
                
                guard let width  = image.cgImage?.width  else { return }
                guard let height = image.cgImage?.height else { return }
                
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
                guard let originalWidth  = image.cgImage?.width  else { return }
                guard let originalHeight = image.cgImage?.height else { return }
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
                ///Adding Page
                if let pageId = CBFileManager.sharedInstance.nextId(
                    "id",
                    forEntityName: PAGES
                ) as? Int32 {
                    var entries : [String: Any] = [:]
                    entries["id"]               = pageId
                    entries["file_id"]          = editFile.id
                    entries["cropped_image"]    = image.jpegData(compressionQuality: 1.0)
                    entries["original_image"]   = oImage.jpegData(compressionQuality: 1.0)
                    entries["enhanced_image"]   = pageData
                    entries["page_size"]        = pageSize.rawValue
                    entries["scanner_type"]     = scannerType.rawValue
                    
                    CBFileManager.sharedInstance.createData(
                        withEntries : entries,
                        forEntity   : PAGES
                    ) { (isFinished) in
                        
                        if isFinished {
                            ///Saving Quads
                            if let quadId = CBFileManager.sharedInstance.nextId(
                                "id",
                                forEntityName: QUADS
                            ) as? Int32 {
                                var entries : [String: Any] = [:]
                                entries["id"]               = quadId
                                entries["page_id"]          = pageId
                                entries["top_left_x"]       = quad.topLeft.x
                                entries["top_left_y"]       = quad.topLeft.y
                                entries["top_right_x"]      = quad.topRight.x
                                entries["top_right_y"]      = quad.topRight.y
                                entries["bottom_left_x"]    = quad.bottomLeft.x
                                entries["bottom_left_y"]    = quad.bottomLeft.y
                                entries["bottom_right_x"]   = quad.bottomRight.x
                                entries["bottom_right_y"]   = quad.bottomRight.y
                                
                                CBFileManager.sharedInstance.createData(
                                    withEntries : entries,
                                    forEntity   : QUADS
                                ) { (isFinished) in
                                    ///Dismissing View
                                    if let imageScannerController = self.navigationController as? ImageScannerController {
                                        imageScannerController.imageScannerDelegate?.imageScannerControllerShouldOpenDoc(imageScannerController)
                                    }
                                    
                                }
                                
                            }
                        }
                        
                    }
                    
                }
            }
            
        }
    }
    
    /// Update page in document
    /// - Parameters:
    ///   - results: Cropped and enhanced images
    ///   - size: Size of the page
    ///   - scannerType: Type of scanning we're using
    ///   - rotatedAngle: Rotation angle of images
    ///   - quad: Quad of the images
    func updatePDFPage(
        result: ImageScannerResults,
        PageSize size: PageSize,
        ScannerType scannerType: ScannerType,
        RotatedAngle rotatedAngle: CGFloat,
        andQuad quad: Quadrilateral
    ){
        
        let angle = Measurement<UnitAngle>(
            value: Double(rotatedAngle),
            unit: .degrees
        )
        
        if let image  = result.croppedScan.image.rotated(by: angle) {
            
            let page             = PDFPage()
            var bounds           = page.bounds(for: .mediaBox)
            var widthMultiplier  = CGFloat(0.0)
            var heightMultiplier = CGFloat(0.0)
            
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
                
                guard let width  = image.cgImage?.width  else { return }
                guard let height = image.cgImage?.height else { return }
                
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
                guard let originalWidth  = image.cgImage?.width  else { return }
                guard let originalHeight = image.cgImage?.height else { return }
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
                ///Adding Page
                var entries : [String: Any] = [:]
                entries["cropped_image"]    = image.jpegData(compressionQuality: 1.0)
                entries["enhanced_image"]   = pageData
                
                CBFileManager.sharedInstance.upateData(
                    withId: pageId,
                    forEntity: PAGES,
                    withEntries: entries
                ) { [weak self] (isCompleted) in
                    guard let self = self else { return }
                    
                    if isCompleted {
                        ///Dismissing View
                        self.navigationController?.popViewController(animated: true, completion: { [weak self] in
                            guard let self = self else { return }
                            if let docVC = self.docVC {
                                docVC.shouldUpdatePage()
                            } else if let docFolderVC = self.docFolderVC {
                                docFolderVC.navigationController?.popViewController(animated: true)
                            }
                        })
                    }
                }
            }
            
        }
    }
    
    /// MULTIPLE SCANS i.e. Batch
    func batchScanDone(){
        results.removeAll()
        var croppedImages: [UIImage] = []
        
        for (row,image) in images.enumerated() {
            autoreleasepool { [weak self] in
                guard let self = self else { return }
                Helper.debugLogs(any: row, and: "Index")
                var q: Quadrilateral?
                dispachGroup.enter()
                if let quadViewQuad = self.quadViews[row].quad {
                    q = quadViewQuad
                    dispachGroup.leave()
                } else {
                    self.quad  = quads[row]
                    self.image = image
                    
                    quadView.removeQuadrilateral()
                    displayQuad()
                    
                    q = quadView.quad
                    
                    self.quadViews.remove(at: row)
                    self.quadViews.insert(quadView, at: row)
                    dispachGroup.leave()
                }
                
                dispachGroup.wait()
                guard let quad  = q,
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
                let orientedImage = ciImage.oriented(
                    forExifOrientation: Int32(cgOrientation.rawValue)
                )
                
                let scaledQuad = quad.scale(self.quadViews[row].bounds.size, image.size)
                self.quadViews[row].quad = scaledQuad
                
                // Cropped Image
                var cartesianScaledQuad = scaledQuad.toCartesian(
                    withHeight: image.size.height
                )
                cartesianScaledQuad.reorganize()
                
                let filteredImage = orientedImage.applyingFilter(
                    "CIPerspectiveCorrection",
                    parameters: [
                        "inputTopLeft"    : CIVector(cgPoint: cartesianScaledQuad.bottomLeft ),
                        "inputTopRight"   : CIVector(cgPoint: cartesianScaledQuad.bottomRight),
                        "inputBottomLeft" : CIVector(cgPoint: cartesianScaledQuad.topLeft    ),
                        "inputBottomRight": CIVector(cgPoint: cartesianScaledQuad.topRight   )
                    ]
                )
                
                let croppedImage = UIImage.from(ciImage: filteredImage)
                
                croppedImages.append(croppedImage)
                // Enhanced Image
                let enhancedImage = filteredImage.applyingAdaptiveThreshold()?.withFixedOrientation()
                let enhancedScan = enhancedImage.flatMap { ImageScannerScan(image: $0) }
                
                let result = ImageScannerResults(
                    detectedRectangle : scaledQuad,
                    originalScan      : ImageScannerScan(image: image),
                    croppedScan       : ImageScannerScan(image: croppedImage),
                    enhancedScan      : enhancedScan
                )
                
                results.append(result)
            }
        }
        
        createPDFPages(
            results       : results        ,
            PageSize      : pageSize       ,
            ScannerType   : scannerType    ,
            RotatedAngle  : rotationAngles ,
            andQuad       : oQuads
        )
        
    }
    
    /// Method to generate multiple pages document
    /// - Parameters:
    ///   - results: Cropped and enhanced images
    ///   - size: Size of the page
    ///   - scannerType: Type of scanning we're using
    ///   - rotatedAngle: Rotation angle of images
    ///   - quad: Quad of the images
    func createPDFPages(
        results: [ImageScannerResults],
        PageSize size: PageSize,
        ScannerType scannerType: ScannerType,
        RotatedAngle rotatedAngle: [CGFloat],
        andQuad quad: [Quadrilateral]
    ){
        ///Saving Document
        if let documentId = CBFileManager.sharedInstance.nextId(
            "id",
            forEntityName: DOCUMENTS
        ) as? Int32 {
            var entries : [String: Any] = [:]
            entries["id"]               = documentId
            entries["type"]             = DataType.file.rawValue
            entries["name"]             = "PDF - \(documentId)"
            entries["folder_id"]        = Int32(0)
            entries["password"]         = ""
            entries["created_at"]       = Date()
            
            CBFileManager.sharedInstance.createData(
                withEntries : entries,
                forEntity   : DOCUMENTS
            ) { [weak self] (isFinished) in
                guard let self = self else { return }
                
                if isFinished {
                    for (i,r) in results.enumerated() {
                        autoreleasepool {
                            let rAngle = Measurement<UnitAngle>(
                                value: Double(rotatedAngle[i]),
                                unit : .degrees
                            )
                            
                            if let image  = r.croppedScan.image.rotated(by: rAngle),
                               let oImage = r.originalScan.image.rotated(by: rAngle) {
                                
                                let page             = PDFPage()
                                var bounds           = page.bounds(for: .mediaBox)
                                var widthMultiplier  = CGFloat(0.0)
                                var heightMultiplier = CGFloat(0.0)
                                
                                switch scannerType {
                                case .passport, .idCard:
                                    widthMultiplier  = 0.5
                                    heightMultiplier = 0.5
                                case .batch, .single, .imageToText:
                                    widthMultiplier  = 1.0
                                    heightMultiplier = 1.0
                                }
                                
                                switch size {///Sizes At 300 PPI
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
                                    
                                    guard let width  = image.cgImage?.width  else { return }
                                    guard let height = image.cgImage?.height else { return }
                                    
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
                                    guard let originalWidth  = image.cgImage?.width  else { return }
                                    guard let originalHeight = image.cgImage?.height else { return }
                                    ///Getting multiplier
                                    var multiplier = CGFloat(0.0)
                                    
                                    ///If user has scanned a card and set the page size to business card
                                    ///then it should be stretch to fit the page
                                    if scannerType == .idCard && size == .businessCard {
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
                                    
                                    ///Saving Page
                                    if let pageId = CBFileManager.sharedInstance.nextId(
                                        "id",
                                        forEntityName: PAGES
                                    ) as? Int32 {
                                        var entries : [String: Any] = [:]
                                        entries["id"]               = pageId
                                        entries["file_id"]          = documentId
                                        entries["cropped_image"]    = image.jpegData(compressionQuality: 1.0)
                                        entries["original_image"]   = oImage.jpegData(compressionQuality: 1.0)
                                        entries["enhanced_image"]   = pageData
                                        entries["page_size"]        = self.pageSize.rawValue
                                        entries["scanner_type"]     = scannerType.rawValue
                                        
                                        CBFileManager.sharedInstance.createData(
                                            withEntries : entries,
                                            forEntity   : PAGES
                                        ) { (isFinished) in
                                            
                                            if isFinished {
                                                ///Saving Quads
                                                if let quadId = CBFileManager.sharedInstance.nextId(
                                                    "id",
                                                    forEntityName: QUADS
                                                ) as? Int32 {
                                                    var entries : [String: Any] = [:]
                                                    entries["id"]             = quadId
                                                    entries["page_id"]        = pageId
                                                    entries["top_left_x"]     = quad[i].topLeft.x
                                                    entries["top_left_y"]     = quad[i].topLeft.y
                                                    entries["top_right_x"]    = quad[i].topRight.x
                                                    entries["top_right_y"]    = quad[i].topRight.y
                                                    entries["bottom_left_x"]  = quad[i].bottomLeft.x
                                                    entries["bottom_left_y"]  = quad[i].bottomLeft.y
                                                    entries["bottom_right_x"] = quad[i].bottomRight.x
                                                    entries["bottom_right_y"] = quad[i].bottomRight.y
                                                    
                                                    CBFileManager.sharedInstance.createData(
                                                        withEntries : entries,
                                                        forEntity   : QUADS
                                                    ) { [weak self] (isFinished) in
                                                        guard let self = self else {return}
                                                        ///Dismissing View
                                                        if i == results.count - 1 {
                                                            self.removeSpinner()
                                                            if let imageScannerController = self.navigationController as? ImageScannerController {
                                                                imageScannerController.imageScannerDelegate?.imageScannerControllerShouldOpenDoc(imageScannerController)
                                                            } else {
                                                                if self.isFromGallery {
                                                                    Helper.popToViewController(ofKind: BaseVC.self)
                                                                } else {
                                                                    Helper.popToViewController(ofKind: DocVC.self)
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
}

/* MARK:- Actions */
extension EditScanVC {
    ///Top Bar Actions
    @IBAction func didTapBack(_ sender: UIButton) {
        navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func didTapRetake(_ sender: UIButton) {
        if scannerType != .batch {
            navigationController?.popViewController(animated: true)
        } else {
            let index = scannedImageIndex.row
            
            if self.oImages.indices.contains(index) {
                self.oImages.remove(at: index)
            }
            
            if self.oQuads.indices.contains(index) {
                self.oQuads.remove(at: index)
            }
            
            let scannerVC        = ScannerVC()
            scannerVC.datasource = ["Single"]
            scannerVC.eIndex     = index
            scannerVC.eImages    = self.oImages
            scannerVC.eQuads     = self.quads
            scannerVC.isRetake   = true
            
            scannerVC.modalPresentationStyle = .fullScreen
            
            self.navigationController?.pushViewController(scannerVC, animated: true)
        }
    }
    
    @IBAction func filterToggle(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        
        if sender.isSelected {
            filterNameView.isHidden          = false
            filterCollectionView.isHidden    = false
            imageSizeCollectionView.isHidden = true
            
            filterImageView.image = UIImage(named: "edit-color-selected")
        } else {
            filterNameView.isHidden          = true
            filterCollectionView.isHidden    = true
            imageSizeCollectionView.isHidden = false
            
            filterImageView.image = UIImage(named: "edit-color")
        }
    }
    
    ///Bottom Bar Actions
    @IBAction func didTapDelete(_ sender: UIButton) {
        if scannerType != .batch {
            navigationController?.popViewController(animated: true)
        } else {
            let index = scannedImageIndex.row
            
            if self.images.indices.contains(index) {
                self.images.remove(at: index)
            }
            
            if self.quadViews.indices.contains(index) {
                self.quadViews.remove(at: index)
            }
            
            if self.rotationAngles.indices.contains(index){
                self.rotationAngles.remove(at: index)
            }
            
            if self.images.count > 0 {
                self.scanedImageCollectionView.reloadData()
            } else {
                navigationController?.popViewController(animated: true)
            }
        }
    }
    
    @IBAction func didTapDone(_ sender: UIButton) {
        sender.isEnabled = false
        showSpinner(onView: sender, bgColor: .clear)
        if scannerType == .batch {
            let indexPath = IndexPath(row: images.count - 1, section: 0)
            scanedImageCollectionView.scrollToItem(at: indexPath, at: .right, animated: true)
            MAIN_QUEUE.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self = self else { return }
                self.batchScanDone()
            }
        } else {
            singleScanDone()
        }
    }
    
    @IBAction func didTapRotate(_ sender: UIButton) {
        rotationAngle += 90
        
        if rotationAngle == 360 {
            rotationAngle = 0
        }

        var transform = CGAffineTransform.identity
        
        if rotationAngle == 90 || rotationAngle == 270 {
            var frame      = CGRect(x: 0.0, y: 0.0, width: 0.0, height: 0.0)
            
            if scannerType == .batch {
                frame = scanedImageCollectionView.frame
            } else {
                frame = scanedImageContainerView.frame
            }
            
            let scaleX     = frame.width/frame.height
            let multiplier = frame.height/frame.width
            let scaleY     = scaleX / multiplier
            
            transform = CGAffineTransform(
                scaleX: scaleX,
                y     : scaleY
            ).rotated(by: Helper.deg2rad(rotationAngle))
        } else {
            transform = CGAffineTransform(
                scaleX: 1,
                y     : 1
            ).rotated(by: Helper.deg2rad(rotationAngle))
        }
        
        UIView.animate(withDuration: 0.5) { [weak self] in
            guard let self = self else { return }
            if self.scannerType == .batch {
                guard let cell = self.scanedImageCollectionView.cellForItem(at: self.scannedImageIndex
                ) as? EditImageCell else {
                    return
                }
                
                cell.scanedImageContainerView.transform = transform
                
                let index = self.scannedImageIndex.row
                self.rotationAngles.remove(at: index)
                self.rotationAngles.insert(self.rotationAngle, at: index)
            } else {
                self.scanedImageContainerView.transform = transform
            }
        }
    }
    
    @IBAction func toggleFullScreenQuadView(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        
        if sender.isSelected {
            if scannerType == .batch {
                guard let cell = scanedImageCollectionView.cellForItem(
                    at: scannedImageIndex
                ) as? EditImageCell else {
                    return
                }
                
                cell.lastQuad = Quadrilateral(
                    topLeft     : cell.quad!.topLeft    ,
                    topRight    : cell.quad!.topRight   ,
                    bottomRight : cell.quad!.bottomRight,
                    bottomLeft  : cell.quad!.bottomLeft
                )
                
                cell.quad = Quadrilateral(
                    topLeft    : CGPoint(
                        x: cell.quadView.bounds.minX,
                        y: cell.quadView.bounds.minY
                    ),
                    topRight   : CGPoint(
                        x: cell.quadView.bounds.maxX,
                        y: cell.quadView.bounds.minY
                    ),
                    bottomRight: CGPoint(
                        x: cell.quadView.bounds.maxX,
                        y: cell.quadView.bounds.maxY
                    ),
                    bottomLeft : CGPoint(
                        x: cell.quadView.bounds.minX,
                        y: cell.quadView.bounds.maxY
                    )
                )
                
                cell.quadView.drawQuadrilateral(quad: cell.quad!, animated: true)
            } else {
                lastQuad = Quadrilateral(
                    topLeft     : quad.topLeft    ,
                    topRight    : quad.topRight   ,
                    bottomRight : quad.bottomRight,
                    bottomLeft  : quad.bottomLeft
                )
                
                quad = Quadrilateral(
                    topLeft    : CGPoint(
                        x: quadView.bounds.minX,
                        y: quadView.bounds.minY
                    ),
                    topRight   : CGPoint(
                        x: quadView.bounds.maxX,
                        y: quadView.bounds.minY
                    ),
                    bottomRight: CGPoint(
                        x: quadView.bounds.maxX,
                        y: quadView.bounds.maxY
                    ),
                    bottomLeft : CGPoint(
                        x: quadView.bounds.minX,
                        y: quadView.bounds.maxY
                    )
                )
                
                quadView.drawQuadrilateral(quad: quad, animated: true)
            }
        } else {
            if scannerType == .batch {
                guard let cell = scanedImageCollectionView.cellForItem(
                    at: scannedImageIndex
                ) as? EditImageCell else {
                    return
                }
                
                cell.quad = Quadrilateral(
                    topLeft     : cell.lastQuad.topLeft    ,
                    topRight    : cell.lastQuad.topRight   ,
                    bottomRight : cell.lastQuad.bottomRight,
                    bottomLeft  : cell.lastQuad.bottomLeft
                )
                
                cell.quadView.removeQuadrilateral()
                cell.displayQuad()
            } else {
                quad = Quadrilateral(
                    topLeft     : lastQuad.topLeft    ,
                    topRight    : lastQuad.topRight   ,
                    bottomRight : lastQuad.bottomRight,
                    bottomLeft  : lastQuad.bottomLeft
                )
                
                quadView.removeQuadrilateral()
                displayQuad()
            }
        }
    }
}

/* MARK:- objc-interface */
extension EditScanVC {
    @objc func didSwipeRight(_ sender: UISwipeGestureRecognizer){
        if sender.direction == .right {
            if lastIndex.row > -1 {
                lastIndex = IndexPath(row: lastIndex.row - 1, section: 0)
                imageSizeCollectionView.scrollToItem(
                    at       : lastIndex            ,
                    at       : .centeredHorizontally,
                    animated : true
                )
                
                setupSelectedCell()
            }
        }
    }
    
    @objc func didSwipeLeft(_ sender: UISwipeGestureRecognizer){
        if sender.direction == .left {
            if lastIndex.row < datasource.count {
                lastIndex = IndexPath(row: lastIndex.row + 1, section: 0)
                imageSizeCollectionView.scrollToItem(
                    at       : lastIndex            ,
                    at       : .centeredHorizontally,
                    animated : true
                )
                
                setupSelectedCell()
            }
        }
    }
}

/* MARK:- Collection View */

///DataSource
extension EditScanVC: UICollectionViewDataSource {
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        if collectionView == imageSizeCollectionView {
            return datasource.count
        } else if collectionView == scanedImageCollectionView {
            return images.count
        } else {
            return Filter.all.count
        }
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        
        if collectionView == imageSizeCollectionView {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier : Constants.cellNib.IMAGE_SIZE,
                for                 : indexPath
            ) as! ImageSizeCell
            
            let index = indexPath.row
            let name  = datasource[index]
            
            cell.name = name
            
            if index == 0 {
                cell.transform           = CGAffineTransform(scaleX: 1.5, y: 1.5)
                cell.nameLabel.textColor = #colorLiteral(red: 0.03137254902, green: 0.5647058824, blue: 0.9725490196, alpha: 1)
            }
            
            return cell
        } else if collectionView == scanedImageCollectionView {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier : Constants.cellNib.EDIT_IMAGE,
                for                 : indexPath
            ) as! EditImageCell
            
            let index = indexPath.row
            let quad  = quads[index]
            let image = images[index]
            
            cell.refrenceVC = self
            cell.index      = index
            cell.quad       = quad
            cell.image      = image
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier : Constants.cellNib.FILTER,
                for                 : indexPath
            ) as! FilterCell
            
            let index  = indexPath.row
            let filter = Filter.all[index]
            
            if index == 0 && shouldSetCellBorder {
                cell.isSelected     = true
                shouldSetCellBorder = false
            }
            
            DispatchQueue.global().async { [weak self, weak cell] in
                var filteredImage = self?.smallImage
                filteredImage     = CIFilterService.shared.applyFilter(
                    with  : filteredImage!,
                    filter: filter
                )
                
                DispatchQueue.main.async {
                    cell?.image = filteredImage
                }
            }
            
            return cell
        }
    }
}

///Delegate
extension EditScanVC: UICollectionViewDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        if collectionView == imageSizeCollectionView {
            lastIndex = indexPath
            
            imageSizeCollectionView.scrollToItem(
                at       : indexPath,
                at       : .centeredHorizontally,
                animated : true
            )
            
            setupSelectedCell()
        } else if collectionView == filterCollectionView {
            selectedFilterIndex = indexPath.row
            
            resetCells(withType: "filter")
            
            guard let cell = collectionView.cellForItem(
                at: indexPath
            ) as? FilterCell else {
                return
            }
            
            cell.isSelected = true
            applyFilterImageView()
        }
    }
}

///Delegate FlowLayout
extension EditScanVC: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView            : UICollectionView,
        layout collectionViewLayout : UICollectionViewLayout,
        sizeForItemAt indexPath     : IndexPath
    ) -> CGSize {
        
        if collectionView == imageSizeCollectionView {
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
            let height = imageSizeCollectionView.frame.height
            
            return CGSize(width: width, height: height)
        } else if collectionView == scanedImageCollectionView {
            
            return scanedImageCollectionView.frame.size
            
        } else {
            let height = filterCollectionView.frame.height
            let width  = height
            
            return CGSize(width: width, height: height)
        } 
    }
    
    func collectionView(
        _ collectionView            : UICollectionView,
        layout collectionViewLayout : UICollectionViewLayout,
        insetForSectionAt section   : Int
    ) -> UIEdgeInsets {
        
        if collectionView == scanedImageCollectionView {
            return UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
        } else {
            let width = imageSizeCollectionView.frame.width
            
            return UIEdgeInsets(top: 0.0, left: width/2, bottom: 0.0, right: width/2)
        }
        
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        
        if collectionView == imageSizeCollectionView {
            return 40.0
        } else if collectionView == scanedImageCollectionView {
            return 0.0
        } else {
            return 0.0
        }
        
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        
        if collectionView == filterCollectionView {
            return 5.0
        } else if collectionView == scanedImageCollectionView {
            return 0.0
        } else {
            return 0.0
        }
        
    }
}

///Scroll Delegate
extension EditScanVC: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView == scanedImageCollectionView {
            let row = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)
            scannedImageIndex = IndexPath(row: row, section: 0)
            rotationAngle    = rotationAngles[row]
        }
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        if scrollView == scanedImageCollectionView {
            let row = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)
            let indexPath = IndexPath(row: row, section: 0)
            
            guard let cell = scanedImageCollectionView.cellForItem(
                at: indexPath
            ) as? EditImageCell else {
                return
            }
            
            quadViews.remove(at: row)
            quadViews.insert(cell.quadView, at: row)
            
            Helper.debugLogs(any: "Quad Inserted", and: "\(row)")
        }
    }
}

/* MARK:- Scanner */

///Delegate
extension EditScanVC: ImageScannerControllerDelegate {
    func imageScannerControllerShouldOpenDoc(_ scanner: ImageScannerController) {
        scanner.dismiss(animated: true) {
            /// TODO :- Open DocVC
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
