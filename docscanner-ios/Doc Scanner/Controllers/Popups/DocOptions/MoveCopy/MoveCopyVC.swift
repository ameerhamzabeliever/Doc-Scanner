//
//  MoveCopyVC.swift
//  Doc Scanner
//
//  Created by M Farhan on 8/10/20.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import UIKit

class MoveCopyVC: UIViewController {
    /* MARK:- IBOutlets  */
    @IBOutlet weak var containerView: UIView!
    
    /* MARK:- Properties */
    var docsVC      : DocsVC?
    var docFolderVC : DocFolderVC?
    
    /// Drag Drop Only Properties
    var file        : DocumentsModel = DocumentsModel()
    var folder      : DocumentsModel = DocumentsModel()
    var isDragDrop  : Bool           = false
        
    override func viewDidLoad() {
        super.viewDidLoad()
        initVC()
    }
    
    deinit {
        Helper.debugLogs(any: "Deinit Move Copy VC Successful")
    }
}

/* MARK:- Methods */
extension MoveCopyVC {
    func initVC(){
        containerView.layer.cornerRadius = containerView.frame.height * 0.12048193
    }
    
    func goToFolderListVC(to toggle: String){
        let folderListVC    = FolderListVC(nibName: Constants.VCID.FOLDER_LIST, bundle: nil)
        
        if let docsVC = docsVC {
            folderListVC.docsVC       = docsVC
            folderListVC.selectedDocs = docsVC.selectedDoc
        } else if let docFolderVC = self.docFolderVC {
            folderListVC.docFolderVC  = docFolderVC
            folderListVC.selectedDocs = docFolderVC.selectedFiles
        }
        
        folderListVC.toggle       = toggle
        
        folderListVC.modalTransitionStyle   = .coverVertical
        folderListVC.modalPresentationStyle = .overFullScreen
        
        self.dismiss(animated: true) { [weak self] in
            guard let self = self else {return}
            if let docsVC = self.docsVC {
                docsVC.present(folderListVC, animated: true, completion: nil)
            } else if let docFolderVC = self.docFolderVC {
                docFolderVC.present(folderListVC, animated: true, completion: nil)
            }
        }
    }
    
    /// Drag Drop Only
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
    
    func move(atFolder folderId: Int32, File file: DocumentsModel){
        CBFileManager.sharedInstance.upateData(
            withId      : file.id,
            forEntity   : DOCUMENTS,
            withEntries : ["folder_id": folderId]
        ) { [weak self] (completed) in
            guard let self = self else {return}
            
            if completed {
                self.dismiss(animated: true) {
                    if let docsVC = self.docsVC {
                        docsVC.didNeedsRefresh?()
                    }
                }
            }
        }
    }
}

/* MARK:- Actions */
extension MoveCopyVC {
    @IBAction func didTapCancel(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didTapMove(_ sender: UIButton) {
        if isDragDrop {
            move(atFolder: folder.id, File: file)
        } else {
            goToFolderListVC(to: "move")
        }
    }
    
    @IBAction func didTapCopy(_ sender: UIButton) {
        if isDragDrop {
            createCopyOfFile(atFolder: folder.id, ofFile: file)
        } else {
            goToFolderListVC(to: "copy")
        }
    }
}
