//
//  CBImagePickerAlbumCell.swift
//  Doc Scanner
//
//  Created by Umar Farooq on 02/11/2020.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import UIKit

class CBImagePickerAlbumCell: UICollectionViewCell {
    
    /* MARK:- IBOutlets */
    @IBOutlet weak var nameLabel     : UILabel!
    @IBOutlet weak var containerView : UIView!
    
    /* MARK:- Properties */
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
}

/* MARK:- Methods */
extension CBImagePickerAlbumCell {
    func setup(){
        MAIN_QUEUE.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self = self else { return }
            self.containerView.layer.cornerRadius = 10
        }
    }
    
    func setSelected(){
        if isSelected {
            nameLabel.textColor           = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            containerView.backgroundColor = #colorLiteral(red: 0.03137254902, green: 0.568627451, blue: 0.9725490196, alpha: 1)
        } else {
            nameLabel.textColor           = #colorLiteral(red: 0.3882352941, green: 0.3882352941, blue: 0.3882352941, alpha: 1)
            containerView.backgroundColor = #colorLiteral(red: 0.9764705882, green: 0.9764705882, blue: 0.9764705882, alpha: 1)
        }
    }
}
