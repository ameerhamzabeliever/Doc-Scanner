//
//  SettingsVC.swift
//  Doc Scanner
//
//  Created by M Farhan on 7/28/20.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import UIKit
import StoreKit

class SettingsVC: UIViewController {
    
    /* MARK:- IBOutlets  */
    @IBOutlet weak var tableView             : UITableView!
    @IBOutlet weak var proBarView            : UIView!
    @IBOutlet weak var howToUseView          : UIView!
    @IBOutlet weak var restorePurchaseButton : UIButton!
    
    /* MARK:- NSLayout Constraints */
    @IBOutlet weak var howToUseTop         : NSLayoutConstraint!
    @IBOutlet weak var probarHeight        : NSLayoutConstraint!
    @IBOutlet weak var restoreButtonHeight : NSLayoutConstraint!
    
    /* MARK:- Lazy Properties */
    lazy var settingsNib: UINib = {
        return UINib(nibName: Constants.cellNib.SETTINGS, bundle: nil)
    }()
    
    /* MARK:- Properties */
    var settings: [String] = [
        "App Pin & Touch ID",
        "Start App With"    ,
//        "Wifi Transfer"     ,
        "Picture Quality"   ,
        "Contact us"        ,
        "Rate us"           ,
        "Share App"         ,
        "TOS"               ,
        "More Apps"
    ]
    
    /* MARK:- Lifecycle */
    override func viewDidLoad() {
        super.viewDidLoad()
        initVC()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ///If is premium user then hide probar
        probar(shouldHide: Constants.sharedInstance.isPremiumUser)
        ///Reload inorder to update the tableview according to new changes
        tableView.reloadData()
    }

}

/* MARK:- Methods */
extension SettingsVC {
    func initVC() {
        ///ProBar View Design Setup
        MAIN_QUEUE.asyncAfter(deadline: .now() + 0.05) {
            self.proBarView.layer.cornerRadius = self.proBarView.frame.height / 2.0
        }
        ///Restore Purchase button attributed text setup
        switch Helper.device() {
        case .iPad:
            let arrtibutedText = Helper.underlineText(
                withTitle : "Restore Purchase",
                andColor  : #colorLiteral(red: 0.2078431373, green: 0.2078431373, blue: 0.2078431373, alpha: 1),
                andFont   : UIFont(name: "Roboto-Regular", size: 22.0)!
            )
            
            restorePurchaseButton.setAttributedTitle(arrtibutedText, for: .normal)
        case .bezeliPhone, .bezelLessiPhone:
            let arrtibutedText = Helper.underlineText(
                withTitle : "Restore Purchase",
                andColor  : #colorLiteral(red: 0.2078431373, green: 0.2078431373, blue: 0.2078431373, alpha: 1),
                andFont   : UIFont(name: "Roboto-Regular", size: 14.0)!
            )
            
            restorePurchaseButton.setAttributedTitle(arrtibutedText, for: .normal)
        }
        
        ///howToUse View radius setup
        self.howToUseView.layer.cornerRadius  = self.howToUseView.frame.height/2
        
        ///Nib Registeration
        registerNib()
    }
    
    func probar(shouldHide flag: Bool) {
        if flag {
            howToUseTop.constant         = 0
            probarHeight.constant        = 0
            restoreButtonHeight.constant = 0
            
            restorePurchaseButton.isHidden = true
        } else {
            howToUseTop.constant         = 30.0
            probarHeight.constant        = 52.0
            restoreButtonHeight.constant = 29.0
            
            restorePurchaseButton.isHidden = false
        }
    }
    
    func registerNib(){
        tableView.register(
            settingsNib,
            forCellReuseIdentifier: Constants.cellNib.SETTINGS
        )
    }
    
    func openUrl(withLink strUrl: String) {
        if let url = URL(string: strUrl) {
            UIApplication.shared.open(url)
        }
    }
    
    func openRateUsDilogue(){
        if #available(iOS 14, *) {
            if let scene = UIApplication.shared.currentScene {
                SKStoreReviewController.requestReview(in: scene)
            }
        } else {
            SKStoreReviewController.requestReview()
        }
    }
    
    func share(Application text: [Any]){
        let activityVC = UIActivityViewController(activityItems: text, applicationActivities: nil)
        present(activityVC, animated: true, completion: nil)
    }
}

/* MARK:- Actions */
extension SettingsVC {
    @IBAction func didTapGetPro(_ sender: UIButton) {
        let premiumVC = PremiumPopUp(nibName: Constants.VCID.PREMIUM_POPUP, bundle: nil)
        
        premiumVC.modalTransitionStyle   = .coverVertical
        premiumVC.modalPresentationStyle = .overFullScreen
        
        self.present(premiumVC, animated: true, completion: nil)
    }
    
    @IBAction func didTapRestore(_ sender: UIButton) {
        showSpinner(onView: view, title: "Restoring, Please wait")
        IAPManager.sharedInstance.restorePurchase { [weak self] isRestored in
            guard let self = self else {return}
            
            self.removeSpinner()
            
            if isRestored {
                self.probar(shouldHide: true)
                Constants.sharedInstance.isPremiumUser = true
            } else {
                self.showAlert(message: "Nothing to restore")
                Constants.sharedInstance.isPremiumUser = false
            }
        }
    }
}

/* MARK:- TableView */

///DataSource
extension SettingsVC: UITableViewDataSource {
    func tableView(
        _ tableView                   : UITableView,
        numberOfRowsInSection section : Int
    ) -> Int {
        return settings.count
    }
    
    func tableView(
        _ tableView            : UITableView,
        cellForRowAt indexPath : IndexPath
    ) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(
                    withIdentifier: Constants.cellNib.SETTINGS
                   ) as! SettingsCell
        
        let index    = indexPath.row
        cell.setting = settings[index]
        
        if index == 0 {
            if Constants.sharedInstance.appLockType != 0 {
                cell.selectedNameLabel.text = "On"
            } else {
                cell.selectedNameLabel.text = "Off"
            }
        } else if index == 1 {
            let startAppWith = StartAppWith(rawValue: Constants.sharedInstance.startAppWith)
            
            switch startAppWith {
            case .documents:
                cell.selectedNameLabel.text = "Documents"
            case .scanner:
                cell.selectedNameLabel.text = "Scanner"
            default:
                break
            }
        } else if index == 2 {
            let pictureQuality = PictureQuality(rawValue: Constants.sharedInstance.pictureQuality)
            
            switch pictureQuality {
            case .low:
                cell.selectedNameLabel.text = "Low"
            case .medium:
                cell.selectedNameLabel.text = "Medium"
            case .high:
                cell.selectedNameLabel.text = "High"
            case .original:
                cell.selectedNameLabel.text = "Original"
            default:
                break
            }
        }
        
        return cell
    }
}

///Delegate
extension SettingsVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let index = indexPath.row
        
        if index == 0 { /// App Pin & Touch ID
            openPinVC()
        } else if index == 1 { /// Start App With
            openStartAppWithVC()
        } else if index == 2 { /// Picture Quality
            openPictureQualityVC()
        } else if index == 3 { /// Contact Us
            openUrl(withLink: "fb://profile/1398094643543511")
        } else if index == 4 { /// Rate Us
            openRateUsDilogue()
        } else if index == 5 { /// Share App
            let shareMessage = """
            Try Doc Scanner app! It helps scan and share any documents you need.
            \(APP_LINK)\(APP_ID)
            """
            
            share(Application: [shareMessage])
        } else if index == 6 { ///TOS
            openUrl(withLink: "https://people-talent.com.my/Privacy/terms_and_conditions.html")
        } else if index == 7 { ///More Apps
            openUrl(withLink: "https://apps.apple.com/us/developer/ptt-games/id1276114260")
        }
        
    }
    
    func tableView(
        _ tableView              : UITableView,
        heightForRowAt indexPath : IndexPath
    ) -> CGFloat {
        return 66.0
    }
}


///Actions
extension SettingsVC {
    func openPinVC(){
        let appPinVC = AppPinVC(nibName: Constants.VCID.APP_PIN, bundle: nil)
        
        self.navigationController?.pushViewController(appPinVC, animated: true)
    }
    
    func openStartAppWithVC(){
        let startAppWithVC = StartAppWithVC(
            nibName: Constants.VCID.START_APP_WITH,
            bundle : nil
        )
        
        self.navigationController?.pushViewController(
            startAppWithVC,
            animated: true
        )
    }
    
    func openPictureQualityVC(){
        let pictureQualityVC = PictureQualityVC(
            nibName: Constants.VCID.PICTURE_QUALITY,
            bundle : nil
        )
        
        self.navigationController?.pushViewController(
            pictureQualityVC,
            animated: true
        )
    }
}
