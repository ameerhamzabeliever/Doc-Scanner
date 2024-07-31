//
//  IAPManager.swift
//  Doc Scanner
//
//  Created by Umar Farooq on 12/10/2020.
//  Copyright © 2020 KingAppStudio. All rights reserved.
//

import Foundation
import SwiftyStoreKit

class IAPManager {
    
    static let sharedInstance = IAPManager()
    
    /// Get all subscriptions available information
    /// - Parameter completion: provide info if the fetch request is a success or faliure
    func getSubscriptionInfo(completion: @escaping (_ competed: Bool)->()){
        let productIds : Set<String> = [
            IAPIdentifiers.weekly.rawValue  ,
            IAPIdentifiers.monthly.rawValue ,
            IAPIdentifiers.yearly.rawValue
        ]
        
        var IAPInfo : [IAPProductModel] = []
        
        SwiftyStoreKit.retrieveProductsInfo(productIds) { result in
            if result.retrievedProducts.count > 0 {
                result.retrievedProducts.forEach { (product) in
                    let info = IAPProductModel(
                        id    : product.productIdentifier,
                        price : product.localizedPrice ?? ""
                    )
                    
                    IAPInfo.append(info)
                }
                
                Constants.sharedInstance.IAPInfo = IAPInfo
                
                completion(true)
            } else if result.invalidProductIDs.count > 0 {
                fatalError("IAP Products Invalid")
            } else {
                Helper.debugLogs(any: result.error as Any, and: "Error")
                completion(false)
            }
        }
    }
    
    
    /// For purchasing the subscription
    /// - Parameters:
    ///   - identifier: Identifier of the subscription to be purchased
    ///   - completion: Provide info if the purchase is a success or faliure
    func purchaseSubscription(
        withIdentifier identifier: IAPIdentifiers,
        completion: @escaping (_ completed: Bool)->()
    ){
        
        if let vc = Constants.sharedInstance.topVC {
            vc.showSpinner(onView: vc.view, title: "Waiting for the purchase....", bgColor: #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.1990536972))
        }
        
        SwiftyStoreKit.purchaseProduct(identifier.rawValue) { result in
            
            if let vc = Constants.sharedInstance.topVC {
                vc.removeSpinner()
            }
            
            switch result {
            case .success(purchase: let purchase):
                
                if purchase.needsFinishTransaction {
                    SwiftyStoreKit.finishTransaction(purchase.transaction)
                }
                
                if identifier == IAPIdentifiers.weekly {
                    Constants.sharedInstance.purchasedIdentifier = IAPIdentifiers.weekly.rawValue
                } else if identifier == IAPIdentifiers.monthly {
                    Constants.sharedInstance.purchasedIdentifier = IAPIdentifiers.monthly.rawValue
                } else if identifier == IAPIdentifiers.yearly {
                    Constants.sharedInstance.purchasedIdentifier = IAPIdentifiers.yearly.rawValue
                }
                
                completion(true)
            case .error(error: let error):
                switch error.code {
                case .unknown:
                    Helper.debugLogs(any: "Unknown error. Please contact support")
                case .clientInvalid:
                    Helper.debugLogs(any: "Not allowed to make the payment")
                case .paymentInvalid:
                    Helper.debugLogs(any: "The purchase identifier was invalid")
                case .paymentCancelled:
                    break
                case .paymentNotAllowed:
                    Helper.debugLogs(any: "The device is not allowed to make the payment")
                case .cloudServiceRevoked:
                    Helper.debugLogs(any: "User has revoked permission to use this cloud service")
                case .storeProductNotAvailable:
                    Helper.debugLogs(any: "The product is not available in the current storefront")
                case .cloudServicePermissionDenied:
                    Helper.debugLogs(any: "Access to cloud service information is not allowed")
                case .cloudServiceNetworkConnectionFailed:
                    Helper.debugLogs(any: "Could not connect to the network")
                default:
                    Helper.debugLogs(any: error.localizedDescription)
                }
                completion(false)
            }
        }
    }
    
    
    
    /// Restore subscription of a user
    /// - Parameter completion: Provide info if the restore purchase request  is a success or faliure
    func restorePurchase(completion: @escaping (_ completed: Bool)->()){
        SwiftyStoreKit.restorePurchases(atomically: true) { result in
            if result.restoredPurchases.count > 0 {
                if let purchase = result.restoredPurchases.first {
                    Helper.debugLogs(any: "Purchase Restored", and: "Success")
                    
                    if purchase.productId == IAPIdentifiers.weekly.rawValue {
                        Constants.sharedInstance.purchasedIdentifier = IAPIdentifiers.weekly.rawValue
                    } else if purchase.productId == IAPIdentifiers.monthly.rawValue {
                        Constants.sharedInstance.purchasedIdentifier = IAPIdentifiers.monthly.rawValue
                    } else if purchase.productId == IAPIdentifiers.yearly.rawValue {
                        Constants.sharedInstance.purchasedIdentifier = IAPIdentifiers.yearly.rawValue
                    }
                    
                    if let identifier = IAPIdentifiers(rawValue: purchase.productId) {
                        self.verifyReceipt(withIdentifier: identifier) { state in
                            switch state {
                            case .purchased:
                                completion(true)
                            case .expired:
                                completion(false)
                            case .notPurchased:
                                completion(false)
                            }
                        }
                    } else {
                        completion(false)
                    }
                }
            } else if result.restoreFailedPurchases.count > 0 {
                fatalError("IAP Products Invalid")
            } else {
                Helper.debugLogs(any: "Nothing to restore", and: "Error")
                completion(false)
            }
        }
    }
    
    
    
    /// Verifies the reciept of the purchase (if it is expired or not)
    /// - Parameters:
    ///   - identifier: Identifire of the purchase
    ///   - completion: Provide info if the purchase is valid
    func verifyReceipt(
        withIdentifier identifier: IAPIdentifiers,
        completion: @escaping (_ completed: IAPState)->()
    ){
        let validator = AppleReceiptValidator(
            service      : IAP_MODE,
            sharedSecret : SHARED_SECRET
        )
        
        SwiftyStoreKit.verifyReceipt(using: validator) { result in
            switch result {
            case .success(receipt: let info):
                let purchaseResult = SwiftyStoreKit.verifySubscription(
                    ofType    : .autoRenewable      ,
                    productId : identifier.rawValue ,
                    inReceipt : info
                )
                
                switch purchaseResult {
                case .purchased(expiryDate: let expiryDate, items: _):
                    Helper.debugLogs(any: expiryDate, and: "Will Expire On")
                    
                    Constants.sharedInstance.subscriptionExpiryDate = expiryDate
                    
                    if Date() > expiryDate {
                        completion(.expired)
                    } else {
                        completion(.purchased)
                    }
                case .expired(expiryDate: let expiryDate, items: _):
                    Helper.debugLogs(any: expiryDate, and: "Is Expired On")
                    completion(.expired)
                case .notPurchased:
                    completion(.notPurchased)
                }
            case .error(error: let error):
                Helper.debugLogs(any: error.localizedDescription, and: "Error")
            }
        }
    }
    
}
