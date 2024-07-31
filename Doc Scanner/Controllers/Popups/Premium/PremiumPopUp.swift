//
//  PremiumPopUp.swift
//  Doc Scanner
//
//  Created by M Farhan on 8/15/20.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import UIKit

class PremiumPopUp: UIViewController {

    /* MARK:- IBOutlet */
    @IBOutlet weak var containerView            : UIView!
    @IBOutlet weak var restoreButton            : UIButton!
    @IBOutlet weak var subscriptionDetailButton : UIButton!
    
    @IBOutlet weak var yearlyPriceLabel         : UILabel!
    @IBOutlet weak var weeklyPriceLabel         : UILabel!
    @IBOutlet weak var monthlyPriceLabel        : UILabel!
    
    @IBOutlet weak var yearlySubscriptionButton  : UIButton!
    @IBOutlet weak var weeklySubscriptionButton  : UIButton!
    @IBOutlet weak var monthlySubscriptionButton : UIButton!
    
    /* MARK:- IBOutlets Collection */
    @IBOutlet var plansView       : [UIView]!
    @IBOutlet var planslabels     : [UILabel]!
    @IBOutlet var radioImageView  : [UIImageView]!
    @IBOutlet var plansBGImageView: [UIImageView]!
    
    /* MARK:- Properties */
    var selectedSubscription     : IAPIdentifiers = IAPIdentifiers.weekly
    
    var fromVC                   : VCToBeUpdated  = .docsVC
    var refrenceVC               : Any?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initVC()///Initilization of view
    }
    
}

/* MARK:- Methods */
extension PremiumPopUp {
    func initVC(){
        ///Container view corner radius setup
        containerView.layer.cornerRadius  = 25
        containerView.layer.maskedCorners = [
            .layerMinXMinYCorner,
            .layerMaxXMinYCorner
        ]
        
        ///Setting up corner radius of plans view
        for view in plansView {
            view.layer.cornerRadius = view.frame.height / 2.0
        }
        ///Subscription detail button attributed text setup
        switch Helper.device() {
        case .iPad:
            let restore = Helper.underlineText(
                withTitle : "Restore?" ,
                andColor  : #colorLiteral(red: 0.3882352941, green: 0.3882352941, blue: 0.3882352941, alpha: 1)         ,
                andFont   : UIFont(name: "Roboto-Regular", size: 30.0)!
            )
            
            let subscriptionDetail = Helper.underlineText(
                withTitle : "Tap to see Subscription details" ,
                andColor  : #colorLiteral(red: 0.1882352941, green: 0.1882352941, blue: 0.1882352941, alpha: 1)                                ,
                andFont   : UIFont(name: "Roboto-Light", size: 22.0)!
            )
            
            restoreButton.setAttributedTitle(
                restore,
                for: .normal
            )
            
            subscriptionDetailButton.setAttributedTitle(
                subscriptionDetail,
                for: .normal
            )
        case .bezeliPhone, .bezelLessiPhone:
            let restore = Helper.underlineText(
                withTitle : "Restore?" ,
                andColor  : #colorLiteral(red: 0.3882352941, green: 0.3882352941, blue: 0.3882352941, alpha: 1)         ,
                andFont   : UIFont(name: "Roboto-Regular", size: 20.0)!
            )
            
            let subscriptionDetail = Helper.underlineText(
                withTitle : "Tap to see Subscription details"  ,
                andColor  : #colorLiteral(red: 0.1882352941, green: 0.1882352941, blue: 0.1882352941, alpha: 1)                                 ,
                andFont   : UIFont(name: "Roboto-Light", size: 15.0)!
            )
            
            restoreButton.setAttributedTitle(
                restore,
                for: .normal
            )
            
            subscriptionDetailButton.setAttributedTitle(
                subscriptionDetail,
                for: .normal
            )
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
    
    func setupIAPInfo(){
        if let IAPInfo = Constants.sharedInstance.IAPInfo {
            IAPInfo.forEach { (info) in
                if info.id == IAPIdentifiers.weekly.rawValue {
                    weeklyPriceLabel.text = "Weekly: \(info.price)/week"
                    weeklySubscriptionButton.accessibilityIdentifier = info.id
                } else if info.id == IAPIdentifiers.monthly.rawValue {
                    monthlyPriceLabel.text = "Monthly: \(info.price)/month"
                    monthlySubscriptionButton.accessibilityIdentifier = info.id
                } else if info.id == IAPIdentifiers.yearly.rawValue {
                    yearlyPriceLabel.text = "Yearly: \(info.price)/year"
                    yearlySubscriptionButton.accessibilityIdentifier = info.id
                }
            }
        }
    }
    
    func resetPremiumPlanView(){
        for view in plansView {
            view.layer.borderWidth = 0.0
        }
        
        for imageView in radioImageView {
            imageView.image = UIImage(named: "premium-radio-unselected")
        }
        
        for imageView in plansBGImageView {
            imageView.image = nil
        }
        
        for label in planslabels {
            label.textColor = #colorLiteral(red: 0.4196078431, green: 0.4196078431, blue: 0.4196078431, alpha: 1)
        }
    }
    
    func selectPlan(WithType type: IAPIdentifiers) {
        ///Resetting selected plan
        resetPremiumPlanView()
        ///Setting up new plan
        switch type {
        case .weekly:
            for view in plansView {
                if view.accessibilityIdentifier == IAPIdentifiers.weekly.rawValue{
                    view.layer.borderWidth = 1.0
                }
            }
            
            for imageView in radioImageView {
                if imageView.accessibilityIdentifier == IAPIdentifiers.weekly.rawValue{
                    imageView.image = UIImage(named: "premium-radio-selected")
                }
            }
            
            for imageView in plansBGImageView {
                if imageView.accessibilityIdentifier == IAPIdentifiers.weekly.rawValue{
                    imageView.image = UIImage(named: "pro-bar-bg")
                }
            }
            
            for label in planslabels {
                if label.accessibilityIdentifier == IAPIdentifiers.weekly.rawValue{
                    label.textColor = #colorLiteral(red: 0.1254901961, green: 0.1254901961, blue: 0.1254901961, alpha: 1)
                }
            }
        case .monthly:
            for view in plansView {
                if view.accessibilityIdentifier == IAPIdentifiers.monthly.rawValue{
                    view.layer.borderWidth = 1.0
                }
            }
            
            for imageView in radioImageView {
                if imageView.accessibilityIdentifier == IAPIdentifiers.monthly.rawValue{
                    imageView.image = UIImage(named: "premium-radio-selected")
                }
            }
            
            for imageView in plansBGImageView {
                if imageView.accessibilityIdentifier == IAPIdentifiers.monthly.rawValue{
                    imageView.image = UIImage(named: "pro-bar-bg")
                }
            }
            
            for label in planslabels {
                if label.accessibilityIdentifier == IAPIdentifiers.monthly.rawValue{
                    label.textColor = #colorLiteral(red: 0.1254901961, green: 0.1254901961, blue: 0.1254901961, alpha: 1)
                }
            }
        case .yearly:
            for view in plansView {
                if view.accessibilityIdentifier == IAPIdentifiers.yearly.rawValue{
                    view.layer.borderWidth = 1.0
                }
            }
            
            for imageView in radioImageView {
                if imageView.accessibilityIdentifier == IAPIdentifiers.yearly.rawValue{
                    imageView.image = UIImage(named: "premium-radio-selected")
                }
            }
            
            for imageView in plansBGImageView {
                if imageView.accessibilityIdentifier == IAPIdentifiers.yearly.rawValue{
                    imageView.image = UIImage(named: "pro-bar-bg")
                }
            }
            
            for label in planslabels {
                if label.accessibilityIdentifier == IAPIdentifiers.yearly.rawValue{
                    label.textColor = #colorLiteral(red: 0.1254901961, green: 0.1254901961, blue: 0.1254901961, alpha: 1)
                }
            }
        }
    }
}

/* MARK:- Actions */
extension PremiumPopUp {
    @IBAction func togglePremiumPlans(_ sender: UIButton){
        if sender.accessibilityIdentifier == IAPIdentifiers.weekly.rawValue {
            selectPlan(WithType: .weekly)
            selectedSubscription = .weekly
        } else if sender.accessibilityIdentifier == IAPIdentifiers.monthly.rawValue {
            selectPlan(WithType: .monthly)
            selectedSubscription = .monthly
        } else if sender.accessibilityIdentifier == IAPIdentifiers.yearly.rawValue {
            selectPlan(WithType: .yearly)
            selectedSubscription = .yearly
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
    
    @IBAction func didTapCross(_ sender: UIButton){
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didTapGetPremium(_ sender: UIButton) {
        IAPManager.sharedInstance.purchaseSubscription(
            withIdentifier: selectedSubscription
        ) { [weak self] isPurchased in
            guard let self = self else {return}
            
            if isPurchased {
                Constants.sharedInstance.isPremiumUser = true
                self.dismiss(animated: true) {
                    switch self.fromVC {
                    case .docVC:
                        if let docVC = self.refrenceVC as? DocVC {
                            docVC.presentCongratulationVC()
                            docVC.docOptionsView?.setCrownImage(forPremiumUser: true)
                        }
                    case .docsVC:
                        if let docsVC = self.refrenceVC as? DocsVC {
                            docsVC.probar(shouldHide: true)
                            docsVC.presentCongratulationVC()
                        }
                    case .settingsVC:
                        if let settingsVC = self.refrenceVC as? SettingsVC {
                            settingsVC.probar(shouldHide: true)
                            settingsVC.presentCongratulationVC()
                        }
                    case .appPinVC:
                        if let appPinVC = self.refrenceVC as? AppPinVC {
                            appPinVC.probar(shouldHide: true)
                            appPinVC.presentCongratulationVC()
                        }
                    case .startAppWithVC:
                        if let startAppWithVC = self.refrenceVC as? StartAppWithVC {
                            startAppWithVC.probar(shouldHide: true)
                            startAppWithVC.presentCongratulationVC()
                        }
                    case .pictureQualityVC:
                        if let pictureQualityVC = self.refrenceVC as? PictureQualityVC {
                            pictureQualityVC.probar(shouldHide: true)
                            pictureQualityVC.presentCongratulationVC()
                        }
                    case .scanningOptionsVC:
                        if let scanningOptionsVC = self.refrenceVC as? ScanningOptions {
                            scanningOptionsVC.presentCongratulationVC()
                            scanningOptionsVC.docsVC?.probar(shouldHide: true)
                            scanningOptionsVC.setCrownImage(forPremiumUser: true)
                        }
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
                    switch self.fromVC {
                    case .docVC:
                        if let docVC = self.refrenceVC as? DocVC {
                            docVC.docOptionsView?.setCrownImage(forPremiumUser: true)
                            docVC.presentCongratulationVC()
                        }
                    case .docsVC:
                        if let docsVC = self.refrenceVC as? DocsVC {
                            docsVC.probar(shouldHide: true)
                            docsVC.presentCongratulationVC()
                        }
                    case .settingsVC:
                        if let settingsVC = self.refrenceVC as? SettingsVC {
                            settingsVC.probar(shouldHide: true)
                            settingsVC.presentCongratulationVC()
                        }
                    case .appPinVC:
                        if let appPinVC = self.refrenceVC as? AppPinVC {
                            appPinVC.probar(shouldHide: true)
                            appPinVC.presentCongratulationVC()
                        }
                    case .startAppWithVC:
                        if let startAppWithVC = self.refrenceVC as? StartAppWithVC {
                            startAppWithVC.probar(shouldHide: true)
                            startAppWithVC.presentCongratulationVC()
                        }
                    case .pictureQualityVC:
                        if let pictureQualityVC = self.refrenceVC as? PictureQualityVC {
                            pictureQualityVC.probar(shouldHide: true)
                            pictureQualityVC.presentCongratulationVC()
                        }
                    case .scanningOptionsVC:
                        if let scanningOptionsVC = self.refrenceVC as? ScanningOptions {
                            scanningOptionsVC.presentCongratulationVC()
                            scanningOptionsVC.docsVC?.probar(shouldHide: true)
                            scanningOptionsVC.setCrownImage(forPremiumUser: true)
                        }
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
}
