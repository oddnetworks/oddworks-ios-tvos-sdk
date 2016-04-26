//
//  Keychain.swift
//  SwiftKeychain
//
//  Created by Chris Hulbert on 14/06/2015.
//  Copyright (c) 2015 Chris Hulbert. All rights reserved.
//
//  Simple Swift 2 Keychain wrapper.

// Hat tip to http://www.splinter.com.au/2015/06/21/swift-keychain-wrapper/

import Foundation
import Security

struct Keychain {
  
  static func serviceName() -> String {
    // we return a default in case the SDK is run in a unit test with no bundle. derp.
    guard let bundleName = NSBundle.mainBundle().infoDictionary!["CFBundleName"] as? String else { return "OddKeychainService_test" }
    return "OddKeychainService_\(bundleName)"
  }
  
  static func deleteAccount(account: String) {
    do {
      try SecItemWrapper.delete([
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: serviceName(),
        kSecAttrAccount as String: account,
        kSecAttrSynchronizable as String: kSecAttrSynchronizableAny,
        ])
    } catch KeychainError.ItemNotFound {
      // Ignore this error.
    } catch let error {
      NSLog("deleteAccount error: \(error)")
    }
  }
  
  static func dataForAccount(account: String) -> NSData? {
    do {
      let query = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: serviceName(),
        kSecAttrAccount as String: account,
        kSecAttrSynchronizable as String: kSecAttrSynchronizableAny,
        kSecReturnData as String: kCFBooleanTrue as CFTypeRef,
      ]
      let result = try SecItemWrapper.matching(query)
      return result as? NSData
    } catch KeychainError.ItemNotFound {
      // Ignore this error, simply return nil.
      return nil
    } catch let error {
      NSLog("dataForAccount error: \(error)")
      return nil
    }
  }
  
  static func stringForAccount(account: String) -> String? {
    if let data = dataForAccount(account) {
      return NSString(data: data,
        encoding: NSUTF8StringEncoding) as? String
    } else {
      return nil
    }
  }
  
  static func setData(data: NSData,
    forAccount account: String,
    synchronizable: Bool,
    background: Bool) {
      do {
        // Remove the item if it already exists.
        // This saves having to deal with SecItemUpdate.
        // Reasonable people may disagree with this approach.
        deleteAccount(account)
        
        // Add it.
        try SecItemWrapper.add([
          kSecClass as String: kSecClassGenericPassword,
          kSecAttrService as String: serviceName(),
          kSecAttrAccount as String: account,
          kSecAttrSynchronizable as String: synchronizable ?
            kCFBooleanTrue : kCFBooleanFalse,
          kSecValueData as String: data,
          kSecAttrAccessible as String: background ?
            kSecAttrAccessibleAfterFirstUnlock :
          kSecAttrAccessibleWhenUnlocked,
          ])
      } catch let error {
        NSLog("setData error: \(error)")
      }
  }
  
  static func setString(string: String,
    forAccount account: String,
    synchronizable: Bool,
    background: Bool) {
      let data = string.dataUsingEncoding(NSUTF8StringEncoding)!
      setData(data,
        forAccount: account,
        synchronizable: synchronizable,
        background: background)
  }
    
  struct SecItemWrapper {
    static func matching(query: [String: AnyObject]) throws -> AnyObject? {
      var result: AnyObject?
      let rawStatus = SecItemCopyMatching(query, &result)
      
      if let error = KeychainError.errorFromOSStatus(rawStatus) {
        throw error
      }
      return result
    }
    
    static func add(attributes: [String: AnyObject]) throws -> AnyObject? {
      var result: AnyObject?
      let rawStatus = SecItemAdd(attributes, &result)
      
      if let error = KeychainError.errorFromOSStatus(rawStatus) {
        throw error
      }
      return result
    }
    
    static func update(query: [String: AnyObject],
      attributesToUpdate: [String: AnyObject]) throws {
        let rawStatus = SecItemUpdate(query, attributesToUpdate)
        if let error = KeychainError.errorFromOSStatus(rawStatus) {
          throw error
        }
    }
    
    static func delete(query: [String: AnyObject]) throws {
      let rawStatus = SecItemDelete(query)
      if let error = KeychainError.errorFromOSStatus(rawStatus) {
        throw error
      }
    }
  }
  
  enum KeychainError: ErrorType {
    case Unimplemented
    case Param
    case Allocate
    case NotAvailable
    case AuthFailed
    case DuplicateItem
    case ItemNotFound
    case InteractionNotAllowed
    case Decode
    case Unknown
    
    /// Returns the appropriate error for the status, or nil if it
    /// was successful, or Unknown for a code that doesn't match.
    static func errorFromOSStatus(rawStatus: OSStatus) -> KeychainError? {
      if rawStatus == errSecSuccess {
        return nil
      } else {
        // If the mapping doesn't find a match, return unknown.
        return mapping[rawStatus] ?? .Unknown
      }
    }
    
    static let mapping: [Int32: KeychainError] = [
      errSecUnimplemented: .Unimplemented,
      errSecParam: .Param,
      errSecAllocate: .Allocate,
      errSecNotAvailable: .NotAvailable,
      errSecAuthFailed: .AuthFailed,
      errSecDuplicateItem: .DuplicateItem,
      errSecItemNotFound: .ItemNotFound,
      errSecInteractionNotAllowed: .InteractionNotAllowed,
      errSecDecode: .Decode
    ]
  }
}