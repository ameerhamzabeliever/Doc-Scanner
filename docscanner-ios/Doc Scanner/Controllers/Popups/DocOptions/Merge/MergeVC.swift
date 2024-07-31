//
//  MergeVC.swift
//  Doc Scanner
//
//  Created by M Farhan on 8/10/20.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import UIKit

class MergeVC: UIViewController {
    /* MARK:- IBOutlets  */
    @IBOutlet weak var containerView: UIView!
    
    /* MARK:- Properties */
    var docsVC       : DocsVC?
    var docFolderVC  : DocFolderVC?
    
    var folderId     : Int32            = 0
    var selectedDocs : [DocumentsModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initVC()
    }
}

/* MARK:- Methods */
extension MergeVC {
    func initVC(){
        containerView.layer.cornerRadius = containerView.frame.height * 0.12048193
    }
    
    func mergeDocs(_ folderId: Int32, _ pages: [PagesModel]){
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
                guard let _ = self else { return }
                
                if isCompleted {
                    for (index, page) in pages.enumerated() {
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
                                            if index == pages.count - 1 {
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
    
    func deleteOldDocs(_ document: DocumentsModel){
        if document.type == DataType.folder.rawValue {
            CBFileManager.sharedInstance.deleteData(
                key     : "id",
                value   : document.id,
                entity  : DOCUMENTS
            ) { _ in }
        } else {
            CBFileManager.sharedInstance.deleteData(
                key     : "id",
                value   : document.id,
                entity  : DOCUMENTS
            ) { (isFinished) in
                
                if isFinished {
                    for page in document.pages {
                        ///Deleting Pages In PDF
                        CBFileManager.sharedInstance.deleteData(
                            key   : "id",
                            value : page.id,
                            entity: PAGES
                        ) { (isFinished) in
                            
                            if isFinished {
                                ///Deleting Quad of the Page
                                CBFileManager.sharedInstance.deleteData(
                                    key   : "id",
                                    value : page.quad.id,
                                    entity: QUADS
                                ) { _ in }
                            }
                        }
                    }
                }
            }
        }
    }
}

/* MARK:- Actions */
extension MergeVC {
    @IBAction func didTapCancel(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didTapMergeButNotKeepOldDocs(_ sender: UIButton) {
        if let _ = docsVC {
            var pages: [PagesModel] = []
            selectedDocs.forEach { (document) in
                deleteOldDocs(document)
                document.pages.forEach { (page) in
                    pages.append(page)
                }
            }
            
            mergeDocs(Int32(0), pages)
        } else if let _ = docFolderVC {
            var pages: [PagesModel] = []
            selectedDocs.forEach { (document) in
                deleteOldDocs(document)
                document.pages.forEach { (page) in
                    pages.append(page)
                }
            }
            
            mergeDocs(folderId, pages)
        }

    }
    
    @IBAction func didTapMergeAndKeepOldDocs(_ sender: UIButton) {
        if let _ = docsVC {
            var pages: [PagesModel] = []
            selectedDocs.forEach { (document) in
                document.pages.forEach { (page) in
                    pages.append(page)
                }
            }
            
            mergeDocs(Int32(0), pages)
        } else if let _ = docFolderVC {
            var pages: [PagesModel] = []
            selectedDocs.forEach { (document) in
                document.pages.forEach { (page) in
                    pages.append(page)
                }
            }
            
            mergeDocs(folderId, pages)
        }
    }
    
}
