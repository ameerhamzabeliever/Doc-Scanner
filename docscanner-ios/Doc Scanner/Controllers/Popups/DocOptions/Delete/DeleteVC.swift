//
//  DeleteVC.swift
//  Doc Scanner
//
//  Created by M Farhan on 8/10/20.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import UIKit

class DeleteVC: UIViewController {
    
    /* MARK:- IBOutlets  */
    @IBOutlet weak var containerView : UIView!
    
    /* MARK:- Properties */
    var docsVC      : DocsVC?
    var docFolderVC : DocFolderVC?
    
    /* MARK:- Lifecycle */
    override func viewDidLoad() {
        super.viewDidLoad()
        initView()
    }
    
}

/* MARK:- Methods */
extension DeleteVC {
    func initView(){
        containerView.layer.cornerRadius = containerView.frame.height * 0.13333333
    }
}

/* MARK:- Actions */
extension DeleteVC {
    @IBAction func didTapOk(_ sender: UIButton) {
        self.dismiss(animated: true) { [weak self] in
            guard let self = self else {return}
            if let docsVC = self.docsVC {
                docsVC.didTapDeleteButton?()
            } else if let docFolderVC  = self.docFolderVC {
                docFolderVC.didTapDeleteButton?()
            }
        }
    }
    
    @IBAction func didTapCancel(_ sender: UIButton){
        self.dismiss(animated: true, completion: nil)
    }
}
