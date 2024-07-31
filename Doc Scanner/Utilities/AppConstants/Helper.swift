//
//  Helper.swift
//  DialIn
//
//  Created by Umar Farooq Nadeem on 3/20/20.
//  Copyright © 2020 DialIn. All rights reserved.
//

import UIKit
import AVKit
import Photos

class Helper {

    /// - Returns: Top SafeeArea of view
    static func getSafeAreaTop() -> CGFloat {
        var safeAreaTop: CGFloat = 0.0
        if #available(iOS 13.0, *) {
            if let window = UIApplication.shared.currentScene?.windows.first {
                safeAreaTop = window.safeAreaInsets.top
            }
        } else {
            if let window = UIApplication.shared.keyWindow {
                safeAreaTop = window.safeAreaInsets.top
            }
        }
        
        let deviceType = UIDevice.current.deviceType
        switch deviceType {
        case .iPhone5:
            safeAreaTop = 20
        case .iPhone5C:
            safeAreaTop = 20
        case .iPhone5S:
            safeAreaTop = 20
        case .iPhoneSE:
            safeAreaTop = 20
        default:
            break
        }
        
        return safeAreaTop
    }
    
    /// Enhanced Pop To View Controller
    /// - Parameter Kind: The type of class you want pop to
    static func popToViewController(ofKind Kind: AnyClass) {
        if let topVC = Constants.sharedInstance.topVC {
            topVC.navigationController?.viewControllers.forEach({ (vc) in
                if vc.isKind(of: Kind) {
                    if let vc = vc as? DocsVC {
                        vc.shouldOpenNewDoc?()
                        topVC.navigationController?.popToViewController(vc, animated: true)
                    } else if let vc = vc as? BaseVC {
                        topVC.navigationController?.popToViewController(
                            vc,
                            animated: true,
                        completion: {
                            vc.docsVC.shouldOpenNewDoc?()
                        })
                    }
                }
            })
        }
    }
    
    /// - Parameters:
    ///   - data: The data to be printed
    ///   - title: Title of what is to be printed
    static func debugLogs(any data: Any, and title: String = "Log") {
        print("============= DEBUG LOGS START =================")
        print("\(title): \(data)")
        print("=============  DEBUG LOGS END  =================")
        print("\n \n")
    }
    
    /// - Parameter date: String date
    /// - Returns: Formatted date in "MM-dd-yyyy HH:mm:ss" format
    static func dateFormatter(fromDate date: String) -> String? {
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "yyyy-MM-dd HH:mm:ss Z"

        let dateFormatterSet = DateFormatter()
        dateFormatterSet.dateFormat = "MM-dd-yyyy HH:mm:ss"
        
        if let date = dateFormatterGet.date(from: date) {
            return dateFormatterSet.string(from: date)
        }
        
        return nil
    }
    
    
    /// Setup the initial VC of our application
    /// - Parameter window: our application windows
    static func setInitialViewController(window: UIWindow){
        let navigationController = MAIN_STORYBOARD.instantiateInitialViewController() as! UINavigationController
        
        if Constants.sharedInstance.appLockType == 0 {
            if Constants.sharedInstance.regularLaunch {
                let baseVC = BaseVC(
                    nibName: Constants.VCID.BASE,
                    bundle: nil
                )
                
                navigationController.viewControllers = [baseVC]
            } else {
                let onBoardingVC  = OnBoardingVC(
                    nibName : Constants.VCID.ONBOARDING,
                    bundle  : nil
                )
                
                navigationController.viewControllers = [onBoardingVC]
            }
        } else if Constants.sharedInstance.appLockType == 1 {
            let appPasscodeVC = AppPasscodeVC(
                nibName: Constants.VCID.APP_PASSCODE,
                bundle: nil
            )
            
            navigationController.viewControllers = [appPasscodeVC]
        } else if Constants.sharedInstance.appLockType == 2 {
            let appTouchIdVC = AppTouchIdVC(
                nibName: Constants.VCID.APP_TOUCHID,
                bundle: nil
            )
            
            navigationController.viewControllers = [appTouchIdVC]
        }
        
        
        window.rootViewController = navigationController
    }
    
    ///TabBar Frame
    static func getTabBarFrame() -> CGRect {
        ///Setting Up Proportional Frame
        let height = SCREEN_HEIGHT * 0.11160714
        let width  = SCREEN_WIDTH
        let y      = SCREEN_HEIGHT - height
        
        return CGRect(x: 0.0, y: y, width: width, height: height)
    }
    
    ///Linear Gradient
    static func getGradientLayer(
        inView view           : UIView    ,
        withColors colors     : [CGColor] ,
        atLocations locations : [NSNumber]) -> CAGradientLayer {
        
        let gradientLayer: CAGradientLayer = CAGradientLayer()
        
        gradientLayer.frame     = view.bounds
        gradientLayer.colors    = colors
        gradientLayer.locations = locations
        
        return gradientLayer
    }
    
    ///Fetch Current Device
    static func device() -> CurrentDeviceType {
        let deviceType = UIDevice.current.deviceType
        switch deviceType {
        case .iPad         , .iPad2         , .iPad3       , .iPad4, .iPad5, .iPad6,
             .iPadMini     , .iPadMiniRetina, .iPadMini3   , .iPadMini4,
             .iPadAir      , .iPadAir2      , .iPadPro9Inch, .iPadPro10p5Inch,
             .iPadPro11Inch, .iPadPro12Inch:
            
            return .iPad
        case .iPhoneX      , .iPhoneXS       , .iPhoneXSMax, .iPhoneXR, .iPhone11,
             .iPhone11Pro  , .iPhone11ProMax:
            
            return .bezelLessiPhone
        default:
            #if DEBUG
            return .bezeliPhone
            #else
            return .bezeliPhone
            #endif
        }
    }
    
    ///Attributed underline font
    static func underlineText(
        withTitle title: String      ,
        andColor color : UIColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1),
        andFont font   : UIFont  = UIFont(name: "Roboto-Regular", size: 14.0)!
    )  -> NSMutableAttributedString {

        let attributes : [NSAttributedString.Key : Any] = [
            .font            : font  ,
            .foregroundColor : color ,
            .underlineStyle  : 1
        ]
        
        let attributedString = NSMutableAttributedString(
                                    string     : title,
                                    attributes : attributes
                                )
        
        return attributedString
    }
    
    ///Drgrees to radians
    static func deg2rad(_ number: CGFloat) -> CGFloat {
        return number * .pi / 180
    }
    
    ///Permissions
    static func checkCameraPermission(
        isGranted: @escaping (_ permission: Bool) -> ()
    ) {
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch status {
        case .authorized:
            Constants.sharedInstance.cameraPermission = true
            isGranted(true)
        case .restricted, .denied:
            openPermissionSettings()
        case .notDetermined:
            askCameraPermission(completion: isGranted)
        default:
            askCameraPermission(completion: isGranted)
        }
    }
    
    
    static func checkPhotoGalleryPermission(
        isGranted: @escaping (_ permission: Bool) -> ()
    ) {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
            Constants.sharedInstance.photoGalleryPermission = true
            isGranted(true)
        case .restricted, .denied:
            openPermissionSettings()
        case .notDetermined:
            askPhotoGalleryPermission(completion: isGranted)
        default:
            askPhotoGalleryPermission(completion: isGranted)
        }
    }
}

/* MARK:- Methods */
extension Helper {
    static func openPermissionSettings(){
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.appForegroundedAfterSettings),
            name    : UIApplication.didBecomeActiveNotification,
            object  : nil
        )
        
        let settingsUrl = URL(string: UIApplication.openSettingsURLString)
        
        DispatchQueue.main.async {
            UIApplication.shared.open(settingsUrl!)
        }
    }
    
    static func askCameraPermission(completion: @escaping (_ permission: Bool) -> ()) {
        AVCaptureDevice.requestAccess(for: .video) { (isGranted) in
            DispatchQueue.main.async {
                completion(isGranted)
                Constants.sharedInstance.cameraPermission = isGranted
            }
        }
    }
    
    static func askPhotoGalleryPermission(completion: @escaping (_ permission: Bool) -> ()) {
        PHPhotoLibrary.requestAuthorization({ (status: PHAuthorizationStatus) -> Void in
            if status == .authorized {
                DispatchQueue.main.async {
                    completion(true)
                    Constants.sharedInstance.photoGalleryPermission = true
                }
            } else {
                DispatchQueue.main.async {
                    completion(false)
                    Constants.sharedInstance.photoGalleryPermission = false
                }
            }
        })
    }
}

/* MARK:- obj-c Interface */
extension Helper {
    @objc func appForegroundedAfterSettings() {
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
}
