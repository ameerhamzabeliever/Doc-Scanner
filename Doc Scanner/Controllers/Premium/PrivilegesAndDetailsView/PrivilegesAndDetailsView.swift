//
//  PrivilegesAndDetailsView.swift
//  Doc Scanner
//
//  Created by M Farhan on 8/15/20.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import UIKit

class PrivilegesAndDetailsView: UIView {
    /* MARK:- IBOutlet */
    @IBOutlet weak var stackView     : UIStackView!
    @IBOutlet weak var stackViewTop  : NSLayoutConstraint!
    @IBOutlet weak var stackView1Top : NSLayoutConstraint!
    
    func setupStackSpacing(){
        MAIN_QUEUE.asyncAfter(deadline: .now() + 0.05) {
            switch Helper.device() {
            case .bezeliPhone:
                self.stackView.spacing      = SCREEN_HEIGHT * 0.028
                self.stackViewTop.constant  = SCREEN_HEIGHT * 0.028
                self.stackView1Top.constant = SCREEN_HEIGHT * 0.022
            default:
                break
            }
        }
    }
}
