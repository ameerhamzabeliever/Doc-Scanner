//
//  PagesModel.swift
//  Doc Scanner
//
//  Created by Umar Farooq on 15/09/2020.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import Foundation

struct PagesModel {
    let id            : Int32
    let quad          : QuadsModel
    let fileId        : Int32
    let originalImage : Data
    let croppedImage  : Data
    let enhancedImage : Data
    let scannerType   : String
    let pageSize      : String
    
    init(
        id            : Int32      ,
        quad          : QuadsModel ,
        fileId        : Int32      ,
        originalImage : Data       ,
        croppedImage  : Data       ,
        enhancedImage : Data       ,
        scannerType   : String     ,
        pageSize      : String     
    ) {
        self.id             = id
        self.quad           = quad
        self.fileId         = fileId
        self.originalImage  = originalImage
        self.croppedImage   = croppedImage
        self.enhancedImage  = enhancedImage
        self.scannerType    = scannerType
        self.pageSize       = pageSize
    }
    
    init() {
        self.id             = Int32(0)
        self.quad           = QuadsModel()
        self.fileId         = Int32(0)
        self.originalImage  = Data()
        self.croppedImage   = Data()
        self.enhancedImage  = Data()
        self.scannerType    = ""
        self.pageSize       = ""
    }
}
