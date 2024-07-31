//
//  AddPinVC.swift
//  Doc Scanner
//
//  Created by M Farhan on 8/10/20.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import UIKit

class AddPinVC: UIViewController {
    
    /* MARK:- IBOutlets  */
    @IBOutlet weak var pinTextField  : UITextField!
    @IBOutlet weak var subTitleLabel : UILabel!
    
    /* MARK:- IBOutlets Collection  */
    @IBOutlet var pinImages : [UIImageView]!
    
    /* MARK:- Properties */
    var pin         : String  = ""
    var action      : Int     = 0
    var confirmPin  : String  = ""
    var appLockType : Int     = 1
    
    ///Haptic Feedback Generator
    let generator : UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(
        style: .medium
    )
    
    /* MARK:- Lifecycle */
    override func viewDidLoad() {
        super.viewDidLoad()
        initVC()
    }

}

/* MARK:- Methods */
extension AddPinVC {
    func initVC() {
        pinTextField.becomeFirstResponder()
        
        if action == 0 {/// Create Lock
            subTitleLabel.text = "Enter 4 digits passcode"
        } else if action == 1 {/// Update Lock
            subTitleLabel.text = "Enter old 4 digits passcode"
        } else if action == 2 {/// Remove Lock
            subTitleLabel.text = "Enter old 4 digits passcode"
        }
    }
    
    func resetPins(){
        for pinImage in pinImages {
            pinImage.image = #imageLiteral(resourceName: "pin-unfilled")
        }
    }
    
    func createPin(){
        if subTitleLabel.text == "Enter 4 digits passcode" {
            self.pin = pinTextField.text ?? ""
            ///Setting up confirm view
            subTitleLabel.text = "Renter 4 digits passcode"
            for i in 0..<pin.count {
                pinImages[i].image = #imageLiteral(resourceName: "pin-unfilled")
            }
            
            ///Reset Textfield
            pinTextField.text = ""
        } else {
            ///Saving confirm pin
            self.confirmPin = pinTextField.text ?? ""
            
            guard self.pin == self.confirmPin else {
                ///Reset Confirm View
                self.showAlert(
                    title   : APP_NAME,
                    message : "Pin and Confirm pin doesn't match, Try again."
                )
                for i in 0..<pin.count {
                    pinImages[i].image = #imageLiteral(resourceName: "pin-unfilled")
                }
                pinTextField.text = ""
                
                return
            }
            
            Constants.sharedInstance.appLockType = self.appLockType
            Constants.sharedInstance.appPasscode = self.pin
            
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func updatePin(){
        if subTitleLabel.text == "Enter old 4 digits passcode" {
            self.pin = pinTextField.text ?? ""
            
            guard self.pin == Constants.sharedInstance.appPasscode! else {
                ///Reset Confirm View
                self.showAlert(
                    title   : APP_NAME,
                    message : "Pin doesn't match our records, Try again."
                )
                for i in 0..<pin.count {
                    pinImages[i].image = #imageLiteral(resourceName: "pin-unfilled")
                }
                pinTextField.text = ""
                
                return
            }
            
            subTitleLabel.text = "Enter new 4 digits passcode"
            
            for i in 0..<pin.count {
                pinImages[i].image = #imageLiteral(resourceName: "pin-unfilled")
            }
            
            pinTextField.text = ""
            
        } else if subTitleLabel.text == "Enter new 4 digits passcode" {
            self.pin = pinTextField.text ?? ""
            ///Setting up confirm view
            subTitleLabel.text = "Renter 4 digits passcode"
            for i in 0..<pin.count {
                pinImages[i].image = #imageLiteral(resourceName: "pin-unfilled")
            }
            
            ///Reset Textfield
            pinTextField.text = ""
        } else {
            ///Saving confirm pin
            self.confirmPin = pinTextField.text ?? ""
            
            guard self.pin == self.confirmPin else {
                ///Reset Confirm View
                self.showAlert(
                    title   : APP_NAME,
                    message : "Pin and Confirm pin doesn't match, Try again."
                )
                for i in 0..<pin.count {
                    pinImages[i].image = #imageLiteral(resourceName: "pin-unfilled")
                }
                pinTextField.text = ""
                
                return
            }
            
            Constants.sharedInstance.appLockType = self.appLockType
            Constants.sharedInstance.appPasscode = self.pin
            
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func removePin(){
        if subTitleLabel.text == "Enter old 4 digits passcode" {
            self.pin = pinTextField.text ?? ""
            
            guard self.pinTextField.text! == Constants.sharedInstance.appPasscode! else {
                ///Reset Confirm View
                self.showAlert(
                    title   : APP_NAME,
                    message : "Pin doesn't match our records, Try again."
                )
                for i in 0..<pin.count {
                    pinImages[i].image = #imageLiteral(resourceName: "pin-unfilled")
                }
                pinTextField.text = ""
                
                return
            }
            
            Constants.sharedInstance.appLockType = self.appLockType
            Constants.sharedInstance.appPasscode = nil
            
            self.navigationController?.popViewController(animated: true)
        }
    }
}

/* MARK:- Actions */
extension AddPinVC {
    @IBAction func didTapCancel(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func didChangeValue(_ sender: UITextField){
        generator.impactOccurred()
        if let pin = sender.text {
            resetPins()
            
            if pin.count < 5 {
                for i in 0..<pin.count {
                    pinImages[i].image = #imageLiteral(resourceName: "pin-filled")
                }
            }
            
            if pin.count == 4 {
                if action == 0 {/// Create Lock
                    createPin()
                } else if action == 1 {/// Update Lock
                    updatePin()
                } else if action == 2 {/// Remove Lock
                    removePin()
                }
            }
        }
    }
}
