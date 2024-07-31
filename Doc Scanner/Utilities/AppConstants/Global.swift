//
//  Global.swift
//  DialIn
//
//  Created by Umar Farooq Nadeem on 3/20/20.
//  Copyright © 2020 DialIn. All rights reserved.
//

import UIKit
import SwiftyStoreKit

/* MARK:- Constants */
var SPINNER           : [UIView] = []
let APP_NAME          = "Doc Scanner"
let DEFAULTS          = UserDefaults.standard
let MAIN_QUEUE        = DispatchQueue.main
let BG_QUEUE          = DispatchQueue.global(qos: .background)
let APPDELEGATE       = UIApplication.shared.delegate as! AppDelegate
let SCREEN_WIDTH      = UIScreen.main.bounds.width
let SCREEN_HEIGHT     = UIScreen.main.bounds.height
let APP_LINK          = "https://itunes.apple.com/app/"
let APP_ID            = "id1040093707"

/* MARK:- Admobs Constants */
let BANNER_ID       = "ca-app-pub-7317859624855766/5854468318"
let INTERSTITIAL_ID = "ca-app-pub-7317859624855766/4404998738"
let GAD_APP_ID      = "ca-app-pub-7317859624855766~4996805925"

/* MARK:- IAP Constants */
let SHARED_SECRET = "c825bd4666d54611bf8d611a13909ffc"
let IAP_MODE : AppleReceiptValidator.VerifyReceiptURLType = .sandbox

/* MARK:- Core Data Entities */
let PAGES     = "Pages"
let QUADS     = "Quads"
let DOCUMENTS = "Documents"

/* MARK:- Storyboards */
let MAIN_STORYBOARD : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)

/* MARK:- Application Enum */
enum CurrentDeviceType {
    case iPad
    case bezelLessiPhone
    case bezeliPhone
}

enum TabBarVC: String {
    case docs     = "Docs"
    case settings = "Settings"
}

enum SignatureType: String {
    case draw = "Draw"
    case type = "Type"
}

enum DataType: String {
    case file   = "file"
    case folder = "folder"
}

enum StartAppWith: String {
    case scanner   = "scanner"
    case documents = "documents"
}

enum PictureQuality: String {
    case low      = "low"
    case medium   = "medium"
    case high     = "high"
    case original = "original"
}

///IAP
enum IAPIdentifiers: String {
    case weekly  = "com.pttgames.bizscanner.oneWeekSubsNew"
    case monthly = "com.pttgames.bizscanner.oneMonthSubs"
    case yearly  = "com.pttgames.bizscanner.oneYearSubs"
}

enum IAPState {
    case purchased
    case expired
    case notPurchased
}

enum VCToBeUpdated {
    case docVC
    case docsVC
    case settingsVC
    case appPinVC
    case scanningOptionsVC
    case startAppWithVC
    case pictureQualityVC
}

///Scanner
enum ScannerType: String {
    case passport    = "Passport"
    case idCard      = "ID Card"
    case batch       = "Batch"
    case single      = "Single"
    case imageToText = "Image to Text"
}

enum PageSize: String {
    case legal        = "Legal"
    case original     = "Original"
    case a4           = "A4"
    case a5           = "A5"
    case businessCard = "Business Card"
}

/// AdMobs
enum AdTypes: String {
    case banner       = "banner"
    case interstitial = "interstitial"
}

/* MARK:- Application ENV */
let ENV = "staging"

let SERVER_ENV = [
    "staging"     : "",
    "production"  : ""
]
