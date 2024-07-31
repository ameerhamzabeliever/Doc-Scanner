//
//  UIVCExtension.swift
//  Route App
//
//  Created by Umar Farooq Nadeem on 6/13/20.
//  Copyright © 2020 People Talent Tech. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func showAlert(title: String = APP_NAME, message: String) {
        
        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        
        let oKAction = UIAlertAction(
            title   : "OK",
            style   : .default,
            handler : nil
        )
        
        alertController.addAction(oKAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func showSpinner(
        onView      : UIView,
        identifier  : String  = "Default",
        title       : String  = "Loading...",
        bgColor     : UIColor = #colorLiteral(red: 0.1803921569, green: 0.7647058824, blue: 0.9882352941, alpha: 0.5)
    ) {
        MAIN_QUEUE.async {
            let spinnerView = UIView.init(
                frame: onView.bounds
            )
            spinnerView.backgroundColor = bgColor
            
            var activityIndicator: UIActivityIndicatorView!
            
            if #available(iOS 13.0, *) {
                activityIndicator = UIActivityIndicatorView(style: .medium)
            } else {
                activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
            }
            
            activityIndicator.startAnimating()
            activityIndicator.center = spinnerView.center
            
            let lableY     = activityIndicator.frame.origin.y +                                       activityIndicator.frame.size.height
            
            let lableWidth = spinnerView.frame.width
            
            let lable = UILabel(
                frame: CGRect(
                    x      : 0.0       ,
                    y      : lableY    ,
                    width  : lableWidth,
                    height : 40
                )
            )
            
            lable.textColor     = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            lable.text          = title
            lable.textAlignment = .center
            lable.font          = UIFont(name: "Avenir Next Bold", size: 14.0)
            
            
            spinnerView.addSubview(lable)
            spinnerView.addSubview(activityIndicator)
            onView.addSubview(spinnerView)
            onView.bringSubviewToFront(spinnerView)
            
            spinnerView.accessibilityIdentifier = identifier
            SPINNER.append(spinnerView)
        }
    }
    
    func removeSpinner(identifier: String = "Default") {
        MAIN_QUEUE.async {
            for (index, spinner) in SPINNER.enumerated() {
                if spinner.accessibilityIdentifier == identifier {
                    spinner.removeFromSuperview()
                    if SPINNER.indices.contains(index){
                        SPINNER.remove(at: index)
                    }
                }
            }
        }
    }
}


/* MARK:- Application Specifics */
extension UIViewController {
    func presentPremiumVC(fromVC type: VCToBeUpdated, andRefrence refrence: Any){
        let premiumVC = PremiumPopUp(nibName: Constants.VCID.PREMIUM_POPUP, bundle: nil)

        premiumVC.fromVC = type
        
        switch type {
        case .docVC:
            premiumVC.refrenceVC = refrence as? DocVC
        case .docsVC:
            premiumVC.refrenceVC = refrence as? DocsVC
        case .settingsVC:
            premiumVC.refrenceVC = refrence as? SettingsVC
        case .appPinVC:
            premiumVC.refrenceVC = refrence as? AppPinVC
        case .startAppWithVC:
            premiumVC.refrenceVC = refrence as? StartAppWithVC
        case .pictureQualityVC:
            premiumVC.refrenceVC = refrence as? PictureQualityVC
        case .scanningOptionsVC:
            premiumVC.refrenceVC = refrence as? ScanningOptions
        }
        
        premiumVC.modalTransitionStyle   = .coverVertical
        premiumVC.modalPresentationStyle = .overFullScreen
        
        present(premiumVC, animated: true, completion: nil)
    }
    
    func presentCongratulationVC(){
        let congratulationVC = CongratulationVC(nibName: Constants.VCID.CONGRATULATION, bundle: nil)
        
        congratulationVC.modalTransitionStyle   = .coverVertical
        congratulationVC.modalPresentationStyle = .overFullScreen
        
        present(congratulationVC, animated: true, completion: nil)
    }
}
