//
//  SingleDocOptions.swift
//  Doc Scanner
//
//  Created by M Farhan on 8/18/20.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import UIKit

class DocFolderOptions: UIView {
    /* MARK:- IBOutlets  */
    @IBOutlet weak var gradientView : UIView!
    
    @IBOutlet weak var addLabel   : UILabel!
    @IBOutlet weak var addImage   : UIImageView!
    @IBOutlet weak var addButton  : UIButton!
    
    @IBOutlet weak var editLabel  : UILabel!
    @IBOutlet weak var editImage  : UIImageView!
    @IBOutlet weak var editButton : UIButton!
    
    /* MARK:- Properties */
    var docFolderVC  : DocFolderVC!
    var colors       : [CGColor] = [#colorLiteral(red: 0.03137254902, green: 0.6117647059, blue: 0.9725490196, alpha: 1).cgColor, #colorLiteral(red: 0.03137254902, green: 0.5176470588, blue: 0.9725490196, alpha: 1).cgColor]
}

/* MARK:- Methods */
extension DocFolderOptions {
    func initView() {
        MAIN_QUEUE.asyncAfter(deadline: .now() + 0.05) {
            ///Setting Up Gradient
            let gradientLayer = Helper.getGradientLayer(
                inView      : self.gradientView,
                withColors  : self.colors,
                atLocations : [0.0, 1.0]
            )
            
            self.gradientView.layer.addSublayer(gradientLayer)
        }
    }
    
    func configureScannerVC() {
        if let editFile = docFolderVC.selectedFiles.filter({ $0.id != Int(32) }).first {
            let scannerVC  = ImageScannerController(
                dataSource : ["Single"] ,
                document   : editFile   ,
                isEditOrAdd: 1          ,
                delegate   : self
            )
            
            scannerVC.modalPresentationStyle = .fullScreen
            
            if #available(iOS 13.0, *) {
                scannerVC.navigationBar.tintColor = .label
            } else {
                scannerVC.navigationBar.tintColor = .black
            }
            
            docFolderVC.present(scannerVC, animated: true)
        }
    }

    func show(MultipleSelectedOptions flag: Bool) {
        addImage.image  = addImage.image?.withRenderingMode(.alwaysTemplate)
        editImage.image = editImage.image?.withRenderingMode(.alwaysTemplate)
        
        if flag { /// Will show actions that can be performed with multiple docs at once.
            addLabel.textColor  = .gray
            addImage.tintColor  = .gray
            
            editLabel.textColor = .gray
            editImage.tintColor = .gray
        } else {
            addLabel.textColor  = .white
            addImage.tintColor  = .white
            
            editLabel.textColor = .white
            editImage.tintColor = .white
        }
        
        addButton.isUserInteractionEnabled  = !flag
        editButton.isUserInteractionEnabled = !flag
    }
}

/* MARK:- Actions */
extension DocFolderOptions {
    @IBAction func didTapShare(_ sender: UIButton) {
        docFolderVC.didTapShareButton?()
    }
    
    @IBAction func didTapAdd(_ sender: UIButton) {
        if Constants.sharedInstance.cameraPermission {
            configureScannerVC()
        } else {
            Helper.checkCameraPermission { (isGranted) in
                self.configureScannerVC()
            }
        }
    }
    
    @IBAction func didTapEditPDF(_ sender: UIButton) {
       
    }
    
    @IBAction func didTapCopyMovePDF(_ sender: UIButton) {
        docFolderVC.didTapMoveCopyButton?()
    }
    
    @IBAction func didTapDelete(_ sender: UIButton) {
        let deleteVC = DeleteVC(nibName: Constants.VCID.DELETE, bundle: nil)
        
        deleteVC.modalPresentationStyle = .overFullScreen
        deleteVC.modalTransitionStyle   = .coverVertical
        
        deleteVC.docFolderVC            = docFolderVC
        
        self.parentVC?.present(deleteVC, animated: true, completion: nil)
    }
}

/* MARK:- Scanner */

///Delegate
extension DocFolderOptions: ImageScannerControllerDelegate {
    func imageScannerControllerShouldOpenDoc(_ scanner: ImageScannerController) {
        scanner.dismiss(animated: true) { [weak self] in
            guard let self = self else {return}
        
            self.docFolderVC.getFiles(shouldResetView: true)
        }
    }
    
    func imageScannerController(
        _ scanner: ImageScannerController,
        didFinishScanningWithResults results: ImageScannerResults
    ) {
        scanner.dismiss(animated: true, completion: nil)
    }
    
    func imageScannerControllerDidCancel(
        _ scanner: ImageScannerController
    ) {
        scanner.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            
            self.docFolderVC.setup(multiSelect: false)
        }
    }
    
    func imageScannerController(
        _ scanner: ImageScannerController,
        didFailWithError error: Error
    ) {
        scanner.dismiss(animated: true, completion: nil)
    }
}
