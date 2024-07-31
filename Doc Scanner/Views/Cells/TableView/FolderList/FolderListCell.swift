//
//  FolderListCell.swift
//  Doc Scanner
//
//  Created by Umar Farooq on 22/09/2020.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import UIKit

class FolderListCell: UITableViewCell {
    
    /* MARK:- IBOutlet */
    @IBOutlet weak var folderNameLabel: UILabel!
    
    /* MARK:- Properties */
    var folder: DocumentsModel? {
        didSet {
            configure()
        }
    }
    
}

extension FolderListCell {
    func configure(){
        if let folder = folder {
            folderNameLabel.text = folder.name
        }
    }
}
