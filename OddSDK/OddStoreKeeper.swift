//
//  OddStoreKeeper.swift
//  OddSDK
//
//  Created by Patrick McConnell on 8/1/18.
//  Copyright © 2018 Patrick McConnell. All rights reserved.
//

import Foundation
import StoreKit

// returns the products price in the correct currency format for the users locale
public extension SKProduct {
    func formattedPrice() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = self.priceLocale
        return formatter.string(from: self.price) ?? "Undefined"
    }
    
    func asOddStoreProduct() -> OddStoreProduct {
        return OddStoreProduct(id: self.productIdentifier,
                               title: self.localizedTitle,
                               description: self.localizedDescription,
                               price: self.formattedPrice())
    }
}

public enum OddStoreKeeperPurchaseFailureCode {
    case unableToMakePayments
    case noProductsAvailable
    case accountAlreadyExists
    case storePurchaseFailure
    case noReciptFound
    case noOriginalTransactionFound
}

public protocol OddStoreKeeperDelegate {
    func shouldShowPurchaseFailed(withReason reason: OddStoreKeeperPurchaseFailureCode, transaction: SKPaymentTransaction?)
    func shouldShowRegistrationError(_ error: String)
    func displayStoreProducts(_ products: Array<OddStoreProduct>, invalidProductIds: Array<String>?)
    func displayValidatingEmail()
    func displayPurchasingProduct()
    func displayPurchaseComplete(forTransaction transaction: SKPaymentTransaction)
    func displayPurchaseRestored(forTransaction transaction: SKPaymentTransaction)
    func didCompleteNewSubscription()
    func didFailToRestorePurchase(withError error: String)
    func didAuthenticate()
}

public struct OddStoreProduct {
    public var id: String
    public var title: String
    public var description: String
    public var price: String
    
    public init(id: String, title: String, description: String, price: String) {
        self.id = id
        self.title = title
        self.description = description
        self.price = price
    }
    
    static func skProductsAsOddStoreProducts(skProducts: Array<SKProduct?>) -> Array<OddStoreProduct> {
        var oddProducts = Array<OddStoreProduct>()
        
        skProducts.forEach { (skProduct) in
            guard let prod = skProduct else {
                return
            }
            oddProducts.append(prod.asOddStoreProduct())
        }
        
        return oddProducts
    }
}

public class OddStoreKeeper: NSObject, SKRequestDelegate {
    
    public static let shared = OddStoreKeeper()
    
//    public static let connectURL = "https://oddconnect.com/api/"
    public static let connectURL = "https://oddconnect.science/api/"
    
    public var delegate: OddStoreKeeperDelegate? = nil
    
    fileprivate var restoreRequest: SKReceiptRefreshRequest?
    
    static var prefixId: String {
        get {
            guard let bundleName = Bundle.main.bundleIdentifier else { return "unknownBundleId." }
            return "\(bundleName)."
        }
    }
    
    var authAttemptTimeDelta: TimeInterval = 5  // check for Authentication every 5 seconds
    
    /// Number of times the server will be contacted to check for Authentication status changes.
    /// This number multiplied by `authAttemptTimeDelta` will determine how long the SDK will
    /// attempt to detecet a change in state before stopping.
    var numberOfAuthAttempts: Int =  60            // number of times to try before failing
    
    /// A counter to track the number of attempts we have made to check auth state changes
    var authAttemptCount = 0
    
    /// A timer to trigger Authentication state change checks
    var pollingTimer: Timer?
    
    static func configFileName() -> String {
        // we return a default in case the SDK is run in a unit test with no bundle. derp.
        guard let displayName = Bundle.main.infoDictionary!["CFBundleDisplayName"] as? NSString else { return "OddOTSAppConfig_test" }
        let cleanDisplayName = displayName.replacingOccurrences(of: " ", with: "")
//        print("CLEAN: \(cleanDisplayName)")
        return "OddOTSAppConfig_\(cleanDisplayName)"
    }
    
    fileprivate static func configValue(forKey key: String) -> AnyObject? {
        guard let path = Bundle.main.path(forResource: OddStoreKeeper.configFileName(), ofType: "plist"),
            let dict = NSDictionary(contentsOfFile: path) as? Dictionary<String, AnyObject>,
            let value = dict[key] else {
                OddLogger.error("Odd Connect Access Token not found")
                return nil
        }
        return value
    }
    
    static var connectAccessToken: String? {
        get {
            return OddStoreKeeper.configValue(forKey: OddConstants.kConnectAccessTokenKey) as? String
        }
    }
    
    static var gatekeeperEntitlements: Array<String>? {
        get {
            return OddStoreKeeper.configValue(forKey: OddConstants.kGatekeeperEntitlementsKey) as? Array<String>
        }
    }
    
    fileprivate var productIdentifiers: Set<String> = Set()
    
    fileprivate var productsRequest: SKProductsRequest?
    fileprivate var products: Array<SKProduct?> = Array()
    
    fileprivate var selectedProduct: SKProduct? = nil
    
    fileprivate var userEmail = ""
    
    public func initializeStoreKeeper() {
        if self.canMakePayments() {
            self.validateProductIdentifiers()
        } else {
            self.delegate?.shouldShowPurchaseFailed(withReason: .unableToMakePayments, transaction: nil)
        }
    }
    
    fileprivate func canMakePayments() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    // MARK: - Products
    
    fileprivate func fetchProductIdentifiers() {
        OddLogger.info("Fetching product identifiers...")
        guard let url = Bundle.main.url(forResource: "iap_product_ids", withExtension: "plist"),
            let idArray = NSArray(contentsOf: url) as? Array<String> else { return }
        self.productIdentifiers = Set(idArray.map { "\(OddStoreKeeper.prefixId)\($0)" } )
    }
    
    fileprivate func validateProductIdentifiers() {
        OddLogger.info("Validating product identifiers...")
        self.fetchProductIdentifiers()
        self.productsRequest = SKProductsRequest(productIdentifiers: self.productIdentifiers)
        
        self.productsRequest?.delegate = self
        self.productsRequest?.start()
    }
    
}

extension OddStoreKeeper: SKProductsRequestDelegate {
    
    //MARK: - SKProductsRequestDelegate
    
    open func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        self.products = response.products
        
        response.invalidProductIdentifiers.forEach { (invalid) in
            OddLogger.error("\(invalid) is an invalid product identifier")
        }
        
        self.products.forEach { (product) in
            OddLogger.info("\(product?.localizedTitle ?? "undefined product") - \(product?.price ?? 0.00) is valid")
        }
        
        let oddProducts = OddStoreProduct.skProductsAsOddStoreProducts(skProducts: self.products)
        
        if self.products.isEmpty {
            // send some dummy products to debug in simulator
            // this will not allow actual purchases but will display subscription select dialog
//            self.delegate?.displayStoreProducts(self.dummyProducts(), invalidProductIds: nil)
            self.delegate?.shouldShowPurchaseFailed(withReason: .noProductsAvailable, transaction: nil)
        } else if response.invalidProductIdentifiers.isEmpty {
            self.delegate?.displayStoreProducts(oddProducts, invalidProductIds: nil)
        } else {
            self.delegate?.displayStoreProducts(oddProducts, invalidProductIds: response.invalidProductIdentifiers)
        }
    }
    
    
    func dummyProducts() -> [OddStoreProduct] {
        let p1 = OddStoreProduct(id: "1234",
                                 title: "Product One",
                                 description: "A very special product",
                                 price: "$9.99")
        
        let p2 = OddStoreProduct(id: "5678",
                                 title: "Product Two",
                                 description: "Another very special product",
                                 price: "$19.99")
        
        return [p1, p2]
    }

}


extension OddStoreKeeper: SKPaymentTransactionObserver {
    // MARK: - Purchasing
    
    public func makePurchase(itemIndex index: Int, email: String) {
        if self.products.isEmpty || self.products[index] == nil || index > self.products.count {
            OddLogger.error("Product Index Out of Bounds")
            self.delegate?.shouldShowPurchaseFailed(withReason: .noProductsAvailable, transaction: nil)
            return
        }
        
        self.selectedProduct = self.products[index]
        
        let productName = self.selectedProduct?.localizedTitle ?? "Undefined Product"
        
        OddLogger.info("Begining purchase of \(productName) for \(email)")
        self.delegate?.displayValidatingEmail()
        
        self.checkForExistingAccount(email, accountExists: { (accountExists, error) in
            if error != nil {
                OddLogger.error("Error: \(error!.localizedDescription)")
                self.delegate?.shouldShowPurchaseFailed(withReason: .accountAlreadyExists, transaction: nil)
                return
            }
            
            OddLogger.info("Account Exists: \(accountExists)")
            
            self.userEmail = email
            self.makePaymentForProduct()
        })
    }
    
    fileprivate func checkForExistingAccount(_ email: String, accountExists: @escaping (Bool, Error?) -> Void) {
        // needs to be connected to service for subscription validation (Odd Connect)
        
        let path = "device_users/\(self.userEmail)/entitlements"
        
        OddContentStore.sharedStore.API.get(nil, url: path, altDomain: OddStoreKeeper.connectURL) { (response, error) -> () in
            if let e = error {
                OddLogger.error("Error checking for existing account Odd Connect failed with error: \(e.localizedDescription)")
                let userInfo = e.userInfo
                let responseCode = userInfo["statusCode"]
                
                // 404 is a valid response if the user email is not in the system
                if responseCode != nil && responseCode as? Int == 404 {
                    accountExists(false, nil)
                } else {
                    accountExists(false, error)
                }
            } else {
                OddLogger.info("Entitlements Fetched Successfully")
                
                guard let json = response as? jsonObject,
                    let entitlements = json["data"] as? jsonArray else {
                        OddLogger.error("Error checking for existing account. No incorrect response")
                        let error = NSError(domain: "Odd", code: 901, userInfo: ["error": "Error checking for existing account. Incorrect response"]) as Error
                        accountExists(false, error)
                        return
                }
                guard let validEntitlements = OddStoreKeeper.gatekeeperEntitlements else {
                    accountExists(false, nil)
                    return
                }
                entitlements.forEach { (entitlement) in
                    validEntitlements.forEach { (valid) in
                        let entitlementId = entitlement["attributes"]?["entitlement_identifier"] as? String
                        if entitlementId == valid {
                            accountExists(true, nil)
                            return
                        }
                    }
                }
            }
        }
        
        accountExists(false, nil)
    }
    
    fileprivate func makePaymentForProduct() {
        if !SKPaymentQueue.default().transactions.isEmpty {
            OddLogger.warn("Skipping duplicate payment")
            return
        }
        guard let product = self.selectedProduct else {
            self.delegate?.shouldShowPurchaseFailed(withReason: .noProductsAvailable, transaction: nil)
            return
        }
        
        SKPaymentQueue.default().add(self)
        let payment = SKMutablePayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        transactions.forEach { (transaction) in
            switch transaction.transactionState {
            case .purchasing:
                self.delegate?.displayPurchasingProduct()
            case .deferred:
                self.delegate?.displayPurchasingProduct()
            case .failed:
                self.delegate?.shouldShowPurchaseFailed(withReason: .storePurchaseFailure, transaction: transaction)
            case .purchased:
                self.delegate?.displayPurchaseComplete(forTransaction: transaction)
                self.recordPurchaseWithOddConnect(usingTransaction: transaction)
            case .restored:
                self.delegate?.displayPurchaseRestored(forTransaction: transaction)
                self.recordRestoredPurchaseWithOddConnect(usingTransaction: transaction)
            }
        }
    }
    
    fileprivate func appReceipt() -> String? {
        if let receiptURL = Bundle.main.appStoreReceiptURL,
            let data = try? Data(contentsOf: receiptURL) {
            
            let receiptData = data.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
            OddLogger.debug("Receipt Data: \(receiptData)")
            return receiptData
        } else {
            OddLogger.warn("No Receipt Found")
        }
        return nil
    }
    
    fileprivate func recordPurchaseWithOddConnect(usingTransaction transaction: SKPaymentTransaction) {
        guard let receipt = self.appReceipt() else {
            self.delegate?.shouldShowPurchaseFailed(withReason: .noReciptFound, transaction: nil)
            return
        }
        
        let path = "device_users/\(self.userEmail)/transactions"

        let params = [
            "type" : "transaction",
            "attributes" : [
                "platform" : "APPLE",
                "product_identifier" : "\(self.selectedProduct?.productIdentifier ?? "no product id")",
                "external_identifier" : "\(transaction.transactionIdentifier ?? "no transaction id")",
                "receipt" : [
                    "latest_receipt": "\(receipt)"
                ] 
            ]
        ] as [String : Any]
        
        let data = [ "data" : params ]
        
        OddContentStore.sharedStore.API.post(data as jsonObject?, url: path, altDomain: OddStoreKeeper.connectURL) { (response, error) -> () in
            if let e = error {
                let userInfo = e.userInfo
                let message = userInfo["message"] as? String
                if message != nil {
                    OddLogger.error("Registering account with Odd Connect failed with error: \(message!)")
                    self.delegate?.shouldShowRegistrationError("Registering account failed with error: \(message!)")
                } else {
                    OddLogger.error("Registering account with Odd Connect failed with error: \(e.localizedDescription)")
                    self.delegate?.shouldShowRegistrationError("Registering account failed with error: \(e.localizedDescription)")
                }
            } else {
                OddLogger.info("Account Registered Successfully")
                self.fetchJWT()
            }
        }
    }
    
    fileprivate func recordRestoredPurchaseWithOddConnect(usingTransaction transaction: SKPaymentTransaction) {
        guard let receipt = self.appReceipt() else {
            self.delegate?.shouldShowPurchaseFailed(withReason: .noReciptFound, transaction: nil)
            return
        }
        
        guard let originalTransaction = transaction.original else {
            self.delegate?.shouldShowPurchaseFailed(withReason: .noOriginalTransactionFound, transaction: nil)
            return
        }
        
        let path = "transactions/restore"
        
        let params = [
            "type" : "transaction",
            "attributes" : [
                "platform" : "APPLE",
                "external_identifier" : "\(originalTransaction.transactionIdentifier ?? "no transaction id")",
                "receipt" : [
                    "latest_receipt": "\(receipt)"
                ]
            ]
            ] as [String : Any]
        
        let data = [ "data" : params ]
        
        OddContentStore.sharedStore.API.post(data as jsonObject?, url: path, altDomain: OddStoreKeeper.connectURL) { (response, error) -> () in
            if let e = error {
                let userInfo = e.userInfo
                let message = userInfo["message"] as? String
                if message != nil {
                    OddLogger.error("Restoring account with Odd Connect failed with error: \(message!)")
                    self.delegate?.shouldShowRegistrationError("Restoring account failed with error: \(message!)")
                } else {
                    OddLogger.error("Restoring account with Odd Connect failed with error: \(e.localizedDescription)")
                    self.delegate?.shouldShowRegistrationError("Restoring account failed with error: \(e.localizedDescription)")
                }
            } else {
                guard let json = response as? jsonObject else {
                    OddLogger.error("Restoring account with Odd Connect failed with error: unable to determine user id")
                    self.delegate?.shouldShowRegistrationError("Restoring account failed with error: unable to determine user id")
                    return
                }
                
                if self.saveUserId(withJson: json) {
                    OddLogger.info("Account Restored Successfully")
                    self.fetchJWT()
                } else {
                    OddLogger.error("Restoring account with Odd Connect failed with error: unable to determine user id")
                    self.delegate?.shouldShowRegistrationError("Restoring account failed with error: unable to determine user id")
                }
            }
        }
    }
    
    fileprivate func saveUserId(withJson json: jsonObject) -> Bool {
        guard let attribs = json["attributes"] as? jsonObject,
            let email = attribs["email"] as? String else {
                return false
        }
        UserDefaults.standard.set(email, forKey: OddConstants.kUserIdKey)
        UserDefaults.standard.synchronize()
        OddLogger.info(("Stored User ID: \(email)"))
        self.userEmail = email
        return true
    }
    
    fileprivate func fetchJWT() {
        let path = "device_users/\(self.userEmail)/connections"
        
        let userId = OddEventsService.defaultService.userId()
        
        let params = [
            "type" : "connection",
            
            "attributes" : [
                "platform" : "APPLE_TV",
                "device_identifier" : "\(userId)"
            ]
            ] as [String : Any]
        
        let data = [ "data" : params ]
        
        OddContentStore.sharedStore.API.post(data as jsonObject?, url: path, altDomain: OddStoreKeeper.connectURL) { (response, error) -> () in
            if let e = error {
                let userInfo = e.userInfo
                let message = userInfo["message"] as? String
                if message != nil {
                    OddLogger.error("Fetching JWT with Odd Connect failed with error: \(message!)")
                    self.delegate?.shouldShowRegistrationError("Fetching User Token failed with error: \(message!)")
                } else {
                    OddLogger.error("Fetching JWT with Odd Connect failed with error: \(e.localizedDescription)")
                    self.delegate?.shouldShowRegistrationError("Fetching User Token failed with error: \(e.localizedDescription)")
                }
            } else {
                guard let json = response as? jsonObject else {
                    OddLogger.error("Fetching User Token failed: unable to parse viewer token")
                    self.delegate?.shouldShowRegistrationError("Fetching User Token failed: unable to parse viewer token")
                    return
                }
                OddLogger.info("Fetched JWT Successfully")
                self.saveJWT(withJson: json)
            }
        }  
    }
    
    fileprivate func saveJWT(withJson json: jsonObject) {
        guard let data = json["data"],
            let attribs = data["attributes"] as? jsonObject,
            let jwt = attribs["jwt"] as? String else {
                self.delegate?.shouldShowRegistrationError("Fetching User Token failed with error: unable to parse viewer token.")
                return
        }
        UserDefaults.standard.set(jwt, forKey: OddConstants.kUserAuthenticationTokenKey)
        UserDefaults.standard.synchronize()
        OddLogger.info(("Stored User JWT: \(jwt)"))
        self.delegate?.didCompleteNewSubscription()
    }
    
    public func finishTransaction(_ transaction: SKPaymentTransaction) {
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    // MARK: - Restore Purchase

    public func restorePurchase() {
        SKPaymentQueue.default().add(self)
        SKPaymentQueue.default().restoreCompletedTransactions()
    }

    // MARK: - Polling for Auth
    
    public func beginPollingForAuthentication(withEmail email: String) {
        self.userEmail = email
        OddLogger.info("Starting Authentication polling timer")
        self.authAttemptCount = 0
        self.pollingTimer?.invalidate()
        // timer must be configured on the main thread or it will not fire
        DispatchQueue.main.async(execute: { () -> Void in
            self.pollingTimer = Timer.scheduledTimer(timeInterval: self.authAttemptTimeDelta, target: self, selector: #selector(self.checkForAuthentication), userInfo: nil, repeats: true)
        })
        OddLogger.info("Authentication Timer started")
    }
    
    @objc fileprivate func checkForAuthentication() {
        if self.authAttemptCount < self.numberOfAuthAttempts {
            self.authAttemptCount += 1
            OddLogger.debug("Checking for change in auth status: \(self.authAttemptCount)")
            self.pollForJWT()
        } else {
            OddLogger.info("Stopping check for change in auth status")
            self.pollingTimer?.invalidate()
            self.delegate?.shouldShowRegistrationError("Error: Authentication timed out. Please try again.")
        }
    }
    
    fileprivate func pollForJWT() {
        let path = "connections/\(self.userEmail)"
        
        let userId = OddEventsService.defaultService.userId()
        
        let params = [
            "type" : "connection",
            
            "attributes" : [
                "platform" : "APPLE_TV",
                "device_identifier" : "\(userId)"
            ]
            ] as [String : Any]
        
        let data = [ "data" : params ]
        
        OddContentStore.sharedStore.API.post(data as jsonObject?, url: path, altDomain: OddStoreKeeper.connectURL) { (response, error) -> () in
            if let e = error {
                let userInfo = e.userInfo
                let statusCode = userInfo["statusCode"] as? Int
                
                if statusCode != nil && statusCode! == 404 {
                    // 404 is a valid response when the user has not completed the auth process yet
                    OddLogger.info("Received 404. Continue polling...")
                    return
                }
                
                let message = userInfo["message"] as? String
                if message != nil {
                    OddLogger.error("Polling for  viewer token failed with error: \(message!)")
                    self.delegate?.shouldShowRegistrationError("Polling for viewer token failed with error: \(message!)")
                } else {
                    OddLogger.error("Polling for  viewer token failed with error: \(e.localizedDescription)")
                    self.delegate?.shouldShowRegistrationError("Polling for viewer token failed with error: \(e.localizedDescription)")
                }
            } else {
                guard let json = response as? jsonObject else {
                    OddLogger.error("Polling for  viewer token failed with error: unable to parse viewer token")
                    self.delegate?.shouldShowRegistrationError("Polling for viewer token failed with error: unable to parse viewer token")
                    return
                }
                OddLogger.info("Polling for JWT was successful")
                if self.saveUserCredentials(withJson: json) {
                    self.delegate?.didAuthenticate()
                } else {
                    OddLogger.error("Polling for  viewer token failed with error: unable to parse viewer token")
                    self.delegate?.shouldShowRegistrationError("Polling for viewer token failed with error: unable to parse viewer token")
                }
                OddLogger.info("Polling for viewer token complete. Stopping timer.")
                self.pollingTimer?.invalidate()
            }
        }
    }
    
    fileprivate func saveUserCredentials(withJson json: jsonObject) -> Bool {
        guard let attribs = json["attributes"] as? jsonObject,
            let email = attribs["email"] as? String,
            let jwt = attribs["jwt"] as? String else {
                return false
        }
        UserDefaults.standard.set(email, forKey: OddConstants.kUserIdKey)
        UserDefaults.standard.set(jwt, forKey: OddConstants.kUserAuthenticationTokenKey)
        UserDefaults.standard.synchronize()
        OddLogger.info(("Stored User ID: \(email)"))
        return true
    }
}
