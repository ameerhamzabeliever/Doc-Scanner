//
//  TouchIdVC.swift
//  Doc Scanner
//
//  Created by M Farhan on 8/10/20.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import UIKit

class TouchIdVC: UIViewController {
    
    /* MARK:- IBOutlets  */
    @IBOutlet weak var toggleButton  : UISwitch!
    @IBOutlet weak var containerView : UIView!
    @IBOutlet weak var okayButton    : UIButton!
    
    /* MARK:- Properties */
    var docsVC   : DocsVC!
    var folders  : [DocumentsModel] = []
    var entries  : [String: Any]    = [:]
    
    
    /* MARK:- Lifecycle */
    override func viewDidLoad() {
        super.viewDidLoad()
        initView()
    }
    
}

/* MARK:- Methods */
extension TouchIdVC {
    func initView(){
        toggleButton.transform           = CGAffineTransform(scaleX: 0.75, y: 0.75)
        containerView.layer.cornerRadius = containerView.frame.height * 0.13333333
    }
    
    func setTouchId() {
        let passcodeVC = PasscodeVC(nibName: Constants.VCID.PASSCODE, bundle: nil)
        
        passcodeVC.modalTransitionStyle   = .coverVertical
        passcodeVC.modalPresentationStyle = .overFullScreen
        
        passcodeVC.folders                = folders
        passcodeVC.docsVC                 = docsVC
        passcodeVC.entries                = entries
        passcodeVC.isTouchId              = true
        
        dismiss(animated: true, completion: nil)
        docsVC.present(passcodeVC, animated: true, completion: nil)
    }
    
}

/* MARK:- Actions */
extension TouchIdVC {
    @IBAction func didTapOk(_ sender: UIButton) {
        setTouchId()
    }
    
    @IBAction func didTapCancel(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func toggleAction(_ sender: UISwitch) {
    
        if sender.isOn {
            sender.thumbTintColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            
            okayButton.isEnabled  = true
        } else {
            sender.thumbTintColor = #colorLiteral(red: 0.4078431373, green: 0.9411764706, blue: 0.2745098039, alpha: 1)
            
            okayButton.isEnabled  = false
        }
        
    }
}
