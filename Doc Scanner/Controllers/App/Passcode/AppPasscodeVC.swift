//
//  AppPasscodeVC.swift
//  Doc Scanner
//
//  Created by Umar Farooq on 13/10/2020.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import UIKit

class AppPasscodeVC: UIViewController {

    /* MARK:- IBOutlet */
    @IBOutlet weak var backButton    : UIButton!
    @IBOutlet weak var pinTextField  : UITextField!
    @IBOutlet weak var backImageView : UIImageView!
    
    /* MARK:- IBOutlets Collection  */
    @IBOutlet var pinImages : [UIImageView]!
    
    /* MARK:- Properties */
    var pin             : String = ""
    var isFromTouchIdVC : Bool   = false
    
    ///Haptic Feedback Generator
    let generator : UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(
        style: .medium
    )
    
    /* MARK:- Life Cycle */
    override func viewDidLoad() {
        super.viewDidLoad()
        initVC()
    }

}

/* MARK:- Methods */
extension AppPasscodeVC {
    func initVC(){
        backButton.isHidden    = !isFromTouchIdVC
        backImageView.isHidden = !isFromTouchIdVC
        
        pinTextField.becomeFirstResponder()
    }
    
    func goToDashBoard(){
        pinTextField.resignFirstResponder()
        
        let baseVC = BaseVC(
            nibName: Constants.VCID.BASE,
            bundle: nil
        )
        
        self.navigationController?.pushViewController(baseVC, animated: true)
    }
    
    func resetPins(){
        for pinImage in pinImages {
            pinImage.image = #imageLiteral(resourceName: "pin-unfilled")
        }
    }
}

extension AppPasscodeVC {
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
                
                goToDashBoard()
            }
        }
    }
    
    @IBAction func didTapBack(_ sender: UIButton) {
        pinTextField.resignFirstResponder()
        self.navigationController?.popViewController(animated: true)
    }
}
