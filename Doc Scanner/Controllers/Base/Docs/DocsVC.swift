//
//  HomeVC.swift
//  Doc Scanner
//
//  Created by M Farhan on 7/27/20.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import UIKit
import GoogleMobileAds
import MobileCoreServices
import LocalAuthentication

class DocsVC: UIViewController {

    /* MARK:- IBOutlets  */
    @IBOutlet weak var tableView             : UITableView!
    @IBOutlet weak var proBarView            : UIView!
    @IBOutlet weak var bannerAdContainerView : UIView!
    
    ///StackView
    @IBOutlet weak var noDataStack  : UIStackView!
    @IBOutlet weak var btnsStack    : UIStackView!
    
    ///Label
    @IBOutlet weak var titleLbl     : UILabel!
    @IBOutlet weak var totalDocsLbl : UILabel!
    
    ///Buttons
    @IBOutlet weak var cancelBtn    : UIButton!
    @IBOutlet weak var selectAllBtn : UIButton!
    
    /* MARK:- NSLayout Constraints */
    @IBOutlet weak var probarHeight                : NSLayoutConstraint!
    @IBOutlet weak var bannerAdContainerViewHeight : NSLayoutConstraint!
    
    /* MARK:- Lazy Properties */
    lazy var cellNib: UINib = {
        return UINib(nibName: Constants.cellNib.DOCS, bundle: nil)
    }()
    
    /* MARK:- Properties */
    var refrenceVC   : BaseVC!
    var semaphore    : DispatchSemaphore = DispatchSemaphore(value: 0)
    var dispachGroup : DispatchGroup     = DispatchGroup()
    
    var keyVal       : [String:String]   = ["folder_id" : "0"]
    var selectedDoc  : [DocumentsModel]  = []
    var multiSelect  : Bool              = false
    
    var filesAndFolders : [DocumentsModel] = []
    
    ///Haptic Feedback Generator
    let generator : UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(
        style: .medium
    )
    
    ///Google Mobile Ads
    var bannerView      : GADBannerView!
    var interstitial    : GADInterstitial!
    var shouldPresentAd : Bool = false
    
    /* MARK:- Closures */
    var didNeedsRefresh      : (()->())?
    var didTapScannerButton  : (()->())?
    
    ///Options Bar
    var didTapLockButton     : (()->())?
    var didTapUnlockButton   : (()->())?
    var didTapMoveCopyButton : (()->())?
    var didTapMergeButton    : (()->())?
    var didTapDeleteButton   : (()->())?
    var shouldOpenNewDoc     : (()->())?
    
    /* MARK:- Lifecycle */
    override func viewDidLoad() {
        super.viewDidLoad()
        initVC()///Initilizing Views
    }
    
    override func viewWillAppear(_ animated: Bool) {
        getFilesAndFolders()
        probar(shouldHide: Constants.sharedInstance.isPremiumUser)
    }

    deinit {
        Helper.debugLogs(any: "Docs VC Deinitilized", and: "Logs")
    }
}

/* MARK:- Methods */
extension DocsVC {
    func initVC(){        
        ///Fetching Files and Folders
        getFilesAndFolders()
        ///ProBar View Design Setup
        MAIN_QUEUE.asyncAfter(deadline: .now() + 0.05) {
            self.proBarView.layer.cornerRadius = self.proBarView.frame.height / 2.0
        }
        ///Cell Registeration
        registerCell()
        ///Lauch Premium Screen
        #if !DEBUG
        if !Constants.sharedInstance.isPremiumUser {
            presentPremiumScreen()
        }
        #endif
        
        ///Initilizing Selected Files Folders Array
        filesAndFolders.forEach { (_) in
            selectedDoc.append(DocumentsModel())
        }
        
        ///Scanner Button Action
        didTapScannerButton = { [weak self] in
            guard let self = self else { return }
            
            let scannerVC = ImageScannerController(delegate: self)
            scannerVC.modalPresentationStyle = .fullScreen
            
            if #available(iOS 13.0, *) {
                scannerVC.navigationBar.tintColor = .label
            } else {
                scannerVC.navigationBar.tintColor = .black
            }
            
            self.present(scannerVC, animated: true)
        }
        
        ///Refresh Action
        didNeedsRefresh = { [weak self] in
            guard let self = self else { return }
            self.getFilesAndFolders()
            self.setup(multiSelect: false)
        }
        
        /// Open newly created doc
        shouldOpenNewDoc = { [weak self] in
            guard let self = self else { return }
            self.getFilesAndFolders()
            self.setup(multiSelect: false)
            
            if let file = self.filesAndFolders.first, file.type == DataType.file.rawValue {
                self.open(
                    Document   : file,
                    isAnimated : false,
                    andShowAd  : !Constants.sharedInstance.isPremiumUser
                )
            }
        }
        
        ///Option Bar Closure Methods
        optionBarClosures()
        
        if Constants.sharedInstance.startAppWith == StartAppWith.scanner.rawValue {
            presentScanner()
        }
        
        if !Constants.sharedInstance.isPremiumUser {
            showBanner()
        }
    }
    
    func probar(shouldHide flag: Bool) {
        if flag {
            probarHeight.constant = 0
            bannerAdContainerViewHeight.constant = 0
        } else {
            probarHeight.constant = 52
            bannerAdContainerViewHeight.constant = 50
        }
    }
    
    func optionBarClosures(){
        ///Unlock Button Action
        didTapUnlockButton = {[weak self] in
            guard let self  = self else {return}
            
            self.selectedDoc.forEach { (fileOrFolder) in ///Checking if a folder is selected as we can't move or copy folder
                if fileOrFolder.type == DataType.file.rawValue {
                    self.showAlert(message: "Documents(s) can't be unlocked. Please select folder(s) only.")
                    return
                }
            }
            
            let selectedDocs = self.selectedDoc.filter({ $0.id != Int32(0) })///Filter to get only actual selected files
            if selectedDocs.count < 1 {
                self.showAlert(message: "Please select folder to unlock.")
                return
            }
            
            let unlockVC = UnlockVC(nibName: Constants.VCID.UNLOCK, bundle: nil)
            
            unlockVC.modalPresentationStyle = .overFullScreen
            unlockVC.modalTransitionStyle   = .coverVertical
            
            unlockVC.docsVC                 = self
            unlockVC.folders                = selectedDocs
            
            self.present(unlockVC, animated: true, completion: nil)
        }
        
        ///Lock Button Action
        didTapLockButton   = { [weak self] in
            guard let self  = self else {return}
            
            self.selectedDoc.forEach { (fileOrFolder) in ///Checking if a folder is selected as we can't move or copy folder
                if fileOrFolder.type == DataType.file.rawValue {
                    self.showAlert(message: "Documents(s) can't be locked. Please select folder(s) only.")
                    return
                }
            }
            
            let selectedDocs = self.selectedDoc.filter({ $0.id != Int32(0) })///Filter to get only actual selected files
            if selectedDocs.count < 1 {
                self.showAlert(message: "Please select folder to lock.")
                return
            }
            
            let lockVC = LockVC(nibName: Constants.VCID.LOCK, bundle: nil)
            
            lockVC.modalPresentationStyle = .overFullScreen
            lockVC.modalTransitionStyle   = .coverVertical
            
            lockVC.docsVC                 = self
            lockVC.folders                = selectedDocs
            
            self.present(lockVC, animated: true, completion: nil)
        }
        
        ///Merge Button Action
        didTapMergeButton  = { [weak self] in
            guard let self = self else {return}
            
            self.selectedDoc.forEach { (fileOrFolder) in ///Checking if a folder is selected as we can't move or copy folder
                if fileOrFolder.type == DataType.folder.rawValue {
                    self.showAlert(message: "Folders can't be merged. Please select documents only.")
                    return
                }
            }
            
            let selectedDocs = self.selectedDoc.filter({ $0.id != Int32(0) })///Filter to get only actual selected files
            if selectedDocs.count < 2 {
                self.showAlert(message: "Please select atleast 2 documents to be merged.")
                return
            }
            
            let mergeVC = MergeVC(nibName: Constants.VCID.MERGE, bundle: nil)
         
            mergeVC.modalPresentationStyle = .overFullScreen
            mergeVC.modalTransitionStyle   = .coverVertical
            
            mergeVC.docsVC                 = self
            mergeVC.selectedDocs           = self.selectedDoc
            
            self.present(mergeVC, animated: true, completion: nil)
        }
        
        ///Move Button Action
        didTapMoveCopyButton = { [weak self] in
            guard let self = self else {return}
            
            self.selectedDoc.forEach { (fileOrFolder) in ///Checking if a folder is selected as we can't move or copy folder
                if fileOrFolder.type == DataType.folder.rawValue {
                    self.showAlert(message: "Folder's can't be moved or copy. Please select document(s)")
                    return
                }
            }
            
            let selectedDocs = self.selectedDoc.filter({ $0.id != Int32(0) })///Filter to get only actual selected files
            if selectedDocs.count < 1 {
                self.showAlert(message: "Please select document(s) to copy/move.")
                return
            }
            
            let moveCopyVC = MoveCopyVC(nibName: Constants.VCID.MOVE_COPY, bundle: nil)
         
            moveCopyVC.modalPresentationStyle = .overFullScreen
            moveCopyVC.modalTransitionStyle   = .coverVertical
            
            moveCopyVC.docsVC                 = self
            
            self.present(moveCopyVC, animated: true, completion: nil)
        }
        
        ///Delete Action
        didTapDeleteButton = { [weak self] in
            guard let self = self else { return }
            
            let selectedDocs = self.selectedDoc.filter({ $0.id != Int32(0) })///Filter to get only actual selected files
            if selectedDocs.count < 1 {
                self.showAlert(message: "Please select document(s)/folder(s) to delete.")
                return
            }
            
            self.delete(atIndex: 0)
        }
    }
    
    ///DELETE START
    func delete(atIndex index: Int) {
        if index < self.selectedDoc.count {
            if selectedDoc[index].id != Int32(0) {
                if selectedDoc[index].lockType != 0 {
                    showPasscodeFor(folderToDelete: selectedDoc[index], atIndex: index)
                } else {
                    delete(FileFolder: selectedDoc[index], atIndex: index)
                }
            } else {
                delete(atIndex: index + 1)
            }
        } else {
            self.getFilesAndFolders()
            self.setup(multiSelect: false)
        }
    }
    
    /// Shows the passcode VC wihile deleting folder if there is any
    /// - Parameters:
    ///   - folder: Folder to be deleted
    ///   - index: Index at which we're at present
    func showPasscodeFor(folderToDelete folder: DocumentsModel, atIndex index: Int){
        let passcodeVC = PasscodeVC(nibName: Constants.VCID.PASSCODE, bundle: nil)
        
        passcodeVC.modalTransitionStyle   = .coverVertical
        passcodeVC.modalPresentationStyle = .overFullScreen
                
        passcodeVC.folder                 = folder
        passcodeVC.docsVC                 = self
        passcodeVC.isDeleteFolder         = true
        passcodeVC.deleteIndex            = index
        
        present(passcodeVC, animated: true, completion: nil)
    }
    
    func delete(FileFolder doc: DocumentsModel, atIndex index: Int) {
        if doc.type == DataType.folder.rawValue {
            CBFileManager.sharedInstance.deleteData(
                key     : "id",
                value   : doc.id,
                entity  : DOCUMENTS
            ) { (isFinished) in
                if isFinished {
                    self.delete(atIndex: index + 1)
                }
            }
        } else {
            CBFileManager.sharedInstance.deleteData(
                key     : "id",
                value   : doc.id,
                entity  : DOCUMENTS
            ) { (isFinished) in
                
                if isFinished {
                    for (i,page) in doc.pages.enumerated() {
                        ///Deleting Pages In PDF
                        CBFileManager.sharedInstance.deleteData(
                            key   : "id",
                            value : page.id,
                            entity: PAGES
                        ) { (isFinished) in
                            
                            if isFinished {
                                ///Deleting Quad of the Page
                                CBFileManager.sharedInstance.deleteData(
                                    key   : "id",
                                    value : page.quad.id,
                                    entity: QUADS
                                ) { (isFinished) in
                                    
                                    if isFinished {
                                        if i == doc.pages.count - 1 {
                                            self.delete(atIndex: index + 1)
                                        }
                                    } else {
                                        Helper.debugLogs(any: "Can't delete Quad", and: "Failure")
                                    }
                                    
                                }
                            } else {
                                Helper.debugLogs(any: "Can't delete Page", and: "Failure")
                            }
                            
                        }
                    }
                } else {
                    Helper.debugLogs(any: "Can't delete Document", and: "Failure")
                }
                
            }
        }
    }  
    ///DELETE END
    
    func getFilesAndFolders(){
        filesAndFolders.removeAll()///Removing old data inorder to overcome redundancy
        
        filesAndFolders = CBFileManager.sharedInstance.retrieveFilesFolders(
            shouldAddCondition: true,
            withKeyAndValue   : keyVal,
            ofType            : nil
        )
        
        filesAndFolders = filesAndFolders.reversed()
        
        ///Populating selected docs array with empty values
        self.selectedDoc.removeAll()
        for _ in filesAndFolders {
            self.selectedDoc.append(DocumentsModel())
        }
        
        self.tableView.reloadData()
    }
    
    func registerCell(){
        tableView.register(cellNib, forCellReuseIdentifier: Constants.cellNib.DOCS)
        
        tableView.dragDelegate           = self
        tableView.dropDelegate           = self
        tableView.dragInteractionEnabled = true
    }
    
    func setup(multiSelect bool: Bool) {
        if bool {
            multiSelect           = true
            titleLbl.text         = "0 item(s) Selected"
            btnsStack.isHidden    = true
            cancelBtn.isHidden    = false
            totalDocsLbl.isHidden = true
            selectAllBtn.isHidden = false
            
            refrenceVC.loadOptionsView()
            refrenceVC.tabBarView.isHidden = true
        } else {
            multiSelect           = false
            titleLbl.text         = APP_NAME
            btnsStack.isHidden    = false
            cancelBtn.isHidden    = true
            totalDocsLbl.isHidden = false
            selectAllBtn.isHidden = true
            
            selectedDoc.removeAll()
            selectAllBtn.setTitle("Select All", for: .normal)
            filesAndFolders.enumerated().forEach { (index,item) in
                filesAndFolders[index].isSelected = false
                selectedDoc.append(DocumentsModel())
            }
            
            refrenceVC.removeOptionsView()
            refrenceVC.tabBarView.isHidden = false
        }
        
        tableView.reloadData()
    }
    
    func selectedDocsCount() {
        var totalSelecedDocs = 0
        
        filesAndFolders.forEach { (item) in
            if item.isSelected {
                totalSelecedDocs += 1
            }
        }
        
        titleLbl.text = "\(totalSelecedDocs) item(s) Selected"
    }
    
    func presentPremiumScreen(){
        let premiumVC = PremiumVC(nibName: Constants.VCID.PREMIUM, bundle: nil)
        
        premiumVC.refrenceVC             = self
        
        premiumVC.modalTransitionStyle   = .coverVertical
        premiumVC.modalPresentationStyle = .overFullScreen
        
        self.present(premiumVC, animated: true, completion: nil)
    }
    
    func presentScanner(){
        let scannerVC = ImageScannerController(delegate: self)
        scannerVC.modalPresentationStyle = .fullScreen
        
        if #available(iOS 13.0, *) {
            scannerVC.navigationBar.tintColor = .label
        } else {
            scannerVC.navigationBar.tintColor = .black
        }
        
        present(scannerVC, animated: true)
    }
    
    /// Open File Folder
    
    /// Open the doc view to view document
    /// - Parameters:
    ///   - document: The document to be opened
    ///   - animated: bool to define if the presentation will be animated or not
    ///   - showAd: bool to decide if the ad should be shown
    func open(Document document: DocumentsModel, isAnimated animated: Bool = true, andShowAd showAd: Bool = false){
        let docVC      = DocVC(nibName: Constants.VCID.DOC, bundle: nil)
        
        docVC.document     = document
        docVC.shouldShowAd = showAd
        
        self.navigationController?.pushViewController(docVC, animated: animated)
    }
    
    func open(Folder folder: DocumentsModel) {
        let docFolderVC      = DocFolderVC(nibName: Constants.VCID.DOC_FOLDER, bundle : nil)
        docFolderVC.document = folder
        
        self.navigationController?.pushViewController(docFolderVC, animated: true)
    }
    
    /// Open Locked Folder
    
    /// Opens the touch id vc for passcode authentication
    /// - Parameter folder: Folder for which authentication is to be done
    func openPasscodeVC(forFolder folder: DocumentsModel) {
        let passcodeVC = PasscodeVC(nibName: Constants.VCID.PASSCODE, bundle: nil)
        
        passcodeVC.modalTransitionStyle   = .coverVertical
        passcodeVC.modalPresentationStyle = .overFullScreen
                
        passcodeVC.folder                 = folder
        passcodeVC.docsVC                 = self
        passcodeVC.isOpenFolder           = true
        
        present(passcodeVC, animated: true, completion: nil)
    }
    
    /// Opens the touch id vc for touch id authentication
    /// - Parameter folder: Folder for which authentication is to be done
    func openTouchIdVC(forFolder folder: DocumentsModel) {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Use your current touch id to unlock folder"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {
                [weak self] success, authenticationError in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if success {
                        self.open(Folder: folder)
                    } else {
                        if let error = authenticationError?.localizedDescription {
                            
                            if error == "Fallback authentication mechanism selected." {
                                
                                self.openPasscodeVC(forFolder: folder)
                                
                            } else if error != "Canceled by user." {
                                self.authFailedAlert(withError: error)
                            }

                        } else {
                            self.authFailedAlert()
                        }
                    }
                }
            }
        } else {
            let alert = UIAlertController(
                title          : "Biometrey Unavailable",
                message        : "Your device is not configured for biometric authentication.",
                preferredStyle : .alert
            )
            
            let okayAction = UIAlertAction(title: "OK", style: .default)
            
            alert.addAction(okayAction)
            present(alert, animated: true)
        }
    }
    
    /// Presents faliure alert
    /// - Parameter error: Message while authentication
    func authFailedAlert(withError error: String = "Authentication failed"){
        let alert = UIAlertController(
            title          : APP_NAME,
            message        : error,
            preferredStyle : .alert
        )
        
        let okayAction = UIAlertAction(title: "OK", style: .default)
        
        alert.addAction(okayAction)
        self.present(alert, animated: true)
    }
    
    ///Verification of user's purchase
    func checkPremiumStatus(){
        if Constants.sharedInstance.isPremiumUser {
            if let expiryDate = Constants.sharedInstance.subscriptionExpiryDate {
                if Date() > expiryDate {
                    showInterstitial()
                    probar(shouldHide: false)
                    Constants.sharedInstance.isPremiumUser = false
                }
            } else {
                verifyPurchase()
            }
        } else {
            showInterstitial()
            probar(shouldHide: false)
            Constants.sharedInstance.isPremiumUser = false
        }
    }
    
    func verifyPurchase(){
        showSpinner(onView: view)
        if let rawValue = Constants.sharedInstance.purchasedIdentifier {
            if let identifier = IAPIdentifiers(rawValue: rawValue) {
                IAPManager.sharedInstance.verifyReceipt(withIdentifier: identifier) { [weak self] state in
                    guard let self = self else { return }
                    
                    self.removeSpinner()
                    
                    switch state {
                    case .purchased:
                        break
                    case .expired, .notPurchased:
                        self.showInterstitial()
                        self.probar(shouldHide: false)
                        Constants.sharedInstance.isPremiumUser = false
                    }
                }
            } else {
                removeSpinner()
                showInterstitial()
                probar(shouldHide: false)
            }
        } else {
            removeSpinner()
            showInterstitial()
            probar(shouldHide: false)
        }
    }
    
    /// Google AdMobs
    func showInterstitial(){
        interstitial = GADInterstitial(adUnitID: INTERSTITIAL_ID)
        
        let request  = GADRequest()
        interstitial.load(request)
        
        shouldPresentAd       = true
        interstitial.delegate = self
    }
    
    func showBanner(){
        bannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
        
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        
        bannerView.delegate           = self
        bannerView.adUnitID           = BANNER_ID
        bannerView.rootViewController = self
        
        bannerView.alpha = 0
        
        bannerView.load(GADRequest())
        
        bannerAdContainerView.addSubview(bannerView)
        
        let bannerViewConstraints: [NSLayoutConstraint] = [
            bannerView.topAnchor.constraint(
                equalTo: bannerAdContainerView.topAnchor
            ),
            bannerView.bottomAnchor.constraint(
                equalTo: bannerAdContainerView.bottomAnchor
            ),
            bannerView.leadingAnchor.constraint(
                equalTo: bannerAdContainerView.leadingAnchor
            ),
            bannerView.trailingAnchor.constraint(
                equalTo: bannerAdContainerView.trailingAnchor
            )
        ]
        
        NSLayoutConstraint.activate(bannerViewConstraints)
    }
    
    /// Rating Popup
    func openRateUsDilogue(){
        if #available(iOS 14, *) {
            if let scene = UIApplication.shared.currentScene {
                SKStoreReviewController.requestReview(in: scene)
            }
        } else {
            SKStoreReviewController.requestReview()
        }
    }
}

/* MARK:- Actions */
extension DocsVC {
    @IBAction func didTapMultiSelection(_ sender: UIButton) {
        if filesAndFolders.count == 0 {/// If there is no file or folder to select show an alert and do nothing
            self.showAlert(title: APP_NAME, message: "Nothing to select")
            return
        }
        setup(multiSelect: true)
    }
    
    @IBAction func didTapCancel(_ sender: UIButton) {
        setup(multiSelect: false)
    }
    
    @IBAction func didTapNewFolder(_ sender: UIButton) {
        let newFolderVC = NewFolderVC(
            nibName: Constants.VCID.NEW_FOLDER,
            bundle : nil
        )
        
        newFolderVC.refrence               = self

        newFolderVC.modalPresentationStyle = .overFullScreen
        newFolderVC.modalTransitionStyle   = .coverVertical
        
        self.present(newFolderVC, animated: true, completion: nil)
    }
    
    @IBAction func didTapSelectAll(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        
        filesAndFolders.enumerated().forEach { (index,_) in
            filesAndFolders[index].isSelected = sender.isSelected
            selectedDoc.remove(at: index)
            selectedDoc.insert(filesAndFolders[index], at: index)
        }
        
        if sender.isSelected {
            titleLbl.text = "\(filesAndFolders.count) item(s) Selected"
        } else {
            titleLbl.text = "0 item(s) Selected"
        }
        
        self.tableView.reloadData()
    }
    
    @IBAction func didTapGetPro(_ sender: UIButton) {
        self.presentPremiumVC(fromVC: .docsVC, andRefrence: self as Any)
    }
}

/* MARK:- TableView */

///DataSource
extension DocsVC: UITableViewDataSource {
    
    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        
        if filesAndFolders.count > 0 {
            self.tableView.isHidden   = false
            self.noDataStack.isHidden = true
        } else {
            self.tableView.isHidden   = true
            self.noDataStack.isHidden = false
        }
        
        ///Setting Docs Count
        totalDocsLbl.text = "My docs (\(filesAndFolders.count))"
        
        return filesAndFolders.count
    }
    
    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(
            withIdentifier: Constants.cellNib.DOCS
        ) as! DocsCell
        
        let index        = indexPath.row
        cell.index       = index
        let fileOrFolder = filesAndFolders[index]
        cell.multiSelect = self.multiSelect
        cell.fileOrFolder  = fileOrFolder
        
        if fileOrFolder.isSelected {
            cell.selectionBtn.isSelected  = true
            cell.selectionImageView.image = UIImage(named: "radio-seleced")
        } else {
            cell.selectionBtn.isSelected  = false
            cell.selectionImageView.image = UIImage(named: "radio-unselected")
        }
        
        cell.didSelect     = { [weak self] document, index, isSelected in
            guard let self = self else { return }
            
            if isSelected {
                self.filesAndFolders[index].isSelected = true
                
                if self.selectedDoc.indices.contains(index){
                    self.selectedDoc.remove(at: index)
                    self.selectedDoc.insert(document, at: index)
                }
            } else {
                self.filesAndFolders[index].isSelected = false
                
                if self.selectedDoc.indices.contains(index){
                    self.selectedDoc.remove(at: index)
                    self.selectedDoc.insert(DocumentsModel(), at: index)
                }
            }
            
            var allAreSelected = true
            self.selectedDoc.forEach { (document) in
                if document.id == 0 {
                    allAreSelected = false
                }
            }
            
            if allAreSelected {
                self.selectAllBtn.isSelected = true
            } else {
                self.selectAllBtn.isSelected = false
            }
            
            self.selectedDocsCount()
            
            ///Logic to decide if show locked or unlocked in the options bar menu
            ///as different folder can have different passwords so we can lock or unlock only one folder at a time.
            let selectedFiles = self.selectedDoc.filter({
                $0.type == DataType.file.rawValue
            })
            
            let selectedFolders = self.selectedDoc.filter({
                $0.type == DataType.folder.rawValue
            })

            let lockedFolders = self.selectedDoc.filter({
                $0.type == DataType.folder.rawValue && $0.lockType != 0
            })

            if selectedFiles.count > 0 { /// As files can't be locked or unlocked we've to disable lock unlock when there is a file
                self.refrenceVC.docOptionsView.show(LockOption: true)
                self.refrenceVC.docOptionsView.lockUnlockOption(isEnabled: false)
            } else {
                if selectedFolders.count == 1 { /// Check if only one folder is selected
                    if selectedFolders.count == lockedFolders.count { /// Check to unlock
                        self.refrenceVC.docOptionsView.show(LockOption: false)
                        self.refrenceVC.docOptionsView.lockUnlockOption(isEnabled: true)
                    } else {  /// Check to lock
                        self.refrenceVC.docOptionsView.show(LockOption: true)
                        self.refrenceVC.docOptionsView.lockUnlockOption(isEnabled: true)
                    }
                } else { /// Check if multiple folders are selected
                    self.refrenceVC.docOptionsView.show(LockOption: true)
                    self.refrenceVC.docOptionsView.lockUnlockOption(isEnabled: false)
                }
            }
            
            
            
            self.tableView.reloadData()
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let index             = indexPath.row
        var dataSource        = filesAndFolders[index]
        dataSource.isSelected = false
        
        if dataSource.type == DataType.folder.rawValue {
            if dataSource.lockType == 0 { /// Not Locked
                open(Folder: dataSource)
            } else if dataSource.lockType == 1 { /// Password Locked
                openPasscodeVC(forFolder: dataSource)
            } else if dataSource.lockType == 2 { /// Touch Id Locked
                openTouchIdVC(forFolder: dataSource)
            }
        } else {
            open(Document: dataSource)
        }
                
    }
    
}

///Delegate
extension DocsVC: UITableViewDelegate {
    
    func tableView(
        _ tableView: UITableView,
        heightForRowAt indexPath: IndexPath
    ) -> CGFloat {
        return 110.0
    }
    
}

///Drag Delegate
extension DocsVC: UITableViewDragDelegate {
    
    func tableView(
        _ tableView: UITableView,
        itemsForBeginning session: UIDragSession,
        at indexPath: IndexPath
    ) -> [UIDragItem] {
        
        let file         = filesAndFolders[indexPath.row]
        
        guard file.type != DataType.folder.rawValue else {
            showAlert(message: "Only files can be move/copy to folders.")
            return []
        }
        
        generator.impactOccurred()
        
        let index        = "\(indexPath.row)"
        guard let data   = index.data(using: .utf8) else { return [] }
        let itemProvider = NSItemProvider(item: data as NSData, typeIdentifier: kUTTypePlainText as String)
        
        return [UIDragItem(itemProvider: itemProvider)]
        
    }
    
}

///Drop Delegate
extension DocsVC: UITableViewDropDelegate {
    
    func tableView(
        _ tableView: UITableView,
        dropSessionDidUpdate session: UIDropSession,
        withDestinationIndexPath destinationIndexPath: IndexPath?
    ) -> UITableViewDropProposal {
        
        return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        
    }
    
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        let destinationIndexPath: IndexPath

        if let indexPath = coordinator.destinationIndexPath {
            destinationIndexPath = indexPath
        } else {
            let section = tableView.numberOfSections - 1
            let row     = tableView.numberOfRows(inSection: section)
            destinationIndexPath = IndexPath(row: row, section: section)
        }
        
        coordinator.session.loadObjects(ofClass: NSString.self) { [weak self] items in
            guard let self = self else {return}
            
            guard let item        = items.first as? String else { return }
            guard let sourceIndex = Int(item) else { return }
            
            let destinationIndex  = destinationIndexPath.row
            
            let file              = self.filesAndFolders[sourceIndex]
            let folder            = self.filesAndFolders[destinationIndex]
            
            guard folder.type != DataType.file.rawValue else {
                self.showAlert(message: "Files can only be move/copy in folders.")
                return
            }
            
            let moveCopyVC = MoveCopyVC(nibName: Constants.VCID.MOVE_COPY, bundle: nil)
         
            moveCopyVC.modalPresentationStyle = .overFullScreen
            moveCopyVC.modalTransitionStyle   = .coverVertical
            
            moveCopyVC.file                   = file
            moveCopyVC.folder                 = folder
            moveCopyVC.docsVC                 = self
            moveCopyVC.isDragDrop             = true
            
            self.present(moveCopyVC, animated: true, completion: nil)
            
        }
    }
    
}

/* MARK:- Scanner */

///Delegate
extension DocsVC: ImageScannerControllerDelegate {
    func imageScannerControllerShouldOpenDoc(_ scanner: ImageScannerController) {
        scanner.dismiss(animated: true) {
            self.getFilesAndFolders()
            self.setup(multiSelect: false)
            
            if let file = self.filesAndFolders.first, file.type == DataType.file.rawValue {
                self.open(Document: file, isAnimated: false, andShowAd: true)
            }
        }
    }
    
    func imageScannerController(
        _ scanner: ImageScannerController,
        didFinishScanningWithResults results: ImageScannerResults
    ) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func imageScannerControllerDidCancel(
        _ scanner: ImageScannerController
    ) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func imageScannerController(
        _ scanner: ImageScannerController,
        didFailWithError error: Error
    ) {
        self.dismiss(animated: true, completion: nil)
    }
}


/* MARK:- Google AdMobs */

/// Interstitial Delegate
extension DocsVC: GADInterstitialDelegate {
    func interstitialDidReceiveAd(_ ad: GADInterstitial) {
        if shouldPresentAd {
            interstitial.present(fromRootViewController: self)
            
            shouldPresentAd = false
        }
    }
    
    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        if Constants.sharedInstance.appOpenCount == 2 {
            openRateUsDilogue()
        }
    }
}

/// Banner Delegate
extension DocsVC: GADBannerViewDelegate {
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        UIView.animate(withDuration: 1, animations: {[weak self] in
            guard let self = self else {return}
            
            self.bannerView.alpha = 1
        })
    }
}
