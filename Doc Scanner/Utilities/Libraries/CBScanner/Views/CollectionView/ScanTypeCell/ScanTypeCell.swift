//
//  ScanTypeCell.swift
//  Doc Scanner
//
//  Created by M Farhan on 8/27/20.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import UIKit

class ScanTypeCell: UICollectionViewCell {
    
    /* MARK:- IBoutlets */
    @IBOutlet weak var nameLabel: UILabel!
    
    /* MARK:- Properties */
    var name: String? {
        didSet {
            configure()
        }
    }
    
}

/* MARK:- Methods */
extension ScanTypeCell {
    func configure(){
        if let name = name {
            nameLabel.text = name
        }
    }
}
