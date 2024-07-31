//
//  CBImagePickerCell.swift
//  Doc Scanner
//
//  Created by Umar Farooq on 02/11/2020.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import UIKit

class CBImagePickerCell: UICollectionViewCell {

    /* MARK:- IBOutlets */
    @IBOutlet weak var assetImageView     : UIImageView!
    @IBOutlet weak var selectionLabel     : UILabel!
    @IBOutlet weak var selectionImageView : UIImageView!

    /* MARK:- Life Cycle */
    override func prepareForReuse() {
        selectionLabel.text         = ""
        assetImageView.image        = nil
        selectionImageView.isHidden = true
    }
}

extension CBImagePickerCell {
    func setSelected() {
        if isSelected {
            selectionImageView.isHidden = false
        } else {
            selectionImageView.isHidden = true
        }
    }
}
