//
//  SingleDocVC.swift
//  Doc Scanner
//
//  Created by M Farhan on 8/18/20.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import UIKit
import PDFKit

class DocFolderVC: UIViewController {

    /* MARK:- IBOutlets  */
    @IBOutlet weak var collectionView : UICollectionView!
    @IBOutlet weak var proBarView     : UIView!
    
    ///StackView
    @IBOutlet weak var noDataStack    : UIStackView!
    
    ///Label
    @IBOutlet weak var titleLbl       : UILabel!
    
    ///Buttons
    @IBOutlet weak var cancelBtn      : UIButton!
    @IBOutlet weak var backBtn        : UIButton!
    @IBOutlet weak var selectAllBtn   : UIButton!
    
    /* MARK:- Lazy Properties */
    lazy var cellNib: UINib = {
        return UINib(nibName: Constants.cellNib.DOC_FOLDER, bundle: nil)
    }()
    
    /* MARK:- Computed Properties */
    var cellSize: CGSize {
        get {
            let totalWidth = collectionView.frame.width * 0.85
            let width      = totalWidth/3
            let height     = width * 1.0754717
            return CGSize(width: width, height: height)
        }
    }
    
    /* MARK:- Properties */
    var files         : [DocumentsModel] = [] /// All Files in this folder
    var selectedFiles : [DocumentsModel] = [] /// Selected Files in this folder
    var document      : DocumentsModel! /// Folder information
    var multiSelect   : Bool = false
    
    var docFolderOptions: DocFolderOptions = DocFolderOptions()
    
    /* MARK:- Closues */
    var didNeedsRefresh      : (()->())?
    
    ///Options Bar
    var didTapLockButton     : (()->())?
    var didTapMergeButton    : (()->())?
    var didTapShareButton    : (()->())?
    var didTapDeleteButton   : (()->())?
    var didTapMoveCopyButton : (()->())?
    
    /* MARK:- Lifecycle */
    override func viewDidLoad() {
        super.viewDidLoad()
        initVC()///Initilizing Views
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getFiles()
    }

    deinit {
        Helper.debugLogs(any: "Sucessfully deinit Doc Folder VC")
    }
}

/* MARK:- Methods */
extension DocFolderVC {
    private func initVC(){
        ///ProBar View Design Setup
        MAIN_QUEUE.asyncAfter(deadline: .now() + 0.05) {
            self.proBarView.layer.cornerRadius = self.proBarView.frame.height / 2.0
        }
        ///Cell Registeration
        registerCell()
        
        ///Refreshing Data
        didNeedsRefresh = { [weak self] in
            guard let self = self else {return}
            self.getFiles()
            self.setup(multiSelect: false)
        }
        
        ///Option Bar Closure Methods
        optionBarClosures()
    }
    
    private func registerCell(){
        collectionView.register(cellNib, forCellWithReuseIdentifier: Constants.cellNib.DOC_FOLDER)
        getFiles()
    }
    
    private func optionBarClosures() {
        ///Share Button Action
        didTapShareButton = { [weak self] in
            guard let self = self else {return}
            
            let selectedDocs = self.selectedFiles.filter({ $0.id != Int32(0) })///Filter to get only actual selected files
            if selectedDocs.count < 1 {
                self.showAlert(message: "Please select document(s) to share.")
                return
            }
            
            var pageNo : Int         = 0
            let pdfDoc : PDFDocument = PDFDocument()
            
            selectedDocs.forEach { (document) in
                document.pages.forEach { (page) in
                    if let docImage = PDFDocument(data: page.enhancedImage) {
                        
                        if !Constants.sharedInstance.isPremiumUser {
                            docImage.delegate = self
                        }
                        
                        if let page = docImage.page(at: 0) {
                            pdfDoc.insert(
                                page,
                                at: pageNo
                            )
                            
                            pageNo += 1
                        }
                    }
                }
            }
            
            if let pdfData = pdfDoc.dataRepresentation() {
                self.share(PdfFiles: [pdfData])
            }
        }
        
        ///Merge Button Action
        didTapMergeButton = { [weak self] in
            guard let self = self else {return}
            
            let selectedDocs = self.selectedFiles.filter({ $0.id != Int32(0) })///Filter to get only actual selected files
            if selectedDocs.count < 2 {
                self.showAlert(message: "Please select atleast 2 documents to be merged.")
                return
            }
            
            let mergeVC = MergeVC(nibName: Constants.VCID.MERGE, bundle: nil)
            
            mergeVC.modalPresentationStyle = .overFullScreen
            mergeVC.modalTransitionStyle   = .coverVertical
            
            mergeVC.docFolderVC            = self
            mergeVC.selectedDocs           = self.selectedFiles
            
            self.present(mergeVC, animated: true, completion: nil)
        }
        
        ///Move Button Action
        didTapMoveCopyButton = { [weak self] in
            guard let self = self else {return}
            
            let selectedDocs = self.selectedFiles.filter({ $0.id != Int32(0) })///Filter to get only actual selected files
            if selectedDocs.count < 1 {
                self.showAlert(message: "Please select document(s) to copy/move.")
                return
            }
            
            let moveCopyVC = MoveCopyVC(nibName: Constants.VCID.MOVE_COPY, bundle: nil)
         
            moveCopyVC.modalPresentationStyle = .overFullScreen
            moveCopyVC.modalTransitionStyle   = .coverVertical
            
            moveCopyVC.docFolderVC             = self
            
            self.present(moveCopyVC, animated: true, completion: nil)
        }
        ///Delete Action
        didTapDeleteButton = { [weak self] in
            guard let self = self else { return }
            
            let selectedDocs = self.selectedFiles.filter({ $0.id != Int32(0) })///Filter to get only actual selected files
            if selectedDocs.count < 1 {
                self.showAlert(message: "Please select document)s) to delete.")
                return
            }
            
            for doc in self.selectedFiles {
                ///Deleting PDF
                if doc.id != Int32(0) {
                    CBFileManager.sharedInstance.deleteData(
                        key     : "id",
                        value   : doc.id,
                        entity  : DOCUMENTS
                    ) { (isFinished) in
                        
                        if isFinished {
                            for page in doc.pages {
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
                                            self.getFiles()
                                            self.setup(multiSelect: false)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                }
            }
        }
    }
    
    func getFiles(shouldResetView resetView: Bool = false){
        files.removeAll()///Removing old data inorder to overcome redundancy
        
        let keyVal : [String: String] = ["folder_id": "\(document.id)"]
        
        files = CBFileManager.sharedInstance.retrieveFilesFolders(
            shouldAddCondition: true,
            withKeyAndValue   : keyVal,
            ofType            : nil
        )
        
        ///Initilizing Selected Files  Array
        files.forEach { (_) in
            selectedFiles.append(DocumentsModel())
        }
        
        self.collectionView.reloadData()
        
        if resetView{
            setup(multiSelect: false)
        }
    }
    
    func setup(multiSelect bool: Bool) {
        if bool {
            multiSelect           = true
            titleLbl.text         = "0 item(s) Selected"
            backBtn.isHidden      = true
            cancelBtn.isHidden    = false
            selectAllBtn.isHidden = false
            
            loadOptionsView()
        } else {
            multiSelect           = false
            titleLbl.text         = APP_NAME
            backBtn.isHidden      = false
            cancelBtn.isHidden    = true
            selectAllBtn.isHidden = true
            
            selectedFiles.removeAll()
            selectAllBtn.setTitle("Select All", for: .normal)
            files.enumerated().forEach { (index,item) in
                files[index].isSelected = false
                selectedFiles.append(DocumentsModel())
            }
            
            removeOptionsView()
        }
        
        collectionView.reloadData()
    }
    
    func selectedDocsCount() {
        var totalSelecedDocs = 0
        
        files.forEach { (item) in
            if item.isSelected {
                totalSelecedDocs += 1
            }
        }
        
        titleLbl.text = "\(totalSelecedDocs) item(s) Selected" 
    }
    
    func openDocVC(withDocAt index: Int){
        let docVC       = DocVC(nibName: Constants.VCID.DOC, bundle: nil)
        docVC.document  = files[index]
        
        self.navigationController?.pushViewController(docVC, animated: true)
    }
    
    func share(PdfFiles files: [Any]){
        let activityVC = UIActivityViewController(activityItems: files, applicationActivities: nil)
        self.present(activityVC, animated: true, completion: nil)
    }
    
    ///Docs Folder Options View Load and Remove
    
    func loadOptionsView(){
        if let loadedNib = Bundle.main.loadNibNamed(
            Constants.VIEW.DOC_FOLDER_OPTIONS,
            owner   : self,
            options : nil
        ) {
            
            if let docFolderOptions = loadedNib.first as? DocFolderOptions {
                ///Setting proportional frame
                let width       = SCREEN_WIDTH * 0.91945894
                let height      = CGFloat(70.0)
                let x           = self.view.center.x - (width/2)
                let y           = SCREEN_HEIGHT * 0.85714246
                
                docFolderOptions.frame = CGRect(
                    x      : x,
                    y      : y,
                    width  : width,
                    height : height
                )
                
                ///Passing self refrence to call closures
                docFolderOptions.docFolderVC = self
                ///Adding Identifire
                docFolderOptions.accessibilityIdentifier = Constants.VIEW.DOC_FOLDER_OPTIONS
                ///Adding Corner Radius
                docFolderOptions.layer.cornerRadius = docFolderOptions.frame.height/2
                ///Initilizing tabBar
                docFolderOptions.initView()
                ///Assining to class scope variable
                self.docFolderOptions = docFolderOptions
                ///Adding into view
                self.view.addSubview(docFolderOptions)
            }
            
        }
    }
    
    func removeOptionsView() {
        self.view.subviews.forEach { (view) in
            if view.accessibilityIdentifier == Constants.VIEW.DOC_FOLDER_OPTIONS {
                view.removeFromSuperview()
            }
        }
    }
}

/* MARK:- Actions */
extension DocFolderVC {
    @IBAction func didTapCancel(_ sender: UIButton) {
        setup(multiSelect: false)
    }
    
    @IBAction func didTapBack(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func didTapSelectAll(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        
        files.enumerated().forEach { (index,_) in
            files[index].isSelected = sender.isSelected
            selectedFiles.remove(at: index)
            selectedFiles.insert(files[index], at: index)
        }
        
        if sender.isSelected {
            titleLbl.text = "\(files.count) item(s) Selected"
            docFolderOptions.show(MultipleSelectedOptions: true)
        } else {
            titleLbl.text = "0 item(s) Selected"
            docFolderOptions.show(MultipleSelectedOptions: false)
        }
        
        self.collectionView.reloadData()
    }
    
    @IBAction func didTapGetPro(_ sender: UIButton) {
        let premiumVC = PremiumPopUp(nibName: Constants.VCID.PREMIUM_POPUP, bundle: nil)
        
        premiumVC.modalTransitionStyle   = .coverVertical
        premiumVC.modalPresentationStyle = .overFullScreen
        
        self.present(premiumVC, animated: true, completion: nil)
    }
}

/* MARK:- PDF Document */

//Delegate
extension DocFolderVC: PDFDocumentDelegate {
    func classForPage() -> AnyClass {
        return WatermarkPage.self
    }
}

/* MARK:- TableView */

///DataSource
extension DocFolderVC: UICollectionViewDataSource {
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        if files.count > 0 {
            self.collectionView.isHidden = false
            self.noDataStack.isHidden    = true
        } else {
            self.collectionView.isHidden = true
            self.noDataStack.isHidden    = false
        }
        
        return files.count
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier : Constants.cellNib.DOC_FOLDER,
            for                 : indexPath
        ) as! DocFolderCell
        
        let index        = indexPath.row
        cell.index       = index
        cell.multiSelect = self.multiSelect
        let document     = files[index]
        cell.document    = document
        
        if document.isSelected {
            cell.selectionBtn.isSelected  = true
            cell.selectionimageV.image    = UIImage(named: "radio-seleced")
        } else {
            cell.selectionBtn.isSelected  = false
            cell.selectionimageV.image    = UIImage(named: "radio-unselected")
        }
        
        /* MARK:- Closures Implementations Start */
        cell.didTap = { [weak self] index in
            guard let self = self else { return }
            self.openDocVC(withDocAt: index)
        }
        
        cell.didSelect = { [weak self]  document, index, isSelected in
            guard let self = self else { return }
            
            if isSelected {
                self.files[index].isSelected = true
                
                if self.selectedFiles.indices.contains(index){
                    self.selectedFiles.remove(at: index)
                    self.selectedFiles.insert(document, at: index)
                }
            } else {
                self.files[index].isSelected = false
                
                if self.selectedFiles.indices.contains(index){
                    self.selectedFiles.remove(at: index)
                    self.selectedFiles.insert(DocumentsModel(), at: index)
                }
            }
            
            var allAreSelected = true
            self.selectedFiles.forEach { (document) in
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
            
            ///Logic to decide either the ADD and EDIT should be enabled or disabled
            let actualSelectedDocs = self.selectedFiles.filter({ $0.id != Int32(0)})
            
            if actualSelectedDocs.count > 1 {
                self.docFolderOptions.show(MultipleSelectedOptions: true)
            } else {
                self.docFolderOptions.show(MultipleSelectedOptions: false)
            }
            
            self.collectionView.reloadData()
        }
        
        cell.didTapAndHold = { [weak self] in
            guard let self = self else { return }
            self.setup(multiSelect: true)
        }
        /* Closures Implementations End */
        
        return cell
    }
}

///Delegate
extension DocFolderVC: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView            : UICollectionView,
        layout collectionViewLayout : UICollectionViewLayout,
        sizeForItemAt indexPath     : IndexPath
    ) -> CGSize {
        
        return cellSize
    
    }
    
    func collectionView(
        _ collectionView            : UICollectionView      ,
        layout collectionViewLayout : UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        
        return 20.0
        
    }
}
