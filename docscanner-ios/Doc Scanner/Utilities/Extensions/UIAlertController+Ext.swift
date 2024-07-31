//
//  UIAlertController+Ext.swift
//  Doc Scanner
//
//  Created by Umar Farooq on 13/10/2020.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import UIKit

extension UIAlertController {
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
    open override var shouldAutorotate: Bool {
        return false
    }
}
