//
//  TabBar.swift
//  Doc Scanner
//
//  Created by M Farhan on 7/27/20.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import UIKit

class TabBar: UIView {
    
    /* MARK:- IBOutlets  */
    @IBOutlet weak var docImg      : UIImageView!
    @IBOutlet weak var settignsImg : UIImageView!
    
    ///Design Only Outlets
    @IBOutlet weak var selectedLabel: UILabel!
    
    ///Constraints Outlets
    @IBOutlet weak var docImgLeading       : NSLayoutConstraint!
    @IBOutlet weak var settignsImgTrailing : NSLayoutConstraint!
    @IBOutlet weak var selectedLabelCenter : NSLayoutConstraint!
    
    /* MARK:- Nav Properties  */
    var docsVC     : DocsVC?
    var baseVC     : BaseVC!
    var selectedVC : TabBarVC = .docs
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if super.point(inside: point, with: event) { return true }
        for subview in subviews {
            let subviewPoint = subview.convert(point, from: self)
            if subview.point(inside: subviewPoint, with: event) { return true }
        }
        return false
    }
}

/* MARK:- Methods */
extension TabBar {
    func initView() {
        ///Setting Bar Buttons Position
        docImgLeading.constant       = SCREEN_WIDTH * 0.14985845
        settignsImgTrailing.constant = SCREEN_WIDTH * 0.14985845
        ///Adding Scanner Button
        if let loadedNib = Bundle.main.loadNibNamed(
            Constants.VIEW.SCANNER_BUTTON,
            owner   : self,
            options : nil
        ) {
            
            if let scannerButton = loadedNib.first as? ScannerButton {
                ///Setting proportional frame
                let width  = SCREEN_WIDTH * 0.19323671
                let height = width
                let x      = self.center.x - (width/2)
                let y      = -(height/2)
                
                scannerButton.frame = CGRect(
                    x       : x      ,
                    y       : y      ,
                    width   : width  ,
                    height  : height
                )
                
                ///Passing Docs VC Reference
                scannerButton.docsVC = docsVC
                ///Adding into view
                addSubview(scannerButton)
                bringSubviewToFront(scannerButton)
            }
            
        }
    }
    
    func animateSelected(WithIdentifier identifier: String) {
        if identifier == "docs" {
            UIView.animate(withDuration: 0.5) {
                self.selectedLabel.center.x = self.docImg.center.x
            }
        } else {
            UIView.animate(withDuration: 0.5) {
                self.selectedLabel.center.x = self.settignsImg.center.x
            }
        }
    }
    
    func loadDocsView(){
        baseVC.containerView.transform = CGAffineTransform(
            translationX : -UIScreen.main.bounds.size.width,
            y            : 0
        )
        
        baseVC.containerView.addSubview(baseVC.docsVC.view)
        baseVC.docsVC.didMove(toParent: baseVC)
        
        baseVC.docsVC.probar(shouldHide: Constants.sharedInstance.isPremiumUser)
        
        UIView.animate(
            withDuration : 0.4             ,
            delay        : 0               ,
            options      : .curveEaseInOut ,
            animations   : {
                self.baseVC.containerView.transform = .identity
            }
        )
        
        selectedVC = .docs
    }
    
    func loadSettingsView(){
        baseVC.containerView.transform = CGAffineTransform(
            translationX : UIScreen.main.bounds.size.width,
            y            : 0
        )
        
        baseVC.containerView.addSubview(baseVC.settingsVC.view)
        baseVC.settingsVC.didMove(toParent: baseVC)
        
        baseVC.settingsVC.probar(shouldHide: Constants.sharedInstance.isPremiumUser)
        
        UIView.animate(
            withDuration : 0.4             ,
            delay        : 0               ,
            options      : .curveEaseInOut ,
            animations   : {
                self.baseVC.containerView.transform = .identity
            }
        )
        
        selectedVC = .settings
    }
}

/* MARK:- Actions */
extension TabBar {
    @IBAction func didTapdoc (_ sender: UIButton) {
        if selectedVC != .docs {
            if let identifier = sender.accessibilityIdentifier {
                animateSelected(WithIdentifier: identifier)
            }
            loadDocsView()
        }
    }
    
    @IBAction func didTapSettings (_ sender: UIButton) {
        if selectedVC != .settings {
            if let identifier = sender.accessibilityIdentifier {
                animateSelected(WithIdentifier: identifier)
            }
            loadSettingsView()
        }
    }
}
