//
//  EditImageCell.swift
//  Doc Scanner
//
//  Created by M Farhan on 8/31/20.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import UIKit
import AVKit

class EditImageCell: UICollectionViewCell {
    /* MARK:- @IBOutlet */
    @IBOutlet weak var editView                 : UIView!
    @IBOutlet weak var editLabel                : UILabel!
    @IBOutlet weak var editButton               : UIButton!
    @IBOutlet weak var scanedImageContainerView : UIView!
    
    /* MARK:- Properties */
    var index: Int!
    var quad : Quadrilateral?
    var image: UIImage? {
        didSet {
            configureCell()
        }
    }
    var refrenceVC  : EditScanVC!
    var lastQuad    = Quadrilateral(
        topLeft     : CGPoint(x: 0.0, y: 0.0),
        topRight    : CGPoint(x: 0.0, y: 0.0),
        bottomRight : CGPoint(x: 0.0, y: 0.0),
        bottomLeft  : CGPoint(x: 0.0, y: 0.0)
    )
    
    var touchDown                = UILongPressGestureRecognizer()
    var didStartEditing          = true
    var shouldRecognizeGesture   = false
    var quadViewWidthConstraint  = NSLayoutConstraint()
    var quadViewHeightConstraint = NSLayoutConstraint()
    
    /* MARK:- Lazy Properties */
    public lazy var imageView: UIImageView = {
        let imageView               = UIImageView()
        imageView.clipsToBounds     = true
        imageView.isOpaque          = true
        imageView.backgroundColor   = #colorLiteral(red: 0.9568627451, green: 0.9568627451, blue: 0.9725490196, alpha: 1)
        imageView.contentMode       = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    public lazy var quadView: QuadrilateralView = {
        let quadView      = QuadrilateralView()
        quadView.editable = true
        quadView.translatesAutoresizingMaskIntoConstraints = false
        return quadView
    }()
    
    /* MARK:- Properties */
    private var zoomGestureController : ZoomGestureController!
    
    override func layoutSubviews() {
        if didStartEditing {
            adjustQuadViewConstraints()
            displayQuad()            
        }
    }
    
    override func prepareForReuse() {
        resetCell()
        super.prepareForReuse()
    }
    
}

/* MARK:- Methods */
extension EditImageCell {
    func configureCell() {
        MAIN_QUEUE.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self = self else { return }
            self.editView.layer.cornerRadius = self.editView.frame.height/2
        }
        
        if let image = image {
            imageView.image = image
            
            scanedImageContainerView.addSubview(imageView)
            scanedImageContainerView.addSubview(quadView)
            
            setupConstraints()
            
            zoomGestureController = ZoomGestureController(
                image    : image,
                quadView : quadView
            )
            
            let touchDown = UILongPressGestureRecognizer(
                target: zoomGestureController,
                action: #selector(zoomGestureController.handle(pan:))
            )
            
            touchDown.delegate             = self
            touchDown.minimumPressDuration = 0
            scanedImageContainerView.addGestureRecognizer(touchDown)
        }
    }
    
    func resetCell(){
        quad            = nil
        quadView.quad   = nil
        imageView.image = nil
        
        for subview in scanedImageContainerView.subviews {
            subview.removeFromSuperview()
        }
        
        scanedImageContainerView.removeGestureRecognizer(touchDown)
        
        editButton.isSelected  = true
        didStartEditing        = true
        editLabel.text         = "  Edit  "
        shouldRecognizeGesture = false
    }
    
    func setupConstraints() {
        for constraint in quadView.constraints {
            quadView.removeConstraint(constraint)
        }
        
        for constraint in imageView.constraints {
            imageView.removeConstraint(constraint)
        }
        
        let imageViewConstraints = [
            imageView.topAnchor.constraint(
                equalTo: scanedImageContainerView.topAnchor
            ),
            imageView.trailingAnchor.constraint(
                equalTo: scanedImageContainerView.trailingAnchor
            ),
            imageView.bottomAnchor.constraint(
                equalTo: scanedImageContainerView.bottomAnchor
            ),
            imageView.leadingAnchor.constraint(
                equalTo: scanedImageContainerView.leadingAnchor
            )
        ]
        
        if quadViewWidthConstraint.constant == 0 {
            quadViewWidthConstraint  = quadView.widthAnchor.constraint(
                equalToConstant: 0.0
            )
            quadViewHeightConstraint = quadView.heightAnchor.constraint(
                equalToConstant: 0.0
            )
        }
        
        let quadViewConstraints = [
            quadView.centerXAnchor.constraint(
                equalTo: scanedImageContainerView.centerXAnchor
            ),
            quadView.centerYAnchor.constraint(
                equalTo: scanedImageContainerView.centerYAnchor
            ),
            quadViewWidthConstraint,
            quadViewHeightConstraint
        ]
        
        NSLayoutConstraint.activate(quadViewConstraints + imageViewConstraints)
        
        setNeedsDisplay()
        layoutIfNeeded()
    }
    
    ///Layout Methods
    func adjustQuadViewConstraints() {
        if let image = image {
            let frame = AVMakeRect(
                aspectRatio: image.size,
                insideRect : imageView.bounds
            )
            
            quadViewWidthConstraint.constant  = frame.size.width
            quadViewHeightConstraint.constant = frame.size.height
        }
    }
    
    func displayQuad() {
        if let image      = image {
            let imageSize = image.size
            
            let imageFrame = CGRect(
                origin: quadView.frame.origin,
                size  : CGSize(
                    width : quadViewWidthConstraint.constant,
                    height: quadViewHeightConstraint.constant
                )
            )
            
            let scaleTransform = CGAffineTransform.scaleTransform(
                forSize          : imageSize,
                aspectFillInSize : imageFrame.size
            )
            
            let transforms      = [scaleTransform]
            let transformedQuad = quad!.applyTransforms(transforms)
            
            quadView.drawQuadrilateral(
                quad    : transformedQuad,
                animated: true
            )
            
            Helper.debugLogs(any: frame, and: "QuadView Frame Set")
            
            refrenceVC.didSetQuadView?(index,quadView)
        }
    }
}

/* MARK:- Actions */
extension EditImageCell {
    
    @IBAction func toggleEdit(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        
        if sender.isSelected {
            didStartEditing        = true
            editLabel.text         = "  Editing  "
            shouldRecognizeGesture = true
        } else {
            didStartEditing        = false
            editLabel.text         = "  Edit  "
            shouldRecognizeGesture = false
        }
    }
    
}

/* MARK:- Gesture Recognizer */

///Delegate
extension EditImageCell: UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(
        _ gestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return shouldRecognizeGesture
    }
}
