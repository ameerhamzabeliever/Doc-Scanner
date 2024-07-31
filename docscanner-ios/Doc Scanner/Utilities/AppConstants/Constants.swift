//
//  Constants.swift
//  DialIn
//
//  Created by Umar Farooq Nadeem on 3/20/20.
//  Copyright © 2020 DialIn. All rights reserved.
//

import UIKit

struct Constants {
    /* MARK:- Singleton struct initilization */
    static var sharedInstance : Constants = Constants()
    
    var appOpenCount: Int {
        get {
            if let permission = DEFAULTS.value(
                forKey: Constants.userDefaults.APP_OPEN_COUNT
            ) as? Int {
                return permission
            }
            
            return 0
        } set {
            DEFAULTS.set(newValue, forKey: Constants.userDefaults.APP_OPEN_COUNT)
        }
    }
    
    var startAppWith: String {
        get {
            if let identifier = DEFAULTS.value(
                forKey: Constants.userDefaults.START_APP_WITH
            ) as? String {
                return identifier
            }
            
            return "documents"
        } set {
            DEFAULTS.setValue(newValue, forKey: Constants.userDefaults.START_APP_WITH)
        }
    }
    
    var timesShared: [String: Any] {
        get {
            if let identifier = DEFAULTS.value(
                forKey: Constants.userDefaults.TIMES_SHARED
            ) as? [String: Any] {
                return identifier
            }
            
            return [:]
        } set {
            DEFAULTS.setValue(newValue, forKey: Constants.userDefaults.TIMES_SHARED)
        }
    }
    
    var topVC: UIViewController? {
        get {
            return UIApplication.topViewController()
        }
    }
    
    var pictureQuality: String {
        get {
            if let identifier = DEFAULTS.value(
                forKey: Constants.userDefaults.PICTURE_QUALITY
            ) as? String {
                return identifier
            }
            
            return "high"
        } set {
            DEFAULTS.setValue(newValue, forKey: Constants.userDefaults.PICTURE_QUALITY)
        }
    }
    
    var cameraPermission: Bool {
        get {
            if let permission = DEFAULTS.value(
                forKey: Constants.userDefaults.CAMERA_PERMISSION
            ) as? Bool {
                return permission
            }
            
            return false
        } set {
            DEFAULTS.set(newValue, forKey: Constants.userDefaults.CAMERA_PERMISSION)
        }
    }
    
    var photoGalleryPermission: Bool {
        get {
            if let permission = DEFAULTS.value(
                forKey: Constants.userDefaults.PHOTO_GALLERY_PERMISSION
            ) as? Bool {
                return permission
            }
            
            return false
        } set {
            DEFAULTS.set(newValue, forKey: Constants.userDefaults.PHOTO_GALLERY_PERMISSION)
        }
    }
    
    var regularLaunch: Bool {
        get {
            if let permission = DEFAULTS.value(
                forKey: Constants.userDefaults.REGULAR_LAUNCH
            ) as? Bool {
                return permission
            }
            
            return false
        } set {
            DEFAULTS.set(newValue, forKey: Constants.userDefaults.REGULAR_LAUNCH)
        }
    }
    
    var IAPInfo: [IAPProductModel]? {
        get {
            if let info = DEFAULTS.object(
                forKey: Constants.userDefaults.IAP_INFO
                ) as? Data {
                
                let decoder = JSONDecoder()
                return try! decoder.decode(
                    [IAPProductModel].self, from: info
                )
            }
            return nil
        } set {
            if let info = newValue {
                let encoder    = JSONEncoder()
                if let encoded = try? encoder.encode(info) {
                    DEFAULTS.set(encoded, forKey: Constants.userDefaults.IAP_INFO)
                }
            } else {
                DEFAULTS.set(nil, forKey: Constants.userDefaults.IAP_INFO)
            }
        }
    }
    
    var isPremiumUser: Bool {
        get {
            if let permission = DEFAULTS.value(
                forKey: Constants.userDefaults.PREMIUM_USER
            ) as? Bool {
                return permission
            }
            
            return false
        } set {
            DEFAULTS.set(newValue, forKey: Constants.userDefaults.PREMIUM_USER)
        }
    }
    
    var purchasedIdentifier: String? {
        get {
            if let identifier = DEFAULTS.value(
                forKey: Constants.userDefaults.PURCHASED_IDENTIFIER
            ) as? String {
                return identifier
            }
            
            return nil
        } set {
            if let identifier = newValue {
                DEFAULTS.setValue(identifier, forKey: Constants.userDefaults.PURCHASED_IDENTIFIER)
            } else {
                DEFAULTS.set(nil, forKey: Constants.userDefaults.PURCHASED_IDENTIFIER)
            }
        }
    }
    
    var subscriptionExpiryDate: Date? {
        get {
            if let date = DEFAULTS.value(
                forKey: Constants.userDefaults.SUBSCRIPTION_EXPIRY_DATE
            ) as? Date {
                return date
            }
            
            return nil
        } set {
            if let date = newValue {
                DEFAULTS.setValue(date, forKey: Constants.userDefaults.SUBSCRIPTION_EXPIRY_DATE)
            } else {
                DEFAULTS.set(nil, forKey: Constants.userDefaults.SUBSCRIPTION_EXPIRY_DATE)
            }
        }
    }
    
    var appPasscode: String? {
        get {
            if let identifier = DEFAULTS.value(
                forKey: Constants.userDefaults.APP_PASSCODE
            ) as? String {
                return identifier
            }
            
            return nil
        } set {
            if let identifier = newValue {
                DEFAULTS.setValue(identifier, forKey: Constants.userDefaults.APP_PASSCODE)
            } else {
                DEFAULTS.set(nil, forKey: Constants.userDefaults.APP_PASSCODE)
            }
        }
    }
    
    var appLockType: Int {
        get {
            if let lockType = DEFAULTS.value(
                forKey: Constants.userDefaults.APP_LOCK_TYPE
            ) as? Int {
                return lockType
            }
            
            return 0
        } set {
            DEFAULTS.setValue(newValue, forKey: Constants.userDefaults.APP_LOCK_TYPE)
        }
    }
    
    /* MARK:- Nibs Names */
    struct cellNib {
        ///Table View Cell Nibs
        static let DOCS        = "DocsCell"
        static let SETTINGS    = "SettingsCell"
        static let FOLDER_LIST = "FolderListCell"
        ///Collection View Cell Nibs
        static let ONBOARDING  = "OnBoardingCell"
        static let DOC_FOLDER  = "DocFolderCell"
        ///CBScanner Collection View Cell Nibs
        static let FILTER      = "FilterCell"
        static let SCAN_TYPE   = "ScanTypeCell"
        static let IMAGE_SIZE  = "ImageSizeCell"
        static let EDIT_IMAGE  = "EditImageCell"
    }
    
    /* MARK:- Views */
    struct VIEW {
        static let TAB_BAR            = "TabBar"
        static let DOC_OPTIONS        = "DocOptions"
        static let DOCS_OPTIONS       = "DocsOptions"
        static let SCANNER_BUTTON     = "ScannerButton"
        static let DOC_FOLDER_OPTIONS = "DocFolderOptions"
        static let PRIVILEGES_DETAILS = "PrivilegesAndDetailsView"
    }
    
    /* MARK:- View Controllers ID's */
    struct VCID {
        ///App Passcode
        static let APP_TOUCHID         = "AppTouchIdVC"
        static let APP_PASSCODE        = "AppPasscodeVC"
        ///OnBoarding
        static let ONBOARDING          = "OnBoardingVC"
        ///Regular VC
        static let DOC                 = "DocVC"
        static let DOCS                = "DocsVC"
        static let BASE                = "BaseVC"
        static let APP_PIN             = "AppPinVC"
        static let ADD_PIN             = "AddPinVC"
        static let PREMIUM             = "PremiumVC"
        static let SETTIGNS            = "SettingsVC"
        static let SIGNATURE           = "SignatureVC"
        static let DOC_FOLDER          = "DocFolderVC"
        static let SET_SIGNATURE       = "SetSignatureVC"
        static let PICTURE_QUALITY     = "PictureQualityVC"
        static let START_APP_WITH      = "StartAppWithVC"
        ///Popups
        static let MERGE               = "MergeVC"
        static let DELETE              = "DeleteVC"
        static let RENAME              = "RenameVC"
        static let PASSCODE            = "PasscodeVC"
        static let TOUCH_ID            = "TouchIdVC"
        static let OCR_TEXT            = "OCRTextVC"
        static let MOVE_COPY           = "MoveCopyVC"
        static let NEW_FOLDER          = "NewFolderVC"
        static let FOLDER_LIST         = "FolderListVC"
        static let IMAGE_PICKER        = "CBImagePickerVC"
        static let PREMIUM_POPUP       = "PremiumPopUp"
        static let CONGRATULATION      = "CongratulationVC"
        static let SCANNING_OPTIONS    = "ScanningOptions"
        static let SUBSCROPTION_DETAIL = "SubscriptionDetailsVC"
        ///Doc Options
        static let LOCK                = "LockVC"
        static let UNLOCK              = "UnlockVC"
    }
    
    /* MARK:- User Defaults */
    struct userDefaults {
        static let IAP_INFO                 = "IAPInfo"
        static let PREMIUM_USER             = "PremiumUser"
        static let APP_PASSCODE             = "appPasscode"
        static let TIMES_SHARED             = "timesShared"
        static let APP_LOCK_TYPE            = "appLockType"
        static let START_APP_WITH           = "startAppWith"
        static let REGULAR_LAUNCH           = "regularLaunch"
        static let APP_OPEN_COUNT           = "appOpenCount"
        static let PICTURE_QUALITY          = "pictureQuality"
        static let CAMERA_PERMISSION        = "cameraPermission"
        static let PURCHASED_IDENTIFIER     = "purchasedIdentifier"
        static let SUBSCRIPTION_EXPIRY_DATE = "subscriptionExpiryDate"
        static let PHOTO_GALLERY_PERMISSION = "photoGalleryPermission"
    }
    
}

