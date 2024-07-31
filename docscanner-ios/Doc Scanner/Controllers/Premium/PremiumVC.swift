//
//  PremiumVC.swift
//  Doc Scanner
//
//  Created by M Farhan on 8/15/20.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import UIKit

class PremiumVC: UIViewController {

    /* MARK:- IBOutlets */
    @IBOutlet weak var containerView            : UIView!
    @IBOutlet weak var segmentControl           : UISegmentedControl!
    @IBOutlet weak var docScannerIconImage      : UIImageView!
    @IBOutlet weak var subscriptionDetailButton : UIButton!
    
    @IBOutlet weak var yearlyPriceLabel         : UILabel!
    @IBOutlet weak var monthlyPriceLabel        : UILabel!
    
    @IBOutlet weak var yearlySubscriptionButton  : UIButton!
    @IBOutlet weak var monthlySubscriptionButton : UIButton!
    
    /* MARK:- NSLayout Constaints */
    @IBOutlet weak var imageTopConstraint : NSLayoutConstraint!
    
    /* MARK:- IBOutlets Collection */
    @IBOutlet var subscriptionRadioButtons: [UIImageView]!
    
    /* MARK:- Properties */
    var privilegesAndDetailsView : UIView         = UIView()
    var selectedSubscription     : IAPIdentifiers = IAPIdentifiers.yearly
    var refrenceVC               : DocsVC?
    
    /* MARK:- Life Cycle */
    override func viewDidLoad() {
        super.viewDidLoad()
        initVC()///Initilization of VC
    }

}

/* MARK:- Methods */
extension PremiumVC {
    func initVC() {
        MAIN_QUEUE.async {
            self.imageTopConstraint.constant = SCREEN_HEIGHT * 0.0390625
        }
        ///Segment-Control setup
        setupSegmentControl()
        ///Setup Privileges And Details View
        setupPrivilegesAndDetailsView()
        ///Subscription detail button attributed text setup
        switch Helper.device() {
        case .iPad:
            let subscriptionDetail = Helper.underlineText(
                withTitle : "Tap to see Subscription details" ,
                andColor  : #colorLiteral(red: 0.1882352941, green: 0.1882352941, blue: 0.1882352941, alpha: 1)                                ,
                andFont   : UIFont(name: "Roboto-Light", size: 22.0)!
            )
            
            subscriptionDetailButton.setAttributedTitle(
                subscriptionDetail,
                for: .normal
            )
            
            docScannerIconImage.image = UIImage(named: "ipad-doc-scanner-pro-icon")
        case .bezeliPhone, .bezelLessiPhone:
            let subscriptionDetail = Helper.underlineText(
                withTitle : "Tap to see Subscription details"  ,
                andColor  : #colorLiteral(red: 0.1882352941, green: 0.1882352941, blue: 0.1882352941, alpha: 1)                                 ,
                andFont   : UIFont(name: "Roboto-Light", size: 15.0)!
            )
            
            subscriptionDetailButton.setAttributedTitle(
                subscriptionDetail,
                for: .normal
            )
            
            docScannerIconImage.image = UIImage(named: "iphone-doc-scanner-pro-icon")
        }
        
        /// Getting IAP Info
        if Constants.sharedInstance.IAPInfo == nil {
            IAPManager.sharedInstance.getSubscriptionInfo { [weak self] isCompleted in
                guard let self = self else {return}
                if isCompleted {
                    self.setupIAPInfo()
                }
            }
        } else {
            setupIAPInfo()
        }
    }
    
    func setupSegmentControl() {
        let selectedTextColor   = [NSAttributedString.Key.foregroundColor: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)]
        let unselectedTextColor = [NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.3568627451, green: 0.3568627451, blue: 0.3568627451, alpha: 1)]
        
        segmentControl.setTitleTextAttributes(selectedTextColor   , for: .selected)
        segmentControl.setTitleTextAttributes(unselectedTextColor , for: .normal  )
    }
    
    func setupPrivilegesAndDetailsView(){
        if let loadedNib = Bundle.main.loadNibNamed(
            Constants.VIEW.PRIVILEGES_DETAILS,
            owner   : self,
            options : nil
        ) {
            
            if let view = loadedNib.first as? PrivilegesAndDetailsView {
                MAIN_QUEUE.asyncAfter(deadline: .now() + 0.05, execute: {
                    ///Setting up proportional frame
                    var frame: CGRect   = CGRect()
                    
                    frame.origin.x      = 0.0
                    frame.origin.y      = 0.0
                    
                    switch Helper.device() {
                    case .iPad:
                        frame.size.width  = SCREEN_WIDTH * 1.5
                    case .bezelLessiPhone:
                        frame.size.width  = SCREEN_WIDTH * 2.0
                    case .bezeliPhone:
                        frame.size.width  = SCREEN_WIDTH * 2.11
                    }
                    
                    frame.size.height   = self.containerView.frame.height
                    
                    view.frame          = frame
                    
                    ///Setting up stackview spacing
                    view.setupStackSpacing()
                    ///Adding into view
                    self.containerView.addSubview(view)
                    ///Assigning view to class scope variable
                    self.privilegesAndDetailsView = view
                })
            }
            
        }
    }
    
    func resetSelectedPremiumDeal(){
        for imageView in subscriptionRadioButtons {
            imageView.image = UIImage(named: "premium-radio-unselected")
        }
    }
    
    func setupIAPInfo(){
        if let IAPInfo = Constants.sharedInstance.IAPInfo {
            IAPInfo.forEach { (info) in
                if info.id == IAPIdentifiers.monthly.rawValue {
                    
                    monthlyPriceLabel.text = "\(info.price)/month"
                    monthlySubscriptionButton.accessibilityIdentifier = info.id
                    
                } else if info.id == IAPIdentifiers.yearly.rawValue {
                    
                    yearlyPriceLabel.text  = "\(info.price)/yearly"
                    yearlySubscriptionButton.accessibilityIdentifier  = info.id
                    
                }
            }
        }
    }
}

/* MARK:- Actions */
extension PremiumVC {
    @IBAction func togglePremiumDeals(_ sender: UIButton) {
        ///Resetting images
        resetSelectedPremiumDeal()
        ///Setting up selected image
        if sender.accessibilityIdentifier == IAPIdentifiers.monthly.rawValue {
            for imageView in subscriptionRadioButtons {
                if imageView.accessibilityIdentifier == IAPIdentifiers.monthly.rawValue {
                    imageView.image = UIImage(named: "premium-radio-selected")
                }
            }
            
            selectedSubscription = IAPIdentifiers.monthly
        } else {
            for imageView in subscriptionRadioButtons {
                if imageView.accessibilityIdentifier == IAPIdentifiers.yearly.rawValue {
                    imageView.image = UIImage(named: "premium-radio-selected")
                }
            }
            
            selectedSubscription = IAPIdentifiers.yearly
        }
    }
    
    @IBAction func toggleSegmentControl(_ sender: UISegmentedControl) {
        let selectedIndex = sender.selectedSegmentIndex
        
        if selectedIndex == 0 {
            privilegesAndDetailsView.transform = CGAffineTransform(
                translationX : 0,
                y            : 0
            )
        } else {
            privilegesAndDetailsView.transform = CGAffineTransform(
                translationX : -SCREEN_WIDTH,
                y            : 0
            )
        }
    }
    
    @IBAction func didTapSubscriptionDetail(_ sender: UIButton){
        let subscriptionDetailVC = SubscriptionDetailsVC(
            nibName: Constants.VCID.SUBSCROPTION_DETAIL,
            bundle : nil
        )
       
        subscriptionDetailVC.modalTransitionStyle   = .coverVertical
        subscriptionDetailVC.modalPresentationStyle = .overFullScreen
        
        self.present(subscriptionDetailVC, animated: true, completion: nil)
    }
    
    @IBAction func didTapGetPremium(_ sender: UIButton) {
        IAPManager.sharedInstance.purchaseSubscription(
            withIdentifier: selectedSubscription
        ) { [weak self] isPurchased in
            guard let self = self else {return}
            
            if isPurchased {
                Constants.sharedInstance.isPremiumUser = true
                self.dismiss(animated: true) {
                    if let docsVC = self.refrenceVC {
                        docsVC.probar(shouldHide: true)
                    }
                }
            } else {
                Constants.sharedInstance.isPremiumUser = true
                self.dismiss(animated: true) {
                    if let docsVC = self.refrenceVC {
                        #if !DEBUG
                        docsVC.showInterstitial()
                        #endif
                    }
                }
            }
            
        }
    }
    
    @IBAction func didTapRestore(_ sender: UIButton) {
        showSpinner(onView: view, title: "Restoring, Please wait")
        IAPManager.sharedInstance.restorePurchase { [weak self] isRestored in
            guard let self = self else {return}
            
            self.removeSpinner()
            
            if isRestored {
                Constants.sharedInstance.isPremiumUser = true
                self.dismiss(animated: true) {
                    if let docsVC = self.refrenceVC {
                        docsVC.probar(shouldHide: true)
                    }
                }
            } else {
                Constants.sharedInstance.isPremiumUser = false
                self.dismiss(animated: true) {
                    if let topVC = UIApplication.topViewController() {
                        topVC.showAlert(message: "Nothing to restore")
                    }
                }
            }
        }
    }
    
    @IBAction func didTapClose(_ sender: UIButton){
        self.dismiss(animated: true) { [weak self] in
            guard let self = self else {return}
            
            if !Constants.sharedInstance.isPremiumUser {
                if let docsVC = self.refrenceVC {
                    #if !DEBUG
                    docsVC.checkPremiumStatus()
                    #endif
                }
            }
        }
    }
}
