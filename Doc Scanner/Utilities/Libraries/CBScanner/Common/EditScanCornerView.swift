//
//  EditScanCornerView.swift
//  WeScan
//
//  Created by Boris Emorine on 3/5/18.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import UIKit

/// A UIView used by corners of a quadrilateral that is aware of its position.
final class EditScanCornerView: UIView {
    
    let position: CornerPosition
    
    /// The image to display when the corner view is highlighted.
    private var image: UIImage?
    private(set) var isHighlighted = false
    
    private lazy var circleLayer: CAShapeLayer = {
        let layer           = CAShapeLayer()
        layer.fillColor     = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        layer.strokeColor   = #colorLiteral(red: 0.03137254902, green: 0.5647058824, blue: 0.9725490196, alpha: 1)
        layer.lineWidth     = 2.0
        return layer
    }()

    /// Set stroke color of coner layer
    public var strokeColor: CGColor? {
        didSet {
            circleLayer.strokeColor = strokeColor
        }
    }
    
    init(frame: CGRect, position: CornerPosition) {
        self.position = position
        super.init(frame: frame)
        backgroundColor = UIColor.clear
        clipsToBounds   = true
        layer.addSublayer(circleLayer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.width / 2.0
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let bezierPath = UIBezierPath(ovalIn: rect.insetBy(dx: circleLayer.lineWidth, dy: circleLayer.lineWidth))
        circleLayer.frame = rect
        circleLayer.path = bezierPath.cgPath
        
        image?.draw(in: rect)
    }
    
    func highlightWithImage(_ image: UIImage) {
        isHighlighted         = true
        self.image            = image
        circleLayer.fillColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
        self.setNeedsDisplay()
    }
    
    func reset() {
        isHighlighted         = false
        image                 = nil
        circleLayer.fillColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        setNeedsDisplay()
    }
    
}
