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

@objc public protocol StoreKeeperTransactionDelegate {
  optional func showPurchaseInProgress(deferred deferred: Bool)
  optional func showPurchaseCompleted(transaction: SKPaymentTransaction)
  optional func showPurchaseFailed(transaction: SKPaymentTransaction)
  optional func showPurchaseRestored(transaction: SKPaymentTransaction)
}

public protocol StoreKeeperRestorePurchasesDelegate {
  func showRestoreCompleted()
  func showRestoreFailedWithError(error: String)
}

public class OddStoreKeeper: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver, SKRequestDelegate {
  
  static public let defaultStore = OddStoreKeeper()
  
  var prefixId: String {
    get {
      guard let bundleName = NSBundle.mainBundle().bundleIdentifier else { return "unknownBundleId." }
      return "\(bundleName)."
    }
  }
  
  static public var productIdentifiers: Set<String> = Set()
  private var products: Array<SKProduct> = Array()
  private var productsRequest: SKProductsRequest?
  
  public var delegate: StoreKeeperDelegate?
  public var transactionDelegate: StoreKeeperTransactionDelegate?
  public var restoreDelegate: StoreKeeperRestorePurchasesDelegate?
  
  // MARK: - Class Methods
  static public func canMakePayments() -> Bool {
    return SKPaymentQueue.canMakePayments()
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
    
    self.productsRequest?.delegate = self
    self.productsRequest?.start()
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
    
    if response.invalidProductIdentifiers.isEmpty {
      self.delegate?.processStoreProducts(self.products, invalidProducts: nil)
    }
    else {
      self.delegate?.processStoreProducts(self.products, invalidProducts: response.invalidProductIdentifiers)
    }
  }
  
  // MARK: - SKRequestDelegate
  
  public func request(request: SKRequest, didFailWithError error: NSError) {
    OddLogger.error("Store Request Error: \(error.localizedDescription)")
    // add alert for error !!
  }
  
  public func requestDidFinish(request: SKRequest) {
    guard request is SKReceiptRefreshRequest else { return }
    
    OddLogger.info("Store Request did finish")
  }
  
  // MARK: - Payments
  
  public func makePaymentForProduct(product: SKProduct) {
    SKPaymentQueue.defaultQueue().addTransactionObserver(self)
    let payment = SKMutablePayment(product: product)
    SKPaymentQueue.defaultQueue().addPayment(payment)
  }
  
  public func restorePurchase() {
    SKPaymentQueue.defaultQueue().addTransactionObserver(self)
    SKPaymentQueue.defaultQueue().restoreCompletedTransactions()
  }
  
  public func paymentQueueRestoreCompletedTransactionsFinished(queue: SKPaymentQueue) {
    OddLogger.info("Restore Purchases Finished")
    self.restoreDelegate?.showRestoreCompleted()
  }
  
  public func paymentQueue(queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: NSError) {
    OddLogger.error("Restore Purchases failed with error: \(error.localizedDescription)")
    self.restoreDelegate?.showRestoreFailedWithError(error.localizedDescription)
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
      }
    }
  }
  
  // MARK: - Transaction Helpers
  
  func showTransactionInProgress(deferred deferred: Bool) {
    if deferred {
      OddLogger.info("StoreKeeper deferred transaction in progress")
      self.transactionDelegate?.showPurchaseInProgress?(deferred: true)
    } else {
      OddLogger.info("StoreKeeper transaction in progress")
      self.transactionDelegate?.showPurchaseInProgress?(deferred: false)
    }
  }
  
  func failedTransaction(transaction: SKPaymentTransaction) {
    OddLogger.error("StoreKeeper transaction \(transaction.transactionIdentifier!) failed: \(transaction.error!)")
    self.transactionDelegate?.showPurchaseFailed?(transaction)
    self.productsRequest = nil
  }
  
  func completeTransaction(transaction: SKPaymentTransaction) {
    OddLogger.info("StoreKeeper transaction complete: \(transaction.transactionIdentifier!)")
    self.transactionDelegate?.showPurchaseCompleted?(transaction)
    self.productsRequest = nil
  }
  
  func restoreTransaction(transaction: SKPaymentTransaction) {
    OddLogger.info("StoreKeeper transaction restoration complete: \(transaction.transactionIdentifier!)")
    self.transactionDelegate?.showPurchaseRestored?(transaction)
    self.productsRequest = nil
  }
  
  public func finishTransaction(transaction: SKPaymentTransaction) {
    SKPaymentQueue.defaultQueue().finishTransaction(transaction)
    self.delegate = nil
    self.transactionDelegate = nil
    self.restoreDelegate = nil
  }

}
