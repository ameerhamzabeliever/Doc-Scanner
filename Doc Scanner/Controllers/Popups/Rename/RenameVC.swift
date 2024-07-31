//
//  RenameVC.swift
//  Doc Scanner
//
//  Created by Umar Farooq on 06/11/2020.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import UIKit

class RenameVC: UIViewController {

    /* MARK:- IBOutlets  */
    @IBOutlet weak var warningLabel  : UILabel!
    @IBOutlet weak var containerView : UIView!
    @IBOutlet weak var nameTextField : UITextField!
    
    /* MARK:- Properties */
    var entries  : [String: Any]  = [:]
    var document : DocumentsModel = DocumentsModel()
    
    var refrence: DocVC!
    
    /* MARK:- Lifecycle */
    override func viewDidLoad() {
        super.viewDidLoad()
        initView()
    }
    
    deinit {
        Helper.debugLogs(any: "Rename VC Deinitilized")
    }

}

/* MARK:- Methods */
extension RenameVC {
    func initView(){
        containerView.layer.cornerRadius = containerView.frame.height * 0.13333333
        nameTextField.becomeFirstResponder()
    }
}

/* MARK:- Actions */
extension RenameVC {
    @IBAction func didTapOk(_ sender: UIButton) {
        guard let folderName = nameTextField.text, folderName != "" else {
            warningLabel.isHidden = false
            return
        }
        nameTextField.text    = ""
        warningLabel.isHidden = true
        
        entries["name"]       = folderName
        
        CBFileManager.sharedInstance.upateData(
            withId      : document.id,
            forEntity   : DOCUMENTS  ,
            withEntries : entries
        ) { [weak self] isCompleted in
            guard let self = self else {return}
            
            if isCompleted {
                self.nameTextField.resignFirstResponder()
                self.dismiss(animated: true) {
                    self.refrence.nameLabel.text = folderName
                }
            } else {
                Helper.debugLogs(any: "Rename", and: "Failed")
            }
            
        }
        
    }
    
    @IBAction func didTapCancel(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}
