//
//  QuadsModel.swift
//  Doc Scanner
//
//  Created by Umar Farooq on 15/09/2020.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import UIKit

struct QuadsModel {
    let id          : Int32
    let pageId      : Int32
    let topLeft     : CGPoint
    let topRight    : CGPoint
    let bottomLeft  : CGPoint
    let bottomRight : CGPoint
    
    init(
        id           : Int32  ,
        pageId       : Int32  ,
        topLeftX     : Double ,
        topLeftY     : Double ,
        topRightX    : Double ,
        topRightY    : Double ,
        bottomLeftX  : Double ,
        bottomLeftY  : Double ,
        bottomRightX : Double ,
        bottomRightY : Double
    ) {
        self.id          = id
        self.pageId      = pageId
        self.topLeft     = CGPoint(x: topLeftX    , y: topLeftY    )
        self.topRight    = CGPoint(x: topRightX   , y: topRightY   )
        self.bottomLeft  = CGPoint(x: bottomLeftX , y: bottomLeftY )
        self.bottomRight = CGPoint(x: bottomRightX, y: bottomRightY)
    }
    
    init() {
        self.id          = 0
        self.pageId      = 0
        self.topLeft     = CGPoint(x: 0, y: 0)
        self.topRight    = CGPoint(x: 0, y: 0)
        self.bottomLeft  = CGPoint(x: 0, y: 0)
        self.bottomRight = CGPoint(x: 0, y: 0)
    }
}
