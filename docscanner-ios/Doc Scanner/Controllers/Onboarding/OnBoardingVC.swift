//
//  OnBoardingVC.swift
//  DialIn
//
//  Created by M Farhan on 3/30/20.
//  Copyright © 2020 DialIn. All rights reserved.
//

import UIKit

class OnBoardingVC: UIViewController {

    /* MARK:- IBOutlets */
    @IBOutlet weak var pageControl    : DSPageControl!
    @IBOutlet weak var collectionView : UICollectionView!
    
    /* MARK:- Properties */
    var timer         : Timer = Timer()
    var scrollAtIndex : Int   = 0
    let numberOfItems : Int   = 3
    /* MARK:- Life Cycle */
    override func viewDidLoad() {
        super.viewDidLoad()
        ///Initilizing view
        initVC()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeTimer()
    }
}

/* MARK:- Methods */
extension OnBoardingVC {
    func initVC() {
        /*  Registering Onboarding Nibs */
        registerOnBoardingNibs()
    }

    func registerOnBoardingNibs() {
        
        let onBoarding1 = UINib(
            nibName: Constants.cellNib.ONBOARDING,
            bundle : nil
        )
        
        collectionView.register(
            onBoarding1,
            forCellWithReuseIdentifier: Constants.cellNib.ONBOARDING
        )
        
        /*  Setup Timer for auto moveable views */
        setupTimer()
    }
    
    /// Timer method to auto scroll onbarding screens
    func setupTimer(){
        timer = Timer.scheduledTimer(
            withTimeInterval: 2.0 ,
            repeats : true        ,
            block   : { [weak self] timer in
                guard let self = self else {return}
                
                if self.scrollAtIndex == (self.numberOfItems - 1) {
                    self.scrollAtIndex = 0
                } else {
                    self.scrollAtIndex += 1
                }
                
                self.pageControl.progress = Double(self.scrollAtIndex)
                let indexPath: IndexPath  = IndexPath(
                    row     : self.scrollAtIndex,
                    section : 0
                )
                
                MAIN_QUEUE.async {
                    self.collectionView.scrollToItem(
                        at       : indexPath,
                        at       : .centeredHorizontally ,
                        animated : true
                    )
                }
                
        })
    }
    
    func removeTimer(){
        timer.invalidate()
    }
}

/* MARK:- Collection View Start */

/* Datasource */
extension OnBoardingVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numberOfItems
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let row  = indexPath.row
        
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier : Constants.cellNib.ONBOARDING,
            for                 : indexPath
        ) as! OnBoardingCell
        
        switch row {
        case 0:
            cell.gifView.image      = UIImage(named: "onboarding-1")
            cell.titleLabel.text    = "Scan"
            cell.subTitleLabel.text = "Turn any document into PDF"
        case 1:
            cell.gifView.image      = UIImage(named: "onboarding-2")
            cell.titleLabel.text    = "OCR"
            cell.subTitleLabel.text = "Photo to text conversation with OCR"
        default:
            cell.gifView.image      = UIImage(named: "onboarding-3")
            cell.titleLabel.text    = "Share"
            cell.subTitleLabel.text = "Share your document anywhere"
        }
        return cell
    }
}

/* Delegate */
extension OnBoardingVC: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        pageControl.progress = Double(Int(scrollView.contentOffset.x) / Int(scrollView.frame.width))
    }
}

/* Layout Delegate */
extension OnBoardingVC: UICollectionViewDelegateFlowLayout {
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        
        let width  = collectionView.bounds.width
        let height = collectionView.frame.height
        let size   = CGSize(width: width, height: height)
        
        return size
    }
    
}

/* MARK:- Actions  */
extension OnBoardingVC {
    @IBAction func didTapGetStarted (_ sender: UIButton) {
        Constants.sharedInstance.regularLaunch = true /// Flag that tell's the app not to start the onboarding again
        let baseVC = BaseVC(nibName: Constants.VCID.BASE, bundle: nil)
        
        self.navigationController?.pushViewController(baseVC, animated: true)
    }
}


