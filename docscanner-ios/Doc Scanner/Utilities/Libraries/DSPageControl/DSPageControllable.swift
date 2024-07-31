//
//  DSPageControllable.swift
//  Doc Scanner
//
//  Created by M Farhan on 8/18/20.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import Foundation
import CoreGraphics
import UIKit

protocol DSPageControllable: class {
    var numberOfPages       : Int     { get set }
    var currentPage         : Int     { get }
    var progress            : Double  { get set }
    var hidesForSinglePage  : Bool    { get set }
    var borderWidth         : CGFloat { get set }

    func set(progress: Int, animated: Bool)
}
