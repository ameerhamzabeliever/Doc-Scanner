//
//  NewFolderVC.swift
//  Doc Scanner
//
//  Created by M Farhan on 8/10/20.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import UIKit

class NewFolderVC: UIViewController {
    
    /* MARK:- IBOutlets  */
    @IBOutlet weak var titleLabel    : UILabel!
    @IBOutlet weak var subTitleLabel : UILabel!
    @IBOutlet weak var warningLabel  : UILabel!
    @IBOutlet weak var containerView : UIView!
    @IBOutlet weak var nameTextField : UITextField!
    
    /* MARK:- Properties */
    var entries : [String: Any] = [:]
    var refrence: DocsVC!
    
    /* MARK:- Lifecycle */
    override func viewDidLoad() {
        super.viewDidLoad()
        initView()
    }
    
    deinit {
        Helper.debugLogs(any: "New Folder VC Deinitilized")
    }
}

/* MARK:- Methods */
extension NewFolderVC {
    func initView(){
        containerView.layer.cornerRadius = containerView.frame.height * 0.13333333
        nameTextField.becomeFirstResponder()
    }
    
    func createFolder(withEntries entries: [String: Any]) {
        CBFileManager.sharedInstance.createData(
            withEntries : entries,
            forEntity   : DOCUMENTS
        ) { [weak self] (isCompleted) in
            
            guard let self = self else { return }
            
            if isCompleted {
                self.nameTextField.resignFirstResponder()
                self.dismiss(animated: true) {
                    self.refrence.didNeedsRefresh?()
                }
            } else {
                Helper.debugLogs(any: "Creating Folder", and: "Failed")
            }
            
        }
    }
}

/* MARK:- Actions */
extension NewFolderVC {
    @IBAction func didTapOk(_ sender: UIButton) {
        guard let folderName = nameTextField.text, folderName != "" else {
            warningLabel.isHidden = false
            return
        }
        nameTextField.text    = ""
        warningLabel.isHidden = true
        
        if let id = CBFileManager.sharedInstance.nextId(
            "id",
            forEntityName: DOCUMENTS
        ) as? Int32 {
            
            entries["id"]          = id
            entries["name"]        = folderName
            entries["type"]        = DataType.folder.rawValue
            entries["folder_id"]   = Int32(0)
            entries["password"]    = ""
            entries["created_at"]  = Date()
            
            createFolder(withEntries: entries)
        }
        
    }
    
    @IBAction func didTapCancel(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}
