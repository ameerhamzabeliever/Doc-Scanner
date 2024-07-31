//
//  PasscodeVC.swift
//  Doc Scanner
//
//  Created by M Farhan on 8/8/20.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import UIKit

class PasscodeVC: UIViewController {
    
    /* MARK:- IBOutlets  */
    @IBOutlet weak var titleLabel        : UILabel!
    @IBOutlet weak var warningLabel      : UILabel!
    @IBOutlet weak var subTitleLabel     : UILabel!
    @IBOutlet weak var containerView     : UIView!
    @IBOutlet weak var passwordTextField : UITextField!
    
    /* MARK:- Properties */
    var docsVC   : DocsVC!
    var folder   : DocumentsModel   = DocumentsModel()
    var folders  : [DocumentsModel] = []
    var entries  : [String: Any]    = [:]
    
    var password       : String = ""
    var isOpenFolder   : Bool   = false /// When the user try to open folder using password
    var isDeleteFolder : Bool   = false /// When a user try to delete locked folder
    var deleteIndex    : Int    = 0
    var isTouchId      : Bool   = false /// To see if we are here for the touch Id
    
    /* MARK:- Lifecycle */
    override func viewDidLoad() {
        super.viewDidLoad()
        initView()
    }

}

/* MARK:- Methods */
extension PasscodeVC {
    func initView(){
        containerView.layer.cornerRadius = containerView.frame.height * 0.13333333
        if isOpenFolder {
            titleLabel.text         = "Enter Passcode"
            subTitleLabel.text      = "Please enter your 4 digit passcode"
        } else if isDeleteFolder {
            titleLabel.text         = "Enter Passcode"
            subTitleLabel.text      = "Please enter '\(folder.name)' 4 digit passcode"
        }
    }
    
    func enterPasscode(){
        guard let password = passwordTextField.text, password != "" else {
            warningLabel.text     = "Password field can't be empty."
            warningLabel.isHidden = false
            return
        }
        
        if password.count != 4 {
            warningLabel.text     = "Password should be 4 digit."
            warningLabel.isHidden = false
            return
        }
        
        warningLabel.isHidden = true
        self.password         = password
        
        titleLabel.text         = "Re-enter Passcode"
        subTitleLabel.text      = "Please re-enter your 4 digit passcode"
        passwordTextField.text  = ""
    }
    
    func reEnterPasscode(){
        guard let confirmPassword = passwordTextField.text, confirmPassword != "" else {
            warningLabel.text     = "Confirm password field can't be empty."
            warningLabel.isHidden = false
            return
        }
        
        if self.password != confirmPassword {
            warningLabel.text     = "Password and confirm password doesn't match."
            warningLabel.isHidden = false
            return
        }
        
        warningLabel.isHidden = true
        
        
        entries["password"]  = self.password
        
        folders.enumerated().forEach { (index,folder) in
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
        }
    }
    
    func openFolder(){
        guard let password = passwordTextField.text, password != "" else {
            warningLabel.text     = "Password field can't be empty."
            warningLabel.isHidden = false
            return
        }
        
        if password != folder.password {
            warningLabel.text     = "Password doesn't match."
            warningLabel.isHidden = false
            passwordTextField.selectAll(nil)
            return
        }
        
        warningLabel.isHidden = true
        
        self.dismiss(animated: true) { [weak self] in
            guard let self = self else {return}
            
            self.docsVC.open(Folder: self.folder)
        }
    }
    
    func deleteFolder(){
        guard let password = passwordTextField.text, password != "" else {
            warningLabel.text     = "Password field can't be empty."
            warningLabel.isHidden = false
            return
        }
        
        if password != folder.password {
            warningLabel.text     = "Password doesn't match."
            warningLabel.isHidden = false
            passwordTextField.selectAll(nil)
            return
        }
        
        warningLabel.isHidden = true
        
        self.dismiss(animated: true) { [weak self] in
            guard let self = self else {return}
            
            self.docsVC.delete(FileFolder: self.folder, atIndex: self.deleteIndex)
        }
    }
}

/* MARK:- Actions */
extension PasscodeVC {
    @IBAction func didTapOk(_ sender: UIButton) {
        if isOpenFolder {
            openFolder()
        } else if isDeleteFolder {
            deleteFolder()
        } else {
            if isTouchId {
                if password == "" {
                    enterPasscode()
                } else {
                    entries["lock_type"] = 2
                    reEnterPasscode()
                }
            } else {
                if password == "" {
                    enterPasscode()
                } else {
                    entries["lock_type"] = 1
                    reEnterPasscode()
                }
            }
        }
    }
    
    @IBAction func didTapCancel(_ sender: UIButton) {
        if isDeleteFolder {
            self.dismiss(animated: true) { [weak self] in
                guard let self = self else {return}
                
                self.docsVC.delete(atIndex: self.deleteIndex + 1)
            }
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
}

/* MARK:- TextField */

///Delegate
extension PasscodeVC: UITextFieldDelegate {
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
