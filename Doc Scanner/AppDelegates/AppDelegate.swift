//
//  AppDelegate.swift
//  Doc Scanner
//
//  Created by Umar Farooq Nadeem on 7/23/20.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import UIKit
import CoreData
import Firebase
import SwiftyStoreKit
import GoogleMobileAds
import UserNotifications
import FirebaseMessaging

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    ///Properties
    var window           : UIWindow?
    var restrictRotation : UIInterfaceOrientationMask = .portrait
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    )-> Bool {
        
        /// Configure Firebase
        FirebaseApp.configure()
        /// APN Setup
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            let center      = UNUserNotificationCenter.current()
            center.delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            center.requestAuthorization(
                options           : authOptions,
                completionHandler : {_, _ in }
            )
        } else {
          let settings : UIUserNotificationSettings = UIUserNotificationSettings(
            types      : [.alert, .badge, .sound],
            categories : nil
          )
          application.registerUserNotificationSettings(settings)
        }
        
        Messaging.messaging().delegate = self

        application.registerForRemoteNotifications()
        
        ///Setting up initial VC
        if let window = window {
            if #available(iOS 13.0, *) {
                ///Not beign used as it'll use the scene
                ///delegate for initial vc and all other setup
            } else {
                Helper.setInitialViewController(window: window)
            }
        }
        
        ///Store Kit Setup
        ///Register a transaction observer
        
        SwiftyStoreKit.completeTransactions(atomically: true) { purchases in
            for purchase in purchases {
                switch purchase.transaction.transactionState {
                case .purchased, .restored:
                    if purchase.needsFinishTransaction {
                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                    }
                case .failed, .purchasing, .deferred:
                    break
                default:
                    break
                }
            }
        }
        
        
        /// Checking if purchase is expired
        if let rawValue = Constants.sharedInstance.purchasedIdentifier {
            if let identifier = IAPIdentifiers(rawValue: rawValue) {
                IAPManager.sharedInstance.verifyReceipt(withIdentifier: identifier) { state in
                    switch state {
                    case .purchased:
                        Constants.sharedInstance.isPremiumUser = true
                    case .expired:
                        self.showExpieryAlert()
                    case .notPurchased:
                        self.showExpieryAlert()
                    }
                }
            }
        }
        
        /// Google AdMobs
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        
        ///App Sharing Constant (As application can only be shared 3 times daily if you are non-premium user)
        if let date = Constants.sharedInstance.timesShared["date"] as? Date {
            if date != Date() {
                var timesShared : [String: Any] = [:]
                
                timesShared["date"]   = Date()
                timesShared["number"] = 0
                
                Constants.sharedInstance.timesShared = timesShared
            }
        } else {
            var timesShared : [String: Any] = [:]
            
            timesShared["date"]   = Date()
            timesShared["number"] = 0
            
            Constants.sharedInstance.timesShared = timesShared
        }
        
        /// Updating Application open count for showing rateus popup
        Constants.sharedInstance.appOpenCount += 1
        
        /// Wait on Lunch Screen
        Thread.sleep(forTimeInterval: 2.0)
        
        return true
    }
    
    ///Method for interface orientations
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        return restrictRotation
    }
    
    // MARK: UISceneSession Lifecycle

    @available(iOS 13.0, *)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    @available(iOS 13.0, *)
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "Doc_Scanner")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

/* MARK:- Methods */
extension AppDelegate {
    func showExpieryAlert(){
        Constants.sharedInstance.isPremiumUser          = false
        Constants.sharedInstance.purchasedIdentifier    = nil
        Constants.sharedInstance.subscriptionExpiryDate = nil
        
        if let baseVC = UIApplication.topViewController() as? BaseVC{
            baseVC.docsVC.probar(shouldHide: false)
            baseVC.docsVC.showAlert(message: "Your in app purchase is expired.")
        }
    }
}

/* MARK:-  Apple Push Notifications */

/// UN User Notification Center Delegate
extension AppDelegate : UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let _ = notification.request.content
        if #available(iOS 14, *) {
            completionHandler([.list, .banner, .sound])
        } else {
            completionHandler([.alert, .sound])
        }
    }
}

/// Messaging Delegate
extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        Helper.debugLogs(any: fcmToken, and: "FCM Token")
    }
}
