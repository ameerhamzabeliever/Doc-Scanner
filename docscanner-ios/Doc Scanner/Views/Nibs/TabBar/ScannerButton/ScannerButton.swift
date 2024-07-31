//
//  Scanner.swift
//  Doc Scanner
//
//  Created by M Farhan on 7/27/20.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import UIKit

class ScannerButton: UIView {
    /* MARK:- Properties */
    var docsVC: DocsVC?
    
}

/* MARK:- Actions */
extension ScannerButton {
    @IBAction func didTapScanner (_ sender: UIButton) {
        let scanningOptions = ScanningOptions(
            nibName : Constants.VCID.SCANNING_OPTIONS,
            bundle  : nil
        )
        
        scanningOptions.docsVC                 = docsVC
        scanningOptions.modalPresentationStyle = .overFullScreen
        scanningOptions.modalTransitionStyle   = .coverVertical
        
        self.parentVC?.present(scanningOptions, animated: true, completion: nil)
    }
}
