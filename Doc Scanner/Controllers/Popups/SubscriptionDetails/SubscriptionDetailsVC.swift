//
//  SubscriptionDetailsVC.swift
//  Doc Scanner
//
//  Created by M Farhan on 8/15/20.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import UIKit

class SubscriptionDetailsVC: UIViewController {

    /* MARK:- IBOutlets  */
    @IBOutlet weak var privacyPolicyButton   : UIButton!
    @IBOutlet weak var termsOfServicesButton : UIButton!
    
    /* MARK:- Lifecycle */
    override func viewDidLoad() {
        super.viewDidLoad()
        initVC()
    }

}

/* MARK:- Methods */
extension SubscriptionDetailsVC {
    func initVC(){
        ///Setup button attributed text setup
        switch Helper.device() {
        case .iPad:
            let privacyPolicy = Helper.underlineText(
                withTitle : "Privacy policy" ,
                andColor  : #colorLiteral(red: 0.2549019608, green: 0.2549019608, blue: 0.2549019608, alpha: 1)               ,
                andFont   : UIFont(name: "Roboto-Regular", size: 22.0)!
            )
            
            let termsOfServices = Helper.underlineText(
                withTitle : "Terms of service",
                andColor  : #colorLiteral(red: 0.2549019608, green: 0.2549019608, blue: 0.2549019608, alpha: 1)                ,
                andFont   : UIFont(name: "Roboto-Regular", size: 22.0)!
            )
                        
            privacyPolicyButton.setAttributedTitle(privacyPolicy    , for: .normal)
            termsOfServicesButton.setAttributedTitle(termsOfServices, for: .normal)
        case .bezeliPhone, .bezelLessiPhone:
            let privacyPolicy = Helper.underlineText(
                withTitle : "Privacy policy",
                andColor  : #colorLiteral(red: 0.2549019608, green: 0.2549019608, blue: 0.2549019608, alpha: 1)              ,
                andFont   : UIFont(name: "Roboto-Regular", size: 14.0)!
            )
            
            let termsOfServices = Helper.underlineText(
                withTitle : "Terms of service",
                andColor  : #colorLiteral(red: 0.2549019608, green: 0.2549019608, blue: 0.2549019608, alpha: 1)                ,
                andFont   : UIFont(name: "Roboto-Regular", size: 14.0)!
            )
                        
            privacyPolicyButton.setAttributedTitle(privacyPolicy    , for: .normal)
            termsOfServicesButton.setAttributedTitle(termsOfServices, for: .normal)
        }
    }
}

/* MARK:- Actions */
extension SubscriptionDetailsVC {
    @IBAction func didTapCross(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}
