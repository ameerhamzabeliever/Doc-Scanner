//
//  Canvas.swift
//  Artfora
//
//  Created by cellzone on 8/29/19.
//  Copyright © 2019 Umar Farooq. All rights reserved.
//

import UIKit

class DrawingView: UIView {
    
    /* MARK:- Properties */
    var touch     : UITouch!
    var lineArray : [[CGPoint]] = [[CGPoint]()]
    var lineWidth : CGFloat     = 4
    
    public var signature : CGImage?
    public var lineColor : CGColor = #colorLiteral(red: 0.03137254902, green: 0.5333333333, blue: 0.9725490196, alpha: 1)
    
    var index = -1
    
    init(lineColor: CGColor) {
        self.lineColor = lineColor
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        touch = touches.first! as UITouch
        let lastPoint = touch.location(in: self)
        
        index += 1
        lineArray.append([CGPoint]())
        lineArray[index].append(lastPoint)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        touch = touches.first! as UITouch
        let currentPoint = touch.location(in: self)
        
        self.setNeedsDisplay()
        
        lineArray[index].append(currentPoint)
    }
    
    override func draw(_ rect: CGRect) {
        
        if(index >= 0){
            guard let context = UIGraphicsGetCurrentContext() else { return }
            context.setLineWidth(lineWidth)
            context.setStrokeColor(lineColor)
            context.setLineCap(.round)
            
            var j = 0
            while( j <= index ){
                context.beginPath()
                var i = 0
                context.move(to: lineArray[j][0])
                while(i < lineArray[j].count){
                    context.addLine(to: lineArray[j][i])
                    i += 1
                }
                context.strokePath()
                signature = context.makeImage()
                j += 1
            }
        }
    }
}
