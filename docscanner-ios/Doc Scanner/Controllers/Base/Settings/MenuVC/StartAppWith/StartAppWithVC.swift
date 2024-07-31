//
//  StartAppWithVC.swift
//  Doc Scanner
//
//  Created by M Farhan on 8/10/20.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import UIKit

class StartAppWithVC: UIViewController {

    /* MARK:- IBOutlets */
    @IBOutlet weak var proBarView            : UIView!
    @IBOutlet weak var restorePurchaseButton : UIButton!
    
    /* MARK:- IBOutlet Collection  */
    @IBOutlet var optionsViews : [UIView]!
    @IBOutlet var buttonLabels : [UILabel]!
    
    /* MARK:- NSLayout Constraints */
    @IBOutlet weak var probarHeight : NSLayoutConstraint!
    
    /* MARK:- Life Cycle */
    override func viewDidLoad() {
        super.viewDidLoad()
        initVC()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        probar(shouldHide: Constants.sharedInstance.isPremiumUser)
    }

}

/* MARK:- Methods */
extension StartAppWithVC {
    func initVC(){
        ///ProBar View Design Setup
        MAIN_QUEUE.asyncAfter(deadline: .now() + 0.05) {
            self.proBarView.layer.cornerRadius = self.proBarView.frame.height / 2.0
        }
        
        for view in optionsViews {
            view.layer.cornerRadius = view.frame.height / 2
        }
        
        /// Setup Selected Button
        buttonLabels.forEach { (label) in
            if label.accessibilityIdentifier == Constants.sharedInstance.startAppWith {
                label.textColor = #colorLiteral(red: 0.03137254902, green: 0.5333333333, blue: 0.9725490196, alpha: 1)
            } else {
                label.textColor = #colorLiteral(red: 0.4392156863, green: 0.4392156863, blue: 0.4392156863, alpha: 1)
            }
        }
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
}

/* MARK:- Actions */
extension StartAppWithVC {
    @IBAction func didTapBack(_ sender: UISwitch) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func didTapGetPro(_ sender: UIButton) {
        let premiumVC = PremiumPopUp(nibName: Constants.VCID.PREMIUM_POPUP, bundle: nil)
        
        premiumVC.refrenceVC             = self
        premiumVC.fromVC                 = .startAppWithVC
        
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
    
    @IBAction func toggleStartAppWith(_ sender: UIButton) {
        buttonLabels.forEach { (label) in
            if label.accessibilityIdentifier == sender.accessibilityIdentifier {
                label.textColor = #colorLiteral(red: 0.03137254902, green: 0.5333333333, blue: 0.9725490196, alpha: 1)
            } else {
                label.textColor = #colorLiteral(red: 0.4392156863, green: 0.4392156863, blue: 0.4392156863, alpha: 1)
            }
        }
        
        Constants.sharedInstance.startAppWith = sender.accessibilityIdentifier ?? "medium"
    }
}
