//
//  OddStoreKeeper.swift
//  OddSDK
//
//  Created by Patrick McConnell on 5/5/16.
//  Copyright © 2016 Patrick McConnell. All rights reserved.
//

// 979ef0c7c80749569f88282be4fc0082

import UIKit
import StoreKit


// returns the products price in the correct currency format for the users locale
public extension SKProduct {
  func formattedPrice() -> String? {
    let formatter = NSNumberFormatter()
    formatter.numberStyle = .CurrencyStyle
    formatter.locale = self.priceLocale
    return formatter.stringFromNumber(self.price)
  }
}

public protocol StoreKeeperDelegate {
  func processStoreProducts(products: Array<SKProduct>, invalidProducts: Array<String>? )
}

public class OddStoreKeeper: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
  
  var prefixId: String {
    get {
      guard let bundleName = NSBundle.mainBundle().bundleIdentifier else { return "unknownBundleId." }
      return "\(bundleName)."
    }
  }
  
  static public var productIdentifiers: Set<String> = Set()
  private var products: Array<SKProduct> = Array()
  private var productsRequest: SKProductsRequest = SKProductsRequest()
  
  public var delegate: StoreKeeperDelegate?
  
  // MARK: - Class Methods
  static public func canMakePayments() -> Bool {
    return SKPaymentQueue.canMakePayments()
  }
  
  // MARK: - Lifecycle
  
  public override init() {
    super.init()
  }
  
  // MARK: - Products
  
  func fetchProductIdentifiers() {
    guard let url = NSBundle.mainBundle().URLForResource("iap_product_ids", withExtension: "plist"),
      let idArray = NSArray(contentsOfURL: url) as? Array<String> else { return }
    OddStoreKeeper.productIdentifiers = Set(idArray.map { "\(prefixId)\($0)" } )
  }
  
  public func validateProductIdentifiers() {
    self.fetchProductIdentifiers()
    self.productsRequest = SKProductsRequest(productIdentifiers: OddStoreKeeper.productIdentifiers)
    
    self.productsRequest.delegate = self
    self.productsRequest.start()
  }
  
  //MARK: - SKProductsRequestDelegate
  
  public func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
    self.products = response.products
    
    response.invalidProductIdentifiers.forEach { (invalid) in
      OddLogger.error("\(invalid) is an invalid product identifier")
    }
    
    self.products.forEach { (product) in
      OddLogger.info("\(product.localizedTitle) - \(product.price) is valid")
    }
    
    if let invalids = response.invalidProductIdentifiers as? Array<String> {
        self.delegate?.processStoreProducts(self.products, invalidProducts: invalids)
    } else {
      self.delegate?.processStoreProducts(self.products, invalidProducts: nil)
    }
  }
  
  public func request(request: SKRequest, didFailWithError error: NSError) {
    OddLogger.error("\(error.localizedDescription)")
  }
  
  public func requestDidFinish(request: SKRequest) {
    OddLogger.info("Request did finish")
  }
  

  // MARK: - Payments
  
  public func makePaymentForProduct(product: SKProduct) {
    SKPaymentQueue.defaultQueue().addTransactionObserver(self)
    let payment = SKMutablePayment(product: product)
    SKPaymentQueue.defaultQueue().addPayment(payment)
  }
  
  // MARK: - SKPaymentTransactionObserver
  
  public func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
    transactions.forEach { (transaction) in
      switch transaction.transactionState {
      case .Purchasing:
        self.showTransactionInProgress(deferred: false)
      case .Deferred:
        self.showTransactionInProgress(deferred: true)
      case .Failed:
        self.failedTransaction(transaction)
      case .Purchased:
        self.completeTransaction(transaction)
      case .Restored:
        self.restoreTransaction(transaction)
      default:
        OddLogger.warn("Unexpected transaction state \(transaction.transactionState)")
      }
    }
  }
  
  // MARK: - Transaction Helpers
  
  func showTransactionInProgress(deferred deferred: Bool) {
    if deferred {
      print("DEFERRED")
    } else {
      print("PURCHASING")
    }
  }
  
  func failedTransaction(transaction: SKPaymentTransaction) {
    print("FAILED")
  }
  
  func completeTransaction(transaction: SKPaymentTransaction) {
    print("PURCHASED")
  }
  
  func restoreTransaction(transaction: SKPaymentTransaction) {
    print("RESTORED")
  }
  
  
}
