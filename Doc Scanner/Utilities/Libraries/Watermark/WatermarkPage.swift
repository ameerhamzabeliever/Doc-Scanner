//
//  WatermarkPage.swift
//  Doc Scanner
//
//  Created by Umar Farooq on 8/18/20.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import PDFKit
import Foundation

class WatermarkPage: PDFPage {

    override func draw(with box: PDFDisplayBox, to context: CGContext) {
        // Draw original content
        super.draw(with: box, to: context)

        // Draw rotated overlay string
        UIGraphicsPushContext(context)
        context.saveGState()

        let pageBounds = self.bounds(for: box)
        
        context.translateBy(
            x: 0.0,
            y: pageBounds.size.height
        )
        
        context.scaleBy(
            x: 1.0,
            y: -1.0
        )
        
        context.rotate(
            by: 0.0
        )

        let string     : NSString = "Scanned with Doc Scanner"
        let attributes : [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.2862745098, green: 0.2862745098, blue: 0.2862745098, alpha: 1),
            NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 30)
        ]

        let size = string.size(withAttributes: attributes)
        string.draw(
            at: CGPoint(
                x: pageBounds.maxX - (size.width + 50),
                y: pageBounds.maxY - (size.height + 50)
            ),
            withAttributes: attributes
        )

        context.restoreGState()
        UIGraphicsPopContext()
    }
    
}
