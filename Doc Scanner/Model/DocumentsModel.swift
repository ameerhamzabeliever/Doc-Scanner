//
//  DocumentsModel.swift
//  Doc Scanner
//
//  Created by Umar Farooq on 07/09/2020.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import Foundation

struct DocumentsModel {
    let id         : Int32
    let name       : String
    let type       : String
    let pages      : [PagesModel]
    let folderId   : Int32
    let createdAt  : Date
    let lockType   : Int16 /// 0 = Unlocked | 1 = Password | 2 = Touch ID
    let password   : String
    
    let totalFiles : Int
    var isSelected : Bool = false
    
    init(
        id         : Int32        ,
        name       : String       ,
        type       : String       ,
        pages      : [PagesModel] ,
        folderId   : Int32        ,
        createdAt  : Date         ,
        lockType   : Int16        ,
        password   : String       ,
        totalFiles : Int          = 0
    ) {
        self.id         = id
        self.name       = name
        self.type       = type
        self.pages      = pages
        self.folderId   = folderId
        self.createdAt  = createdAt
        self.lockType   = lockType
        self.password   = password
        self.totalFiles = totalFiles
    }
    
    init() {
        self.id         = Int32(0)
        self.name       = "Dashboard"
        self.type       = ""
        self.pages      = []
        self.folderId   = Int32(0)
        self.createdAt  = Date()
        self.lockType   = 0
        self.password   = ""
        self.totalFiles = 0
    }
}
