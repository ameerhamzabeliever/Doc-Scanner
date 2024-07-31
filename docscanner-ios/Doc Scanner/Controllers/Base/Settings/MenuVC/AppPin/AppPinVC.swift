//
//  AppPinVC.swift
//  Doc Scanner
//
//  Created by M Farhan on 8/10/20.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import UIKit

class AppPinVC: UIViewController {
    /* MARK:- IBOutlets  */
    @IBOutlet weak var usePinView           : UIView!
    @IBOutlet weak var proBarView           : UIView!
    @IBOutlet weak var usePinSwitch         : UISwitch!
    @IBOutlet weak var changePinButton      : UIButton!
    @IBOutlet weak var useTouchIdSwitch     : UISwitch!
    @IBOutlet weak var restorePurchaseButton: UIButton!
    
    /* MARK:- NSLayout Constraints */
    @IBOutlet weak var probarHeight : NSLayoutConstraint!
    
    /* MARK:- Life Cycle */
    override func viewDidLoad() {
        super.viewDidLoad()
        initVC()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ///If is premium user then hide probar
        probar(shouldHide: Constants.sharedInstance.isPremiumUser)
        
        if Constants.sharedInstance.appLockType == 1 {/// Passcode Locked
            usePinSwitch.isOn           = true
            useTouchIdSwitch.isOn       = false
            changePinButton.isHidden    = false
            
            usePinSwitch.thumbTintColor     = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            useTouchIdSwitch.thumbTintColor = #colorLiteral(red: 0.4078431373, green: 0.9411764706, blue: 0.2745098039, alpha: 1)
        } else if Constants.sharedInstance.appLockType == 2 {/// Touch Id Locked
            usePinSwitch.isOn           = true
            useTouchIdSwitch.isOn       = true
            changePinButton.isHidden    = false
            
            usePinSwitch.thumbTintColor     = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            useTouchIdSwitch.thumbTintColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        } else { /// No Lock
            usePinSwitch.isOn           = false
            useTouchIdSwitch.isOn       = false
            changePinButton.isHidden    = true
            
            usePinSwitch.thumbTintColor     = #colorLiteral(red: 0.4078431373, green: 0.9411764706, blue: 0.2745098039, alpha: 1)
            useTouchIdSwitch.thumbTintColor = #colorLiteral(red: 0.4078431373, green: 0.9411764706, blue: 0.2745098039, alpha: 1)
        }
    }

}

/* MARK:- Methods */
extension AppPinVC {
    func initVC() {
        ///ProBar View Design Setup
        MAIN_QUEUE.asyncAfter(deadline: .now() + 0.05) {
            self.proBarView.layer.cornerRadius = self.proBarView.frame.height / 2.0
        }
        ///Restore Purchase button attributed text setup
        switch Helper.device() {
        case .iPad:
            let restorePurchase = Helper.underlineText(
                withTitle : "Restore Purchase" ,
                andColor  : #colorLiteral(red: 0.2078431373, green: 0.2078431373, blue: 0.2078431373, alpha: 1)                 ,
                andFont   : UIFont(name: "Roboto-Regular", size: 22.0)!
            )
            
            let changePin = Helper.underlineText(
                withTitle : "Change Pin"       ,
                andColor  : #colorLiteral(red: 0.03137254902, green: 0.5333333333, blue: 0.9725490196, alpha: 1)                 ,
                andFont   : UIFont(name: "Roboto-Medium", size: 30.0)!
            )
            
            changePinButton.setAttributedTitle(changePin, for: .normal)
            restorePurchaseButton.setAttributedTitle(restorePurchase, for: .normal)
        case .bezeliPhone, .bezelLessiPhone:
            let restorePurchase = Helper.underlineText(
                withTitle : "Restore Purchase"  ,
                andColor  : #colorLiteral(red: 0.2078431373, green: 0.2078431373, blue: 0.2078431373, alpha: 1)                  ,
                andFont   : UIFont(name: "Roboto-Regular", size: 14.0)!
            )
            
            let changePin = Helper.underlineText(
                withTitle : "Change Pin"       ,
                andColor  : #colorLiteral(red: 0.03137254902, green: 0.5333333333, blue: 0.9725490196, alpha: 1)                 ,
                andFont   : UIFont(name: "Roboto-Medium", size: 20.0)!
            )
            
            changePinButton.setAttributedTitle(changePin, for: .normal)
            restorePurchaseButton.setAttributedTitle(restorePurchase, for: .normal)
        }
        
        ///Switches size setup
        usePinSwitch.transform     = CGAffineTransform(scaleX: 0.75, y: 0.75)
        useTouchIdSwitch.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        
        ///howToUse View radius setup
        self.usePinView.layer.cornerRadius  = self.usePinView.frame.height/2
    }
    
    func probar(shouldHide flag: Bool) {
        if flag {
            probarHeight.constant = 0
            
            restorePurchaseButton.isHidden = true
        } else {
            probarHeight.constant = 52
            
            restorePurchaseButton.isHidden = false
        }
    }
    
    func openPinVC(forActionType action: Int, andLockType type: Int) {
        let addPinVC = AddPinVC(nibName: Constants.VCID.ADD_PIN, bundle: nil)
        
        addPinVC.action      = action
        addPinVC.appLockType = type
        
        self.navigationController?.pushViewController(addPinVC, animated: true)
    }
}

/* MARK:- Actions */
extension AppPinVC {
    @IBAction func didTapBack(_ sender: UISwitch) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func didTapUseTouchId(_ sender: UISwitch) {
        if sender.isOn {
            sender.thumbTintColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            
            if Constants.sharedInstance.appLockType == 0 {
                openPinVC(forActionType: 0, andLockType: 2)
            } else if Constants.sharedInstance.appLockType == 1 {
                Constants.sharedInstance.appLockType = 2
            }
        } else {
            sender.thumbTintColor = #colorLiteral(red: 0.4078431373, green: 0.9411764706, blue: 0.2745098039, alpha: 1)
            openPinVC(forActionType: 2, andLockType: 0)
        }
    }
    
    @IBAction func didTapUsePin(_ sender: UISwitch) {
        if sender.isOn {
            sender.thumbTintColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            
            openPinVC(forActionType: 0, andLockType: 1)
        } else {
            sender.thumbTintColor = #colorLiteral(red: 0.4078431373, green: 0.9411764706, blue: 0.2745098039, alpha: 1)
            
            openPinVC(forActionType: 2, andLockType: 0)
        }
    }
    
    @IBAction func didTapChangePin(_ sender: UIButton) {
        openPinVC(forActionType: 1, andLockType: Constants.sharedInstance.appLockType)
    }
    
    @IBAction func didTapGetPro(_ sender: UIButton) {
        let premiumVC = PremiumPopUp(nibName: Constants.VCID.PREMIUM_POPUP, bundle: nil)
        
        premiumVC.refrenceVC             = self
        premiumVC.fromVC                 = .appPinVC
        
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
