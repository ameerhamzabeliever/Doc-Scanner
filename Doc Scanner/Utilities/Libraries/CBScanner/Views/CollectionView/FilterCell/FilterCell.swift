//
//  FilterCell.swift
//  Doc Scanner
//
//  Created by M Farhan on 8/27/20.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import UIKit

class FilterCell: UICollectionViewCell {
    
    /* MARK:- IBOutlets */
    @IBOutlet weak var filterImageView: UIImageView!
    
    /* MARK:- Properties*/
    var image: UIImage? {
        didSet {
            configure()
        }
    }
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                layer.borderWidth = 2.0
            } else {
                layer.borderWidth = 0.0
            }
        }
    }
    
    /* MARK:- Life Cycle */
    override func prepareForReuse() {
        filterImageView.image = nil
        super.prepareForReuse()
    }
    
}

/* MARK:- Methods */
extension FilterCell {
    func configure() {
        if let image = image {
            layer.cornerRadius    = frame.height * 0.125
            layer.borderColor     = #colorLiteral(red: 0.03137254902, green: 0.5333333333, blue: 0.9725490196, alpha: 1)
            
            filterImageView.image = image
        }
    }
}
