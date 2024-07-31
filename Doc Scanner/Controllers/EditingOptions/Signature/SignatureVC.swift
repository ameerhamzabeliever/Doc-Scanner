//
//  SignatureVC.swift
//  Doc Scanner
//
//  Created by M Farhan on 8/19/20.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import UIKit

class SignatureVC: UIViewController {

    /* MARK:- IBOutlets */
    @IBOutlet weak var colorsStack     : UIStackView!
    @IBOutlet weak var TypeSignature   : UILabel!
    @IBOutlet weak var TextSignature   : UITextField!
    @IBOutlet weak var stackContainer  : UIView!
    @IBOutlet weak var interactionView : UIView!
    
    /* MARK:- Properties */
    var colors        : [UIColor]     = [#colorLiteral(red: 0.8117647059, green: 0.1254901961, blue: 0.1254901961, alpha: 1),#colorLiteral(red: 0.03137254902, green: 0.5333333333, blue: 0.9725490196, alpha: 1),#colorLiteral(red: 0.06274509804, green: 0.06274509804, blue: 0.06274509804, alpha: 1)]
    var selectedColor : UIColor       = #colorLiteral(red: 0.03137254902, green: 0.5333333333, blue: 0.9725490196, alpha: 1)
    var signatureType : SignatureType = .draw
    
    var setSignatureVC : SetSignatureVC!
    
    /// Drawing View
    var drawingView   = DrawingView(lineColor: #colorLiteral(red: 0.03137254902, green: 0.5333333333, blue: 0.9725490196, alpha: 1))

    /* MARK:- Lifecycle */
    override func viewDidLoad() {
        super.viewDidLoad()
        initVC()
    }
    
    ///Setting up landscape mode for signature vc
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        APPDELEGATE.restrictRotation = .landscapeRight
        
        let value = UIInterfaceOrientation.landscapeRight.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
    }
    
    ///Setting up portrait mode again
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        APPDELEGATE.restrictRotation = .portrait
        
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
    }
    
    deinit {
        Helper.debugLogs(any: "Deinit Signature VC Successful")
    }
}

/* MARK:- Methods */
extension SignatureVC {
    func initVC(){
        ///Setting up color pallet
        setupColorPalletStack()
        ///Initiate Drawing View
        initDrawingView()
    }
    
    func initDrawingView(){
        MAIN_QUEUE.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self = self else { return }
            
            let drawingView          = DrawingView(lineColor: self.selectedColor.cgColor)
            let interactionViewFrame = self.interactionView.frame
            
            let frame: CGRect = CGRect(
                x       : 0                          ,
                y       : 0                          ,
                width   : interactionViewFrame.width ,
                height  : interactionViewFrame.height
            )
            
            drawingView.accessibilityIdentifier  = SignatureType.draw.rawValue
            drawingView.frame                    = frame
            drawingView.backgroundColor          = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)
            drawingView.isUserInteractionEnabled = true
            
            self.drawingView = drawingView
            
            self.interactionView.addSubview(drawingView)
        }
    }
    
    func addCornerRadiusToColors(){
        MAIN_QUEUE.asyncAfter(deadline: .now() + 0.05) {
            self.stackContainer.layer.cornerRadius = self.stackContainer.frame.width/2
            
            self.colorsStack.arrangedSubviews.forEach { (colorButton) in
                if let colorButton = colorButton as? UIButton {
                    colorButton.layer.cornerRadius = colorButton.frame.height/2
                }
            }
        }
    }
    
    func setupColorPalletStack(){
        ///Removing sample colors
        removeSubviewsFromStackView()
        ///Adding colors
        for (index,color) in colors.enumerated() {
            /* Setting up color button */
            let colorButton                = UIButton(type: .custom)
            colorButton.backgroundColor    = color
            colorButton.tag                = index
            let colorButtonSelector        = #selector(didSelectColor(_:))
                        
            ///Setting up constraints
            let heightAndWidth: CGFloat = index == 1 ? 40.0 : 30.0
            
            colorButton.heightAnchor.constraint(
                equalToConstant: heightAndWidth
            ).isActive = true
            
            colorButton.widthAnchor.constraint(
                equalToConstant: heightAndWidth
            ).isActive = true
            
            ///Setting up selected image
            colorButton.setImage(#imageLiteral(resourceName: "selected-color"), for: .selected)
                        
            ///Adding action
            colorButton.addTarget(
                self,
                action:
                colorButtonSelector,
                for: .touchUpInside
            )
            
            colorButton.isSelected = index == 1 ? true : false
            
            self.colorsStack.addArrangedSubview(colorButton)
        }
        ///Making color buttons circular
        addCornerRadiusToColors()
    }
    
    ///Method is needed as there is a
    ///sample color is already added in
    ///the stackview
    func removeSubviewsFromStackView(){
        colorsStack.arrangedSubviews.forEach { (subview) in
            subview.removeFromSuperview()
        }
    }
    
    ///Method is needed to deselect all
    ///other colors before selection of
    ///new color
    func resetSelectedColors(){
        colorsStack.arrangedSubviews.forEach { (colorButton) in
            if let colorButton = colorButton as? UIButton {
                colorButton.isSelected = false
                
                colorButton.constraints.forEach { (constraint) in
                    constraint.constant = 30.0
                }
            }
        }
    }
    
}

/* MARK:- objc Interface */
extension SignatureVC {
    @objc func didSelectColor(_ sender: UIButton){
        ///Deseleting all colors
        resetSelectedColors()
        
        sender.isSelected     = true
        selectedColor         = colors[sender.tag]
        
        ///Setting up constraints
        sender.constraints.forEach { (constraint) in
            constraint.constant = 40.0
        }
        
        ///Making color buttons circular
        addCornerRadiusToColors()
        
        switch signatureType {
        case .draw:
            drawingView.lineColor = selectedColor.cgColor
        case .type:
            TypeSignature.textColor = selectedColor
        }
    }
}

/* MARK:- Action */
extension SignatureVC {
    @IBAction func didTapCancel(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func toggleSegmentControl(_ sender: UISegmentedControl) {
        let selectedIndex = sender.selectedSegmentIndex
        
        if selectedIndex == 0 {
            ///Changing sign type
            signatureType = .draw
            ///Removing text and hiding text view
            TextSignature.text     = ""
            TypeSignature.text     = ""
            TypeSignature.isHidden = true
            TextSignature.resignFirstResponder()
            ///initiating drawing view
            initDrawingView()
        } else {
            ///Changing sign type
            signatureType = .type
            ///Removing drawing view
            interactionView.subviews.forEach { (subView) in
                if subView.accessibilityIdentifier == SignatureType.draw.rawValue {
                    subView.removeFromSuperview()
                }
            }
            ///Showing text view and making TextSignature first responder
            TypeSignature.textColor = selectedColor
            TypeSignature.isHidden  = false
            TextSignature.becomeFirstResponder()
        }
    }
    
    @IBAction func didBeganTyping(_ sender: UITextField) {
        if let text = sender.text {
            self.TypeSignature.text = text
        }
    }
    
    @IBAction func didTapDone(_ sender: UIButton) {
        if signatureType == .draw {
            if let signature = drawingView.signature {
                self.navigationController?.popViewController(animated: true, completion: { [weak self] in
                    guard let self = self else { return }
                    self.setSignatureVC.didMadeSigns?(self.signatureType, signature)
                })
            }
        } else {
            if let signature = TypeSignature.text {
                self.navigationController?.popViewController(animated: true, completion: { [weak self] in
                    guard let self = self else { return }
                    self.setSignatureVC.didMadeSigns?(self.signatureType, signature)
                })
            }
        }
    }
    
    @IBAction func didTapClear(_ sender: UIButton) {
        switch signatureType {
        case .draw:
            interactionView.subviews.forEach { (subView) in
                if subView.accessibilityIdentifier == SignatureType.draw.rawValue {
                    subView.removeFromSuperview()
                }
            }
            initDrawingView()
        case .type:
            TextSignature.text = ""
            TypeSignature.text = ""
        }
    }
}
