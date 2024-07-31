//
//  LockVC.swift
//  Doc Scanner
//
//  Created by M Farhan on 8/7/20.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import UIKit

class LockVC: UIViewController {
    /* MARK:- IBOutlets  */
    @IBOutlet weak var containerView: UIView!
    
    /* MARK:- Properties */
    var docsVC  : DocsVC!
    var folders : [DocumentsModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initVC()
    }
}

/* MARK:- Methods */
extension LockVC {
    func initVC(){
        containerView.layer.cornerRadius = containerView.frame.height * 0.12048193
    }
}

/* MARK:- Actions */
extension LockVC {
    @IBAction func didTapPasscode(_ sender: UIButton) {
        let passcodeVC = PasscodeVC(nibName: Constants.VCID.PASSCODE, bundle: nil)
        
        passcodeVC.modalTransitionStyle   = .coverVertical
        passcodeVC.modalPresentationStyle = .overFullScreen
        
        passcodeVC.folders                = folders
        passcodeVC.docsVC                 = docsVC
        
        self.dismiss(animated: true, completion: nil)
        docsVC.present(passcodeVC, animated: true, completion: nil)
    }
    
    @IBAction func didTapTouchId(_ sender: UIButton) {
        let touchIdVC = TouchIdVC(nibName: Constants.VCID.TOUCH_ID, bundle: nil)
        
        touchIdVC.modalTransitionStyle   = .coverVertical
        touchIdVC.modalPresentationStyle = .overFullScreen
        
        touchIdVC.folders                = folders
        touchIdVC.docsVC                 = docsVC
        
        self.dismiss(animated: true, completion: nil)
        docsVC.present(touchIdVC, animated: true, completion: nil)
    }
    
    @IBAction func didTapCancel(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}
