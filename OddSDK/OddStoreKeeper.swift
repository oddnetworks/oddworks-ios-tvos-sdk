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

public class OddStoreKeeper: NSObject, SKProductsRequestDelegate {
  
  var prefixId: String {
    get {
      guard let bundleName = NSBundle.mainBundle().bundleIdentifier else { return "unknownBundleId." }
      return "\(bundleName)."
    }
  }
  
  private var productIdentifiers: Set<String> = Set()
  private var products: Array<SKProduct> = Array()
  private var productsRequest: SKProductsRequest = SKProductsRequest()
  
  public override init() {
    super.init()
    fetchProductIdentifiers()
    validateProductIdentifiers()
  }
  
  func fetchProductIdentifiers() {
    guard let url = NSBundle.mainBundle().URLForResource("iap_product_ids", withExtension: "plist"),
      let idArray = NSArray(contentsOfURL: url) as? Array<String> else { return }
    self.productIdentifiers = Set(idArray.map { "\(prefixId)\($0)" } )
  }
  
  func validateProductIdentifiers() {
    self.productsRequest = SKProductsRequest(productIdentifiers: self.productIdentifiers)
    
    self.productsRequest.delegate = self
    self.productsRequest.start()
  }
  
  public func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
    self.products = response.products
    
    response.invalidProductIdentifiers.forEach { (invalid) in
      OddLogger.error("\(invalid) is an invalid product identifier")
    }
    
    self.products.forEach { (product) in
      OddLogger.info("\(product.localizedTitle) is valid")
    }
  }
  
  public func request(request: SKRequest, didFailWithError error: NSError) {
    OddLogger.error("\(error.localizedDescription)")
  }
  
  public func requestDidFinish(request: SKRequest) {
    OddLogger.info("Request did finish")
  }
}
