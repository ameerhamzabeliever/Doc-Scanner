//
//  DocVC.swift
//  Doc Scanner
//
//  Created by M Farhan on 8/19/20.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import UIKit
import PDFKit
import Vision
import VisionKit
import GoogleMobileAds

class DocVC: UIViewController {
    
    /* MARK:- IBOutlets */
    @IBOutlet weak var nameLabel             : UILabel!
    @IBOutlet weak var countLabel            : UILabel!
    @IBOutlet weak var pdfContainerView      : UIView!
    @IBOutlet weak var bannerAdContainerView : UIView!
    
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
    
    /* MARK:- Properties */
    let pdfDoc   = PDFDocument()
    var document : DocumentsModel!
    
    var currentPage : Int  = 0
    var shouldShowAd: Bool = false
    
    var docOptionsView: DocOptions?
    
    ///Google Mobile Ads
    var bannerView      : GADBannerView!
    var interstitial    : GADInterstitial!
    var shouldPresentAd : Bool = false
    
    ///OCR Properties
    var ocrRequest = VNRecognizeTextRequest(completionHandler: nil)
    
    /* MARK:- Life Cycle */
    override func viewDidLoad() {
        super.viewDidLoad()
        initVC()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let selector = #selector(didChangePDFPage)
        NotificationCenter.default.addObserver(
            self,
            selector : selector,
            name     : Notification.Name.PDFViewPageChanged,
            object   : nil
        )
    }

}

/* MARK:- Methods */
extension DocVC {
    private func initVC(){
        ///Setting Up Doc Name
        nameLabel.text = document.name
        ///Add DocOptions View
        loadOptionsView()
        ///Adding PDF view & setting up constraints
        setupPDFView()
        ///Initilizing Document
        initPDFView()
        ///OCR Setup
        ocrSetup()
        
        ///AdMobs
        if shouldShowAd {
            #if !DEBUG
            checkPremiumStatus()
            #endif
        }
        
        if !Constants.sharedInstance.isPremiumUser {
            bannerAdContainerView.isHidden = false
            
            showBanner()
        } else {
            bannerAdContainerView.isHidden = true
        }
    }

    private func initPDFView(){
        MAIN_QUEUE.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self = self else { return }
         
            for (index,item) in self.document.pages.enumerated() {
                if let tempDoc = PDFDocument(data: item.enhancedImage) {
                    if let page = tempDoc.page(at: 0) {
                        self.pdfDoc.insert(
                            page,
                            at: index
                        )
                    }
                }
            }
            
            self.pdfView.document = self.pdfDoc
            
            self.countLabel.text = "1/\(self.pdfView.document?.pageCount ?? 1)"
        }
    }
    
    public func shouldAddNewPage() {
        let keyVal = ["id": "\(self.document.id)"]
        let result = CBFileManager.sharedInstance.retrieveFilesFolders(
            shouldAddCondition: true,
            withKeyAndValue   : keyVal,
            ofType            : nil
        )

        guard let doc = result.first else { return }

        if let newPage = doc.pages.last?.enhancedImage {
            if let tempDoc = PDFDocument(data: newPage) {
                if let page = tempDoc.page(at: 0) {
                    self.pdfView.document?.insert(
                        page,
                        at: self.pdfView.document!.pageCount
                    )
                }
            }
        }
        
        self.pdfView.goToFirstPage(nil)
        self.countLabel.text = "1/\(self.pdfView.document?.pageCount ?? 1)"
    }
    
    public func shouldUpdatePage() {
        let keyVal = ["id": "\(self.document.id)"]
        let result = CBFileManager.sharedInstance.retrieveFilesFolders(
            shouldAddCondition: true,
            withKeyAndValue   : keyVal,
            ofType            : nil
        )
        
        guard let doc = result.first else { return }
        
        self.pdfView.document?.removePage(at: currentPage)
        
        let updatedPage = doc.pages[currentPage].enhancedImage
        if let tempDoc  = PDFDocument(data: updatedPage) {
            if let page = tempDoc.page(at: 0) {
                self.pdfView.document?.insert(
                    page,
                    at: self.pdfView.document!.pageCount
                )
            }
        }
        
        self.pdfView.goToFirstPage(nil)
        self.countLabel.text = "1/\(self.pdfView.document?.pageCount ?? 1)"
    }
    
    private func ocrSetup(){
        ocrRequest = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            
            var ocrText = ""
            for observation in observations {
                guard let topCandidate = observation.topCandidates(1).first else { return }
                
                ocrText += topCandidate.string + "\n"
            }
            
            DispatchQueue.main.async {
                let ocrTextVC     = OCRTextVC(nibName: Constants.VCID.OCR_TEXT, bundle: nil)
                ocrTextVC.ocrText = ocrText
                
                ocrTextVC.modalPresentationStyle = .overFullScreen
                ocrTextVC.modalTransitionStyle   = .coverVertical
                
                self.present(ocrTextVC, animated: true, completion: nil)
            }
        }
        
        ocrRequest.recognitionLevel       = .accurate
        ocrRequest.recognitionLanguages   = ["en-US", "en-GB"]
        ocrRequest.usesLanguageCorrection = true
    }
    
    private func setupPDFView() {
        pdfContainerView.addSubview(pdfView)
        
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        
        let pdfViewConstraints: [NSLayoutConstraint] = [
            pdfView.topAnchor.constraint(
                equalTo : pdfContainerView.topAnchor,
                constant: 0.0
            ),
            pdfView.trailingAnchor.constraint(
                equalTo : pdfContainerView.trailingAnchor,
                constant: 0.0
            ),
            pdfView.bottomAnchor.constraint(
                equalTo : pdfContainerView.bottomAnchor,
                constant: 0.0
            ),
            pdfView.leadingAnchor.constraint(
                equalTo : pdfContainerView.leadingAnchor,
                constant: 0.0
            )
        ]
        
        NSLayoutConstraint.activate(pdfViewConstraints)
    }
    
    ///Doc Options View Load and Remove
    private func loadOptionsView(){
        if let loadedNib = Bundle.main.loadNibNamed(
            Constants.VIEW.DOC_OPTIONS,
            owner   : self,
            options : nil
        ) {
            
            if let docOptions = loadedNib.first as? DocOptions {
                ///Setting proportional frame
                let width       = SCREEN_WIDTH * 0.91945894
                let height      = CGFloat(70.0)
                let x           = (SCREEN_WIDTH/2) - (width/2)
                let y           = SCREEN_HEIGHT * 0.81
                
                /*let y = SCREEN_HEIGHT * 0.85714246 [Original Y position i.e. Before Banner]*/
                
                docOptions.frame = CGRect(
                    x      : x,
                    y      : y,
                    width  : width,
                    height : height
                )
                
                ///Passing self refrence
                docOptions.docVC = self
                ///Adding Identifire
                docOptions.accessibilityIdentifier = Constants.VIEW.DOC_OPTIONS
                ///Adding Corner Radius
                docOptions.layer.cornerRadius = docOptions.frame.height/2
                ///Initilizing tabBar
                docOptions.initView()
                ///Assigning to class scope variable
                docOptionsView = docOptions
                ///Adding into view
                self.view.addSubview(docOptions)
            }
            
        }
    }
    
    func printPage(withDocument document: NSData) {
        let printController            = UIPrintInteractionController.shared
        
        let printInfo                  = UIPrintInfo(dictionary: [:])
        printInfo.jobName              = "Sample"
        printInfo.outputType           = UIPrintInfo.OutputType.general
        printInfo.orientation          = UIPrintInfo.Orientation.portrait
        printController.printInfo      = printInfo
        
        printController.printingItem   = document
        
        printController.present(animated: true, completionHandler: nil)
    }
    
    ///Verification of user's purchase
    func checkPremiumStatus(){
        if Constants.sharedInstance.isPremiumUser {
            if let expiryDate = Constants.sharedInstance.subscriptionExpiryDate {
                if Date() > expiryDate {
                    showInterstitial()
                    Constants.sharedInstance.isPremiumUser = false
                    docOptionsView?.setCrownImage(forPremiumUser: false)
                }
            } else {
                verifyPurchase()
            }
        } else {
            showInterstitial()
            Constants.sharedInstance.isPremiumUser = false
            docOptionsView?.setCrownImage(forPremiumUser: false)
        }
    }
    
    func verifyPurchase(){
        showSpinner(onView: view)
        if let rawValue = Constants.sharedInstance.purchasedIdentifier {
            if let identifier = IAPIdentifiers(rawValue: rawValue) {
                IAPManager.sharedInstance.verifyReceipt(withIdentifier: identifier) { [weak self] state in
                    guard let self = self else { return }
                    
                    self.removeSpinner()
                    
                    switch state {
                    case .purchased:
                        break
                    case .expired, .notPurchased:
                        self.showInterstitial()
                        Constants.sharedInstance.isPremiumUser = false
                        self.docOptionsView?.setCrownImage(forPremiumUser: false)
                    }
                }
            } else {
                removeSpinner()
                showInterstitial()
                docOptionsView?.setCrownImage(forPremiumUser: false)
            }
        } else {
            removeSpinner()
            showInterstitial()
            docOptionsView?.setCrownImage(forPremiumUser: false)
        }
    }
    
    /// Google AdMobs
    func showInterstitial(){
        interstitial = GADInterstitial(adUnitID: INTERSTITIAL_ID)
        
        let request  = GADRequest()
        interstitial.load(request)
        
        shouldPresentAd       = true
        interstitial.delegate = self
    }
    
    func showBanner(){
        bannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
        
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        
        bannerView.delegate           = self
        bannerView.adUnitID           = BANNER_ID
        bannerView.rootViewController = self
        
        bannerView.alpha = 0
        
        bannerView.load(GADRequest())
        
        bannerAdContainerView.addSubview(bannerView)
        
        let bannerViewConstraints: [NSLayoutConstraint] = [
            bannerView.topAnchor.constraint(
                equalTo: bannerAdContainerView.topAnchor
            ),
            bannerView.bottomAnchor.constraint(
                equalTo: bannerAdContainerView.bottomAnchor
            ),
            bannerView.leadingAnchor.constraint(
                equalTo: bannerAdContainerView.leadingAnchor
            ),
            bannerView.trailingAnchor.constraint(
                equalTo: bannerAdContainerView.trailingAnchor
            )
        ]
        
        NSLayoutConstraint.activate(bannerViewConstraints)
    }
    
    /// Rating Popup
    func openRateUsDilogue(){
        if #available(iOS 14, *) {
            if let scene = UIApplication.shared.currentScene {
                SKStoreReviewController.requestReview(in: scene)
            }
        } else {
            SKStoreReviewController.requestReview()
        }
    }
}

/* MARK:- Actions */
extension DocVC {
    @IBAction func didTapCancel(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func didTapRename(_ sennder: UIButton) {
        let renameVC = RenameVC(nibName: Constants.VCID.RENAME, bundle: nil)
        
        renameVC.refrence = self
        renameVC.document = document
        
        renameVC.modalTransitionStyle   = .coverVertical
        renameVC.modalPresentationStyle = .overFullScreen
        
        present(renameVC, animated: true, completion: nil)
    }
    
    @IBAction func didTapPrint(_ sennder: UIButton) {
        if let data = self.pdfView.document?.dataRepresentation() {
            let document = NSData(data: data)
            printPage(withDocument: document)
        }
    }
}

/* MARK:- Objective C Interface */
extension DocVC {
    @objc func didChangePDFPage() {
        if let currentPage   = pdfView.currentPage {
            let pageNumber   = pdfDoc.index(for: currentPage)
            self.currentPage = pageNumber
            countLabel.text  = "\(pageNumber + 1)/\(pdfView.document?.pageCount ?? 1)"
        }
    }
}

/* MARK:- Google AdMobs */

/// Interstitial Delegate
extension DocVC: GADInterstitialDelegate {
    func interstitialDidReceiveAd(_ ad: GADInterstitial) {
        if shouldPresentAd {
            interstitial.present(fromRootViewController: self)
            
            shouldPresentAd = false
        }
    }
    
    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        openRateUsDilogue()
    }
}

/// Banner Delegate
extension DocVC: GADBannerViewDelegate {
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        UIView.animate(withDuration: 1, animations: { [weak self] in
            guard let self = self else {return}
            
            self.bannerView.alpha = 1
        })
    }
}
