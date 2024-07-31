//
//  UnlockVC.swift
//  Doc Scanner
//
//  Created by Umar Farooq on 29/09/2020.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import UIKit

class UnlockVC: UIViewController {

    /* MARK:- IBOutlets  */
    @IBOutlet weak var warningLabel      : UILabel!
    @IBOutlet weak var containerView     : UIView!
    @IBOutlet weak var passwordTextField : UITextField!
    
    /* MARK:- Properties */
    var docsVC   : DocsVC!
    var folders  : [DocumentsModel] = []
    var entries  : [String: Any]    = [:]
    
    /* MARK:- Lifecycle */
    override func viewDidLoad() {
        super.viewDidLoad()
        initView()
    }

}

/* MARK:- Methods */
extension UnlockVC {
    func initView(){
        containerView.layer.cornerRadius = containerView.frame.height * 0.13333333
    }
    
    func unlockFolder(){
        guard let password = passwordTextField.text, password != "" else {
            warningLabel.text     = "Password field can't be empty."
            warningLabel.isHidden = false
            return
        }
        
        warningLabel.isHidden = true

        entries["lock_type"] = 0
        entries["password"]  = ""
        
        folders.enumerated().forEach { (index,folder) in
            if password == folder.password {
                CBFileManager.sharedInstance.upateData(
                    withId      : folder.id,
                    forEntity   : DOCUMENTS,
                    withEntries : entries
                ) { [weak self] (isCompleted) in
                    guard let self = self else {return}
                    
                    if isCompleted {
                        if index == self.folders.count - 1 {
                            self.dismiss(animated: true) {
                                self.docsVC.didNeedsRefresh?()
                            }
                        }
                    }
                }
            } else {
                warningLabel.text     = "Password doesn't match."
                warningLabel.isHidden = false
            }
        }
    }
    
}

/* MARK:- Actions */
extension UnlockVC {
    @IBAction func didTapOk(_ sender: UIButton) {
        unlockFolder()
    }
    
    @IBAction func didTapCancel(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}

/* MARK:- TextField */

///Delegate
extension UnlockVC: UITextFieldDelegate {
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        
        let maxLength                = 4
        let currentString : NSString = (textField.text ?? "") as NSString
        let newString     : NSString = currentString.replacingCharacters(
                                           in   : range,
                                           with : string
                                       ) as NSString
        
        return newString.length <= maxLength
        
    }
}
