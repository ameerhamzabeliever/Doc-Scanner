//
//  DocOptions.swift
//  Doc Scanner
//
//  Created by M Farhan on 8/7/20.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import UIKit

class DocsOptions: UIView {
    /* MARK:- IBOutlets  */
    @IBOutlet weak var gradientView       : UIView!
    @IBOutlet weak var lockCrownImageView : UIImageView!
    
    @IBOutlet weak var unlockImage  : UIImageView!
    @IBOutlet weak var unlockLabel  : UILabel!
    @IBOutlet weak var unlockButton : UIButton!

    @IBOutlet weak var lockImage    : UIImageView!
    @IBOutlet weak var lockLabel    : UILabel!
    @IBOutlet weak var lockButton   : UIButton!

    /* MARK:- Properties */
    var refrenceVC : BaseVC!
    var docsVC     : DocsVC!
    var colors     : [CGColor] = [#colorLiteral(red: 0.03137254902, green: 0.6117647059, blue: 0.9725490196, alpha: 1).cgColor, #colorLiteral(red: 0.03137254902, green: 0.5176470588, blue: 0.9725490196, alpha: 1).cgColor]
}

/* MARK:- Methods */
extension DocsOptions {
    func initView() {
        MAIN_QUEUE.asyncAfter(deadline: .now() + 0.05) {
            ///Setting Up Gradient
            let gradientLayer = Helper.getGradientLayer(
                inView      : self.gradientView,
                withColors  : self.colors,
                atLocations : [0.0, 1.0]
            )
            
            self.gradientView.layer.addSublayer(gradientLayer)
            
            self.setCrownImage(forPremiumUser: Constants.sharedInstance.isPremiumUser)
        }
    }
    
    func show(LockOption flag: Bool) {
        if flag {
            unlockImage.isHidden  = true
            unlockLabel.isHidden  = true
            unlockButton.isHidden = true
            
            lockImage.isHidden    = false
            lockLabel.isHidden    = false
            lockButton.isHidden   = false
        } else {
            unlockImage.isHidden  = false
            unlockLabel.isHidden  = false
            unlockButton.isHidden = false
            
            lockImage.isHidden    = true
            lockLabel.isHidden    = true
            lockButton.isHidden   = true
        }
    }
    
    func lockUnlockOption(isEnabled flag: Bool){
        lockImage.image   = lockImage.image?.withRenderingMode(.alwaysTemplate)
        unlockImage.image = unlockImage.image?.withRenderingMode(.alwaysTemplate)
        
        if flag {
            lockImage.tintColor = .white
            lockLabel.textColor = .white
            
            unlockImage.tintColor = .white
            unlockLabel.textColor = .white
        } else {
            lockImage.tintColor = .gray
            lockLabel.textColor = .gray
            
            unlockImage.tintColor = .gray
            unlockLabel.textColor = .gray
        }
        
        lockButton.isUserInteractionEnabled   = flag
        unlockButton.isUserInteractionEnabled = flag
    }
    
    func setCrownImage(forPremiumUser isPremium: Bool) {
        lockCrownImageView.isHidden = isPremium
    }
    
    func verifyPurchase(){
        docsVC.showSpinner(onView: docsVC.view)
        if let rawValue = Constants.sharedInstance.purchasedIdentifier {
            if let identifier = IAPIdentifiers(rawValue: rawValue) {
                IAPManager.sharedInstance.verifyReceipt(withIdentifier: identifier) { [weak self] state in
                    guard let self = self else { return }
                    
                    self.docsVC.removeSpinner()
                    
                    switch state {
                    case .purchased:
                        self.docsVC.didTapUnlockButton?()
                    case .expired, .notPurchased:
                        self.docsVC.presentPremiumVC(fromVC: .docsVC, andRefrence: self.docsVC as Any)
                    }
                }
            } else {
                docsVC.removeSpinner()
                setCrownImage(forPremiumUser: false)
                docsVC.presentPremiumVC(fromVC: .docsVC, andRefrence: self.docsVC as Any)
            }
        } else {
            docsVC.removeSpinner()
            setCrownImage(forPremiumUser: false)
            docsVC.presentPremiumVC(fromVC: .docsVC, andRefrence: self.docsVC as Any)
        }
    }
}

/* MARK:- Actions */
extension DocsOptions {
    @IBAction func didTapUnlock(_ sender: UIButton) {
        #if DEBUG
        docsVC.didTapUnlockButton?()
        #else
        if Constants.sharedInstance.isPremiumUser {
            if let expiryDate = Constants.sharedInstance.subscriptionExpiryDate {
                if Date() < expiryDate {
                    docsVC.didTapUnlockButton?()
                } else {
                    setCrownImage(forPremiumUser: false)
                    Constants.sharedInstance.isPremiumUser = false
                    docsVC.presentPremiumVC(fromVC: .docsVC, andRefrence: docsVC as Any)
                }
            } else {
                verifyPurchase()
            }
        } else {
            setCrownImage(forPremiumUser: false)
            docsVC.presentPremiumVC(fromVC: .docsVC, andRefrence: docsVC as Any)
        }
        #endif
    }
    
    @IBAction func didTapLock(_ sender: UIButton) {
        docsVC.didTapLockButton?()
    }
    
    @IBAction func didTapMerge(_ sender: UIButton) {
        docsVC.didTapMergeButton?()
    }
    
    @IBAction func didTapMoveCopy(_ sender: UIButton) {
        docsVC.didTapMoveCopyButton?()
    }
    
    @IBAction func didTapDelete(_ sender: UIButton) {
        let deleteVC = DeleteVC(nibName: Constants.VCID.DELETE, bundle: nil)
        
        deleteVC.modalPresentationStyle = .overFullScreen
        deleteVC.modalTransitionStyle   = .coverVertical
        
        deleteVC.docsVC                 = docsVC
        
        self.parentVC?.present(deleteVC, animated: true, completion: nil)
    }

}
