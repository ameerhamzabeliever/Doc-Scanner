//
//  DocsCell.swift
//  Doc Scanner
//
//  Created by M Farhan on 8/7/20.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import UIKit

class DocsCell: UITableViewCell {
    
    /* MARK:- IBOutlets  */
    @IBOutlet weak var name               : UILabel!
    @IBOutlet weak var ImageV             : UIImageView!
    @IBOutlet weak var createdAt          : UILabel!
    @IBOutlet weak var totalDocs          : UILabel!
    @IBOutlet weak var selectionBtn       : UIButton!
    @IBOutlet weak var totalDocsImageView : UIImageView!
    @IBOutlet weak var selectionImageView : UIImageView!
    
    /* MARK:- Properties */
    var fileOrFolder: DocumentsModel? {
        didSet {
            configureCell()
        }
    }
    
    /// Flag to check if multiple
    /// selection option is enabled
    var multiSelect: Bool = false
    var index      : Int  = 0
    
    /* MARK:- Closure */
    var didSelect  : ((
        _ document    : DocumentsModel ,
        _ index       : Int            ,
        _ isSelected  : Bool           
    )->())?
    
    /* MARK:- Lifecycle */
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = contentView.frame.inset(
            by: UIEdgeInsets(
                top     : 0.0  ,
                left    : 0.0  ,
                bottom  : 15.0 ,
                right   : 0.0
            )
        )
    }
    
    override func prepareForReuse() {
        index       = 0
        fileOrFolder  = nil
        multiSelect = false
        
        selectionBtn.isSelected  = false
        selectionImageView.image = UIImage(named: "radio-unselected")
    }
    
}

/* MARK:- Methods */
extension DocsCell {
    func configureCell() {
        if let dataSource = self.fileOrFolder {
            if dataSource.type == DataType.folder.rawValue {
                ImageV.image  = UIImage(named: "folder-image")
                
                name.text      = dataSource.name
                totalDocs.text = "\(dataSource.totalFiles)"
                
                if let date = Helper.dateFormatter(fromDate: "\(dataSource.createdAt)") {
                    createdAt.text = date
                } else {
                    createdAt.text = "\(dataSource.createdAt)"
                }
                
                totalDocs.isHidden = false
                totalDocsImageView.isHidden = false
            } else {
                ImageV.backgroundColor = #colorLiteral(red: 0.2274509804, green: 0.7607843137, blue: 0.9803921569, alpha: 0.1)
                
                if let data = dataSource.pages.first?.croppedImage {
                    ImageV.image  = UIImage(data: data)
                } else {
                    ImageV.image  = UIImage(named: "document-image")
                }
                
                name.text      = "\(dataSource.name)"
                totalDocs.text = "\(dataSource.pages.count)"
                
                if let date = Helper.dateFormatter(fromDate: "\(dataSource.createdAt)") {
                    createdAt.text = date
                } else {
                    createdAt.text = "\(dataSource.createdAt)"
                }
                
                ///As file doesn't contains any subfiles so this should be hidden
                totalDocs.isHidden = false
                totalDocsImageView.isHidden = false
            }
        }
        
        selectionBtn.isHidden       = !multiSelect
        selectionImageView.isHidden = !multiSelect
    }
}

/* MARK:- Actions */
extension DocsCell {
    @IBAction func selectionToggle(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected 
        
        if let datasource = fileOrFolder {
            didSelect?(datasource,index,sender.isSelected)
        }
    }
}
