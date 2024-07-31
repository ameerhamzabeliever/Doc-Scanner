//
//  Filter.swift
//  CIFilterImage
//
//  Created by Tsubasa Hayashi on 2019/03/29.
//  Copyright © 2019 Tsubasa Hayashi. All rights reserved.
//

import UIKit
import CoreImage

public struct Filter {
    let name         : String
    let ciFilterName : String?

    public init(name: String, ciFilterName: String?) {
        self.name         = name
        self.ciFilterName = ciFilterName
    }
}

extension Filter: Equatable {
    public static func ==(lhs: Filter, rhs: Filter) -> Bool {
        return lhs.name == rhs.name
    }
}

extension Filter {
    static var all: [Filter] = [
        Filter(name: "ORIGINAL" , ciFilterName: nil                       ),
        Filter(name: "CHROME"   , ciFilterName: "CIPhotoEffectChrome"     ),
        Filter(name: "FADE"     , ciFilterName: "CIPhotoEffectFade"       ),
        Filter(name: "INSTANT"  , ciFilterName: "CIPhotoEffectInstant"    ),
        Filter(name: "MONO"     , ciFilterName: "CIPhotoEffectMono"       ),
        Filter(name: "NOIR"     , ciFilterName: "CIPhotoEffectNoir"       ),
        Filter(name: "PROCESS"  , ciFilterName: "CIPhotoEffectProcess"    ),
        Filter(name: "TONAL"    , ciFilterName: "CIPhotoEffectTonal"      ),
        Filter(name: "TRANSFER" , ciFilterName: "CIPhotoEffectTransfer"   ),
        Filter(name: "TONE"     , ciFilterName: "CILinearToSRGBToneCurve" ),
        Filter(name: "LINEAR"   , ciFilterName: "CISRGBToneCurveToLinear" ),
        Filter(name: "SEPIA"    , ciFilterName: "CISepiaTone"             )
    ]
}

