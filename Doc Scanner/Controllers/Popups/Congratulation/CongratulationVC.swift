//
//  CongratulationVC.swift
//  Doc Scanner
//
//  Created by Umar Farooq on 07/11/2020.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import UIKit

class CongratulationVC: UIViewController {

    /* MARK:- IBOutlets */
    @IBOutlet weak var containerView  : UIView!
    @IBOutlet weak var continueButton : UIButton!
    
    /// Constraints
    @IBOutlet weak var continueButtonBottom : NSLayoutConstraint!
    
    /* MARK:- Computed Properties */
    var bottomConstant: CGFloat {
        get {
            return SCREEN_HEIGHT * 0.04
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initVC()
    }

}

/* MARK:- Methods */
extension CongratulationVC {
    func initVC(){
        MAIN_QUEUE.async { [weak self] in
            guard let self = self else { return }
            
            self.containerView.layer.cornerRadius  = 20.0
            self.continueButton.layer.cornerRadius = 10.0
            
            self.continueButtonBottom.constant     = self.bottomConstant
        }
    }
}

/* MARK:- Actions */
extension CongratulationVC {
    @IBAction func didTapContinue(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
}
