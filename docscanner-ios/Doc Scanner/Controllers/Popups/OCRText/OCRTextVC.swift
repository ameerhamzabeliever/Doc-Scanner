//
//  OCRTextVC.swift
//  Doc Scanner
//
//  Created by Umar Farooq on 27/10/2020.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import UIKit

class OCRTextVC: UIViewController {

    /* MARK:- IBOutlets */
    @IBOutlet weak var ocrTextView: UITextView!
    
    /* MARK:- Properties */
    var ocrText: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initVC()
    }

    deinit {
        Helper.debugLogs(any: "OCRTextVC deinit successfully")
    }
}

/* MARK:- Methods */
extension OCRTextVC {
    func initVC(){
        ocrTextView.text = ocrText
    }
}

/* MARK:- Properties */
extension OCRTextVC {
    @IBAction func didTapCancel(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
}
