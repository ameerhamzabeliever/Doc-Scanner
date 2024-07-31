//
//  FolderListVC.swift
//  Doc Scanner
//
//  Created by Umar Farooq on 22/09/2020.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import UIKit

class FolderListVC: UIViewController {

    /* MARK:- IBOutlets */
    @IBOutlet weak var tableView     : UITableView!
    
    @IBOutlet weak var containerView : UIView!
    
    /* MARK:- Layout Constraints */
    @IBOutlet weak var contentViewHeightConstraint: NSLayoutConstraint!
    
    /* MARK:- Lazy Properties */
    lazy var folderListNib: UINib = {
        return UINib(nibName: Constants.cellNib.FOLDER_LIST, bundle: nil)
    }()
    
    var viewMaxHeight: CGFloat {
        get {
            return SCREEN_HEIGHT * 0.6
        }
    }
    
    var tableViewPreferredContentSize: CGSize {
        get {
            self.tableView.layoutIfNeeded()
            return self.tableView.contentSize
        }
    }
    
    /* MARK:- Properties */
    var docsVC       : DocsVC?
    var docFolderVC  : DocFolderVC?
    
    var toggle       : String           = "" /// Flag to choose between move/copy
    var keyVal       : [String: String] = ["type" : DataType.folder.rawValue]
    var folders      : [DocumentsModel] = []
    var selectedDocs : [DocumentsModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initVC()
    }

}

/* MARK:- Methods */
extension FolderListVC {
    func initVC(){
        containerView.layer.cornerRadius = containerView.frame.height * 0.12048193
        registerNib()
    }
    
    func registerNib() {
        tableView.register(
            folderListNib,
            forCellReuseIdentifier: Constants.cellNib.FOLDER_LIST
        )
        getFilesAndFolders()
    }
    
    func getFilesAndFolders(){
        folders.removeAll()///Removing old data inorder to overcome redundancy
        
        folders = CBFileManager.sharedInstance.retrieveFilesFolders(
            shouldAddCondition: true,
            withKeyAndValue   : keyVal,
            ofType            : nil
        )
        
        if let _ = self.docFolderVC {/// Adding Root Folder if file is to be moved from within a folder
            folders.insert(DocumentsModel(), at: 0)
        }
        
        self.tableView.reloadData()
        
        MAIN_QUEUE.asyncAfter(deadline: .now() + 0.05) {
            let height = self.tableViewPreferredContentSize.height
            
            if height < self.viewMaxHeight {
                self.contentViewHeightConstraint.constant = height + 76
            } else {
                self.contentViewHeightConstraint.constant = self.viewMaxHeight
            }
        }
    }
    
    func createCopyOfFile(atFolder folderId: Int32, ofFile file: DocumentsModel){
        if let documentId = CBFileManager.sharedInstance.nextId(
            "id",
            forEntityName: DOCUMENTS
        ) as? Int32 {
            var entries : [String: Any] = [:]
            entries["id"]               = documentId
            entries["type"]             = DataType.file.rawValue
            entries["name"]             = "PDF - \(documentId)"
            entries["folder_id"]        = folderId
            entries["password"]         = ""
            entries["created_at"]       = Date()
            
            CBFileManager.sharedInstance.createData(
                withEntries : entries,
                forEntity   : DOCUMENTS
            ) { [weak self] (isCompleted) in
                guard let self = self else { return }
                
                if isCompleted {
                    for (index,page) in file.pages.enumerated() {
                        ///Saving Page
                        if let pageId = CBFileManager.sharedInstance.nextId(
                            "id",
                            forEntityName: PAGES
                        ) as? Int32 {
                            var entries : [String: Any] = [:]
                            entries["id"]               = pageId
                            entries["file_id"]          = documentId
                            entries["original_image"]   = page.originalImage
                            entries["cropped_image"]    = page.croppedImage
                            entries["enhanced_image"]   = page.enhancedImage
                            entries["scanner_type"]     = page.scannerType
                            entries["page_size"]        = page.pageSize
                            
                            CBFileManager.sharedInstance.createData(
                                withEntries : entries,
                                forEntity   : PAGES
                            ) { (isFinished) in
                                
                                if isFinished {
                                    ///Saving Quads
                                    if let quadId = CBFileManager.sharedInstance.nextId(
                                        "id",
                                        forEntityName: QUADS
                                    ) as? Int32 {
                                        var entries : [String: Any] = [:]
                                        entries["id"]             = quadId
                                        entries["page_id"]        = documentId
                                        entries["top_left_x"]     = page.quad.topLeft.x
                                        entries["top_left_y"]     = page.quad.topLeft.y
                                        entries["top_right_x"]    = page.quad.topRight.x
                                        entries["top_right_y"]    = page.quad.topRight.y
                                        entries["bottom_left_x"]  = page.quad.bottomLeft.x
                                        entries["bottom_left_y"]  = page.quad.bottomLeft.y
                                        entries["bottom_right_x"] = page.quad.bottomRight.x
                                        entries["bottom_right_y"] = page.quad.bottomRight.y
                                        
                                        CBFileManager.sharedInstance.createData(
                                            withEntries : entries,
                                            forEntity   : QUADS
                                        ) { [weak self] (isFinished) in
                                            guard let self = self else {return}
                                            ///Dismissing View
                                            if index == file.pages.count - 1 {
                                                self.dismiss(animated: true) {
                                                    if let docsVC = self.docsVC {
                                                        docsVC.didNeedsRefresh?()
                                                    } else if let docFolderVC = self.docFolderVC {
                                                        docFolderVC.didNeedsRefresh?()
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
}

/* MARK:- Actions */
extension FolderListVC {
    @IBAction func didTapCancel(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}

/* MARK:- Table View */
///Datasource
extension FolderListVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return folders.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: Constants.cellNib.FOLDER_LIST
        ) as! FolderListCell
        
        let index   = indexPath.row
        cell.folder = folders[index]
        
        return cell
    }
}
///Delegate
extension FolderListVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let index    = indexPath.row
        let folderId = folders[index].id
        
        if toggle == "move" {
            selectedDocs.enumerated().forEach { (index,doc) in
                CBFileManager.sharedInstance.upateData(
                    withId      : doc.id,
                    forEntity   : DOCUMENTS,
                    withEntries : ["folder_id": folderId]
                ) { [weak self] (completed) in
                    guard let self = self else {return}
                    
                    if completed {
                        if index == self.selectedDocs.count - 1 {
                            self.dismiss(animated: true) {
                                if let docsVC = self.docsVC {
                                    docsVC.didNeedsRefresh?()
                                } else if let docFolderVC = self.docFolderVC {
                                    docFolderVC.didNeedsRefresh?()
                                }
                            }
                        }
                    }
                }
            }
        } else {
            selectedDocs.forEach { (doc) in
                if doc.id != 0 {
                    createCopyOfFile(atFolder: folderId, ofFile: doc)
                }
            }
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return SCREEN_HEIGHT * 0.05022321
    }
}
