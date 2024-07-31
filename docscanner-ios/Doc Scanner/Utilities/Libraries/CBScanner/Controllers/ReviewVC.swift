//
//  ReviewVC.swift
//  Doc Scanner
//
//  Created by M Farhan on 8/29/20.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import UIKit
import PDFKit

class ReviewVC: UIViewController {

    /* MARK:- IBOutlets */
    @IBOutlet weak var scannedImageContainerView: UIView!
    
    /* MARK:- Properties */
    private var angle         : CGFloat
    private let result        : ImageScannerResults
    private let pageSize      : PageSize
    private let scannerType   : ScannerType
    private var rotatedAngle  = Measurement<UnitAngle>(value: 0, unit: .degrees)
    private let pdfDoc        = PDFDocument()
    
    ///Batch only properties
    private var angles   : [CGFloat]                = []
    private var results  : [ImageScannerResults]    = []
    private var pdfPages : [PDFPage]                = []
    
    /* MARK:- Lazy Properties */
    lazy var pdfView: PDFView = {
        let pdfView              = PDFView()
        pdfView.backgroundColor  = #colorLiteral(red: 0.9568627451, green: 0.9568627451, blue: 0.9725490196, alpha: 1)
        pdfView.autoScales       = true
        pdfView.displayMode      = .singlePageContinuous
        pdfView.displayDirection = .horizontal
        
        pdfView.pageBreakMargins = UIEdgeInsets(
            top    : 0.0 ,
            left   : 0.0 ,
            bottom : 0.0 ,
            right  : 0.0
        )
        
        pdfView.displaysPageBreaks = true
        
        pdfView.usePageViewController(true, withViewOptions: nil)
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        
        return pdfView
    }()
    
    /* MARK: - Life Cycle */
    init(
        results: ImageScannerResults,
        PageSize size: PageSize,
        ScannerType scannerType: ScannerType,
        andRotatedAngle rotatedAngle: CGFloat
    ) {
        angle        = rotatedAngle
        result       = results
        pageSize     = size
        
        self.scannerType  = scannerType
        self.rotatedAngle = Measurement<UnitAngle>(
            value: Double(rotatedAngle),
            unit: .degrees
        )
        
        super.init(nibName: nil, bundle: nil)
    }
    
    init(
        results: [ImageScannerResults],
        PageSize size: PageSize,
        ScannerType scannerType: ScannerType,
        andRotatedAngle rotatedAngle: [CGFloat]
    ) {
        angle        = 0.0
        result       = results[0]
        pageSize     = size
        
        self.scannerType  = scannerType
        self.rotatedAngle = Measurement<UnitAngle>(
            value: Double(rotatedAngle[0]),
            unit: .degrees
        )
        
        for a in rotatedAngle {
            angles.append(a)
        }
        
        for r in results {
            self.results.append(r)
        }
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initVC()
    }
    
    deinit {
        Helper.debugLogs(any: "Deinit Review VC Successful")
    }
}

/* MARK: - Methods */
extension ReviewVC {
    func initVC(){
        if scannerType == .batch {
            initPDFPages()
        } else {
            initPDFPage()
        }
        scannedImageContainerView.addSubview(pdfView)
        setupConstraints()
    }
    
    private func setupConstraints() {
        pdfView.translatesAutoresizingMaskIntoConstraints = false
 
        let pdfViewConstraints: [NSLayoutConstraint] = [
            pdfView.topAnchor.constraint(
                equalTo : scannedImageContainerView.topAnchor,
                constant: 10
            ),
            pdfView.trailingAnchor.constraint(
                equalTo : scannedImageContainerView.trailingAnchor,
                constant: -30
            ),
            pdfView.bottomAnchor.constraint(
                equalTo : scannedImageContainerView.bottomAnchor,
                constant: -50
            ),
            pdfView.leadingAnchor.constraint(
                equalTo : scannedImageContainerView.leadingAnchor,
                constant: 30
            )
        ]
        
        NSLayoutConstraint.activate(pdfViewConstraints)
    }
    
    func initPDFPage(){
        if let image = result.croppedScan.image.rotated(by: rotatedAngle) {
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
            
            switch pageSize {///Sizes At 300 PPI
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
            pdfDoc.insert(
                pdfPage,
                at: 0
            )
            
            pdfView.document = pdfDoc
        }
    }
    
    func initPDFPages(){
        for (i,r) in results.enumerated() {
            autoreleasepool {
                let rAngle = Measurement<UnitAngle>(
                    value: Double(angles[i]),
                    unit : .degrees
                )
                
                if let image = r.croppedScan.image.rotated(by: rAngle) {
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
                    
                    switch pageSize {///Sizes At 300 PPI
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
                    
                    pdfPages.append(pdfPage)
                }
            }
        }
        
        for (index,page) in pdfPages.enumerated() {
            pdfDoc.insert(
                page,
                at: index
            )
        }
        
        pdfView.document = pdfDoc
        
    }
}

/* MARK: - Actions */
extension ReviewVC {
    @IBAction func didTapBack(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func didTapSave(_ sender: UIButton) {
        
    }
}
