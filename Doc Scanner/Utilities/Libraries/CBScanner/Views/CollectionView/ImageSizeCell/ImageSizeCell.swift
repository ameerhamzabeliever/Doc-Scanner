//
//  PDFSizeCell.swift
//  Doc Scanner
//
//  Created by M Farhan on 8/26/20.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import UIKit

class ImageSizeCell: UICollectionViewCell {

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
extension ImageSizeCell {
    func configure(){
        if let name = name {
            nameLabel.text = name
        }
    }
}
