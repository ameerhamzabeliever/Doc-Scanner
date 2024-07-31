//
//  DocFolderCell.swift
//  Doc Scanner
//
//  Created by M Farhan on 8/18/20.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import UIKit

class DocFolderCell: UICollectionViewCell {

    /* MARK:- IBOutlets */
    @IBOutlet weak var ImageV          : UIImageView!
    @IBOutlet weak var selectionBtn    : UIButton!
    @IBOutlet weak var selectionimageV : UIImageView!
    
    /* MARK:- Properties */
    var document: DocumentsModel? {
        didSet {
            configureCell()
        }
    }
    
    /// Flag to check if multiple
    /// selection option is enabled
    var multiSelect: Bool = false
    /// Flag for check if doc is
    /// selected
    var isChecked  : Bool = false
    var index      : Int  = 0
    
    /* MARK:- Closure */
    var didTap        : ((_ index: Int)->())?
    
    var didSelect     : ((
        _ document    : DocumentsModel ,
        _ index       : Int            ,
        _ isSelected  : Bool
    )->())?
    
    var didTapAndHold : (()->())?

}

/* MARK:- Methods */
extension DocFolderCell {
    func configureCell() {
        ImageV.backgroundColor = #colorLiteral(red: 0.2274509804, green: 0.7607843137, blue: 0.9803921569, alpha: 0.1)
        
        if let data = self.document?.pages.first?.croppedImage {
            ImageV.image  = UIImage(data: data)
        } else {
            ImageV.image  = #imageLiteral(resourceName: "document-image")
        }
        
        selectionBtn.isHidden    = !multiSelect
        selectionimageV.isHidden = !multiSelect
        
        let tapSelector = #selector(didTapCell(_:))
        let tapGesture  = UITapGestureRecognizer(
            target: self,
            action: tapSelector
        )
        
        let tapAndHoldSelector = #selector(didTapAndHoldCell(_:))
        let tapAndHoldGesture  = UILongPressGestureRecognizer(
            target: self,
            action: tapAndHoldSelector
        )
        
        addGestureRecognizer(tapGesture)
        addGestureRecognizer(tapAndHoldGesture)
    }
}

/* MARK:- Actions */
extension DocFolderCell {
    @IBAction func selectionToggle(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        
        if sender.isSelected {
            selectionimageV.image = UIImage(named: "radio-seleced")
        } else {
            selectionimageV.image = UIImage(named: "radio-unselected")
        }
        
        if let document = self.document {
            didSelect?(document, index, sender.isSelected)
        }
    }
}

/* MARK:- obj-c interface */
extension DocFolderCell {
    @objc func didTapCell(_ sender: UITapGestureRecognizer) {
        didTap?(index)
    }
    
    @objc func didTapAndHoldCell(_ sender: UILongPressGestureRecognizer) {
        didTapAndHold?()
    }
}
