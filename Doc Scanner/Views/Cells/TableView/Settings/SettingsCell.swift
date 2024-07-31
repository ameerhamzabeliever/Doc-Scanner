//
//  SettingsCell.swift
//  Doc Scanner
//
//  Created by M Farhan on 8/10/20.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import UIKit

class SettingsCell: UITableViewCell {
    /* MARK:- IBOutlets  */
    @IBOutlet weak var nameLabel         : UILabel!
    @IBOutlet weak var toggleSwitch      : UISwitch!
    @IBOutlet weak var arrowRightImage   : UIImageView!
    @IBOutlet weak var selectedNameLabel : UILabel!
    
    
    /* MARK:- Properties */
    var setting: String? {
        didSet {
            configureCell()
        }
    }
    
    /* MARK:- Lifecycle */
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
    }
    
}

/* MARK:- Methods */
extension SettingsCell {
    func configureCell() {
        if let setting = setting {
            nameLabel.text = setting
            
            ///Cell design setup
            if setting == "Wifi Transfer" {
                
                selectedNameLabel.isHidden = true
                arrowRightImage.isHidden   = true
                toggleSwitch.isHidden      = false
            
                toggleSwitch.transform     = CGAffineTransform(scaleX: 0.75, y: 0.75)
                
            } else if setting == "App Pin & Touch ID" ||
                      setting == "Start App With" ||
                      setting == "Picture Quality"
            {
                
                selectedNameLabel.isHidden = false
                arrowRightImage.isHidden   = false
                toggleSwitch.isHidden      = true
                
            } else {
                
                selectedNameLabel.isHidden = true
                arrowRightImage.isHidden   = false
                toggleSwitch.isHidden      = true
                
            }
        }
    }
}

/* MARK:- Actions */
extension SettingsCell {
    @IBAction func toggleAction(_ sender: UISwitch) {
    
        if sender.isOn {
            sender.thumbTintColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        } else {
            sender.thumbTintColor = #colorLiteral(red: 0.4078431373, green: 0.9411764706, blue: 0.2745098039, alpha: 1)
        }
        
    }
}

