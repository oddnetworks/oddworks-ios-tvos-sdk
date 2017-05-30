
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
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = self.priceLocale
    return formatter.string(from: self.price)
  }
}

public protocol StoreKeeperDelegate {
  func processStoreProducts(_ products: Array<SKProduct>, invalidProducts: Array<String>? )
}

@objc public protocol StoreKeeperTransactionDelegate {
  @objc optional func showPurchaseInProgress(deferred: Bool)
  @objc optional func showPurchaseCompleted(withTransaction  transaction: SKPaymentTransaction)
  @objc optional func showPurchaseFailed(withTransaction  transaction: SKPaymentTransaction)
  @objc optional func showPurchaseRestored(withTransaction  transaction: SKPaymentTransaction)
  
}

@objc public protocol StoreKeeperRestorePurchasesDelegate {
  func showRestoreCompleted()
  func showRestoreFailedWithError(_ error: String)
  @objc optional func finalizePurchaseRestoration()
}

open class OddStoreKeeper: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver, SKRequestDelegate {
  
  static open let defaultStore = OddStoreKeeper()
  
  var prefixId: String {
    get {
      guard let bundleName = Bundle.main.bundleIdentifier else { return "unknownBundleId." }
      return "\(bundleName)."
    }
  }
  
  static open var productIdentifiers: Set<String> = Set()
  fileprivate var products: Array<SKProduct> = Array()
  fileprivate var productsRequest: SKProductsRequest?
  fileprivate var restoreRequest: SKReceiptRefreshRequest?
  
  open var delegate: StoreKeeperDelegate?
  open var transactionDelegate: StoreKeeperTransactionDelegate?
  open var restoreDelegate: StoreKeeperRestorePurchasesDelegate?
  
  // MARK: - Class Methods
  static open func canMakePayments() -> Bool {
    return SKPaymentQueue.canMakePayments()
  }
  
  // MARK: - Products
  
  func fetchProductIdentifiers() {
    guard let url = Bundle.main.url(forResource: "iap_product_ids", withExtension: "plist"),
      let idArray = NSArray(contentsOf: url) as? Array<String> else { return }
    OddStoreKeeper.productIdentifiers = Set(idArray.map { "\(prefixId)\($0)" } )
  }
  
  open func validateProductIdentifiers() {
    self.fetchProductIdentifiers()
    self.productsRequest = SKProductsRequest(productIdentifiers: OddStoreKeeper.productIdentifiers)
    
    self.productsRequest?.delegate = self
    self.productsRequest?.start()
  }
  
  //MARK: - SKProductsRequestDelegate
  
  open func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
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
  
  open func request(_ request: SKRequest, didFailWithError error: Error) {
    OddLogger.logAndDisplayError(error: "Store Request Error: \(error.localizedDescription)")
  }
  
  func logRequest(_ request: SKRequest) {
    guard let req = request as? SKReceiptRefreshRequest else { return }
    
    OddLogger.info("Refresh Receipt: \(String(describing: req.receiptProperties))")
  }
  
  // currently only called when we restore a receipt
  open func requestDidFinish(_ request: SKRequest) {
    guard request is SKReceiptRefreshRequest else { return }
    
//    logRequest(request)
    OddLogger.info("Receipt Refresh Request did finish")
    self.restoreDelegate?.finalizePurchaseRestoration?()
  }
  
  // MARK: - Payments
  
  open func makePaymentForProduct(_ product: SKProduct) {
    SKPaymentQueue.default().add(self)
    let payment = SKMutablePayment(product: product)
    SKPaymentQueue.default().add(payment)
  }
  
  //
  open func restorePurchase() {
//    request = [[SKReceiptRefreshRequest alloc] init];
    self.restoreRequest = SKReceiptRefreshRequest()
    self.restoreRequest?.delegate = self;
    self.restoreRequest?.start()
//    SKPaymentQueue.defaultQueue().addTransactionObserver(self)
//    SKPaymentQueue.defaultQueue().restoreCompletedTransactions()
  }
  
  open func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
    OddLogger.info("Restore Purchases Finished")
    self.restoreDelegate?.showRestoreCompleted()
  }
  
  open func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
    OddLogger.error("Restore Purchases failed with error: \(error.localizedDescription)")
    self.restoreDelegate?.showRestoreFailedWithError(error.localizedDescription)
  }
  
  // MARK: - SKPaymentTransactionObserver
  
  open func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
    transactions.forEach { (transaction) in
      switch transaction.transactionState {
      case .purchasing:
        self.showTransactionInProgress(deferred: false)
      case .deferred:
        self.showTransactionInProgress(deferred: true)
      case .failed:
        self.failedTransaction(transaction)
      case .purchased:
        self.completeTransaction(transaction)
      case .restored:
        self.restoreTransaction(transaction)
      }
    }
  }
  
  // MARK: - Transaction Helpers
  
  func showTransactionInProgress(deferred: Bool) {
    if deferred {
      OddLogger.info("StoreKeeper deferred transaction in progress")
      self.transactionDelegate?.showPurchaseInProgress?(deferred: true)
    } else {
      OddLogger.info("StoreKeeper transaction in progress")
      self.transactionDelegate?.showPurchaseInProgress?(deferred: false)
    }
  }
  
  func failedTransaction(_ transaction: SKPaymentTransaction) {
    OddLogger.error("StoreKeeper transaction \(transaction.transactionIdentifier!) failed: \(transaction.error!)")
    self.transactionDelegate?.showPurchaseFailed?(withTransaction: transaction)
    self.productsRequest = nil
  }
  
  func completeTransaction(_ transaction: SKPaymentTransaction) {
    OddLogger.info("StoreKeeper transaction complete: \(transaction.transactionIdentifier!)")
    self.transactionDelegate?.showPurchaseCompleted?(withTransaction: transaction)
    self.productsRequest = nil
  }

  // not currently used.
  func restoreTransaction(_ transaction: SKPaymentTransaction) {
    OddLogger.info("StoreKeeper transaction restoration complete (Apple): \(transaction.transactionIdentifier!)")
    
    switch transaction.transactionState {
    case .deferred: print("DEFERED")
    case .failed: print("FAILED")
    case .purchased: print("PURCHASED")
    case .purchasing: print("PURCHASING")
    case .restored: print("RESTORED")
    }
    
    self.restoreDelegate?.finalizePurchaseRestoration?()
//    self.transactionDelegate?.showPurchaseRestored?(transaction)
    self.productsRequest = nil
  }
  
  open func finishTransaction(_ transaction: SKPaymentTransaction) {
    SKPaymentQueue.default().finishTransaction(transaction)
    self.reset()
  }
  
  open func reset() {
    self.delegate = nil
    self.transactionDelegate = nil
    self.restoreDelegate = nil
  }

}
