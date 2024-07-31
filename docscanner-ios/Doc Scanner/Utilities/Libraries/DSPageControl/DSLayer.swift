//
//  DSLayer.swift
//  Doc Scanner
//
//  Created by M Farhan on 8/18/20.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import QuartzCore

class DSLayer: CAShapeLayer {
    override init() {
        super.init()
        self.actions = [
            "bounds"  : NSNull(),
            "frame"   : NSNull(),
            "position": NSNull()
        ]
    }
    
    override public init(layer: Any) {
        super.init(layer: layer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
