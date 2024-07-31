//
//  BaseVC.swift
//  Doc Scanner
//
//  Created by M Farhan on 7/27/20.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import UIKit

class BaseVC: UIViewController {

    /* MARK:- IBOutlets  */

    /* MARK:- Properties */
    var docsVC         : DocsVC      = DocsVC()
    var settingsVC     : SettingsVC  = SettingsVC()
    var tabBarView     : UIView      = UIView()
    var docOptionsView : DocsOptions = DocsOptions()
    var containerView  : UIView      = UIView()
    
    /* MARK:- Lifecycle */
    override func viewDidLoad() {
        super.viewDidLoad()
        initVC()///Initilizing Views
    }

}

/* MARK:- Methods */
extension BaseVC {
    func initVC(){
        ///Adding Container View
        addContainerView()
        ///Loading BottomBar Nib
        if let loadedNib = Bundle.main.loadNibNamed(
            Constants.VIEW.TAB_BAR,
            owner   : self,
            options : nil
        ) {
            
            if let tabBar = loadedNib.first as? TabBar {
                tabBarView    = tabBar
                ///Setting proportional frame
                tabBar.frame  = Helper.getTabBarFrame()
                ///Passing VC References
                tabBar.docsVC = docsVC
                tabBar.baseVC = self
                ///Initilizing tabBar
                tabBar.initView()
                ///Adding into view
                view.addSubview(tabBar)
            }
            
        }
        
        view.bringSubviewToFront(tabBarView)
    }
    
    func addContainerView(){
        var frame: CGRect   = CGRect()
        
        frame.origin.x      = 0
        frame.origin.y      = 0
        frame.size.width    = SCREEN_WIDTH
        frame.size.height   = SCREEN_HEIGHT * 0.88839286
        
        containerView.frame           = frame
        containerView.backgroundColor = .clear
        
        self.view.addSubview(containerView)
        
        loadDocAndSettingsVC()
    }
    
    func loadDocAndSettingsVC(){
        docsVC     = DocsVC(nibName: Constants.VCID.DOCS, bundle: nil)
        settingsVC = SettingsVC(nibName: Constants.VCID.SETTIGNS, bundle: nil)
        
        addChild(docsVC)
        addChild(settingsVC)
        
        docsVC.view.frame     = containerView.frame
        settingsVC.view.frame = containerView.frame
        
        docsVC.refrenceVC     = self
        
        containerView.addSubview(docsVC.view)
        
        docsVC.didMove(toParent: self)
    }
    
    ///Doc Options View Load and Remove
    
    func loadOptionsView(){
        if let loadedNib = Bundle.main.loadNibNamed(
            Constants.VIEW.DOCS_OPTIONS,
            owner   : self,
            options : nil
        ) {
            
            if let docOptions = loadedNib.first as? DocsOptions {
                docOptionsView  = docOptions
                ///Setting proportional frame
                let tabBarFrame = Helper.getTabBarFrame()
                let width       = SCREEN_WIDTH * 0.91945894
                let height      = CGFloat(70.0)
                let x           = self.containerView.center.x - (width/2)
                let y           = -((height/2) - tabBarFrame.origin.y)
                
                docOptions.frame = CGRect(
                    x      : x,
                    y      : y,
                    width  : width,
                    height : height
                )
                
                ///Adding Corner Radius
                docOptions.layer.cornerRadius = docOptions.frame.height/2
                ///Passing Base VC Reference
                docOptions.refrenceVC = self
                docOptions.docsVC     = docsVC
                ///Initilizing tabBar
                docOptions.initView()
                ///Adding into view
                self.view.addSubview(docOptions)
            }
            
        }
    }
    
    func removeOptionsView() {
        docOptionsView.removeFromSuperview()
    }
}
