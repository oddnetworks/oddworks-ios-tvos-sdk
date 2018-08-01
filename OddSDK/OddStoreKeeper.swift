//
//  OddStoreKeeper.swift
//  OddSDK
//
//  Created by Patrick McConnell on 8/1/18.
//  Copyright © 2018 Patrick McConnell. All rights reserved.
//

import Foundation
import StoreKit

public enum OddStoreKeeperPurchaseFailureCode {
    case unableToMakePayments
}

public protocol OddStoreKeeperDelegate {
    func shouldShowPurchaseFailed(withReason reason: OddStoreKeeperPurchaseFailureCode)
}

public class OddStoreKeeper: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver, SKRequestDelegate {
    
    public static let shared = OddStoreKeeper()
    
    public var delegate: OddStoreKeeperDelegate? = nil
    
    static var prefixId: String {
        get {
            guard let bundleName = Bundle.main.bundleIdentifier else { return "unknownBundleId." }
            return "\(bundleName)."
        }
    }
    
    public func beginPurchase() {
        if self.canMakePayments() {
            OddLogger.info("Continue Purchase process...")
        } else {
            self.delegate?.shouldShowPurchaseFailed(withReason: .unableToMakePayments)
        }
    }
    
    
    fileprivate func canMakePayments() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    // Mark: - SKProductsReqeustDelegte
    
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        
    }
    
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        
    }
    
    // Mark: - SKPaymentTransactionObserver
    
    // Mark: - SKRequestDelegate
    
    
    // MARK: - Products
    
    fileprivate func fetchProductIdentifiers() {
        guard let url = Bundle.main.url(forResource: "iap_product_ids", withExtension: "plist"),
            let idArray = NSArray(contentsOf: url) as? Array<String> else { return }
        OddStoreKeeper.productIdentifiers = Set(idArray.map { "\(prefixId)\($0)" } )
    }
    
    fileprivate func validateProductIdentifiers() {
        self.fetchProductIdentifiers()
        self.productsRequest = SKProductsRequest(productIdentifiers: OddStoreKeeper.productIdentifiers)
        
        self.productsRequest?.delegate = self
        self.productsRequest?.start()
    }
}
