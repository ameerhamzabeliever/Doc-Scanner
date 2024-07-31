//
//  IAPProductModel.swift
//  Doc Scanner
//
//  Created by Umar Farooq on 12/10/2020.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import Foundation

struct IAPProductModel: Codable {
    let id    : String
    let price : String
    
    init(id: String, price: String) {
        self.id    = id
        self.price = price
    }
}
