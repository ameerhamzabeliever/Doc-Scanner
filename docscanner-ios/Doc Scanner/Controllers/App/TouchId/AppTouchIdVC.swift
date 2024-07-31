//
//  AppTouchIdVC.swift
//  Doc Scanner
//
//  Created by Umar Farooq on 13/10/2020.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import UIKit
import LocalAuthentication

class AppTouchIdVC: UIViewController {
    
    /* MARK:- Properties */
    ///Haptic Feedback Generator
    let generator : UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(
        style: .heavy
    )
    
    /* MARK:- Life Cycle */
    override func viewDidLoad() {
        super.viewDidLoad()
        initVC()
    }

}

extension AppTouchIdVC {
    func initVC(){
        openTouchIdVC()
    }
    
    func openTouchIdVC() {
        let context = LAContext()
        var error   : NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Use your current touch id to unlock"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {
                [weak self] success, authenticationError in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if success {
                        self.goToDashBoard()
                    } else {
                        if let error = authenticationError?.localizedDescription {
                            
                            self.generator.impactOccurred()
                            
                            if error == "Fallback authentication mechanism selected." {
                                
                                self.goToPasscodeVC()
                                
                            } else if error != "Canceled by user." {
                                self.authFailedAlert(withError: error)
                            }

                        } else {
                            self.authFailedAlert()
                        }
                    }
                }
            }
        } else {
            let alert = UIAlertController(
                title          : "Biometrey Unavailable",
                message        : "Your device is not configured for biometric authentication.",
                preferredStyle : .alert
            )
            
            let okayAction = UIAlertAction(title: "OK", style: .default)
            
            alert.addAction(okayAction)
            present(alert, animated: true)
        }
    }
    
    func authFailedAlert(withError error: String = "Authentication failed"){
        let alert = UIAlertController(
            title          : APP_NAME,
            message        : error,
            preferredStyle : .alert
        )
        
        let okayAction = UIAlertAction(title: "OK", style: .default)
        
        alert.addAction(okayAction)
        self.present(alert, animated: true)
    }
    
    func goToDashBoard(){
        let baseVC = BaseVC(
            nibName: Constants.VCID.BASE,
            bundle: nil
        )
        
        self.navigationController?.pushViewController(baseVC, animated: true)
    }
    
    func goToPasscodeVC(){
        let appPasscodeVC = AppPasscodeVC(nibName: Constants.VCID.APP_PASSCODE, bundle: nil)
        
        self.navigationController?.pushViewController(appPasscodeVC, animated: true)
    }
}

/* MARK:- Actions */
extension AppTouchIdVC {
    @IBAction func didTapTouchId(_ sender: UIButton) {
        openTouchIdVC()
    }
    
    @IBAction func didTapPasscode(_ sender: UIButton) {
        goToPasscodeVC()
    }
}
