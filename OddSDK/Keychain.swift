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
    guard let bundleName = Bundle.main.infoDictionary!["CFBundleName"] as? String else { return "OddKeychainService_test" }
    return "OddKeychainService_\(bundleName)"
  }
  
  static func deleteAccount(_ account: String) {
    do {
      try SecItemWrapper.delete([
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: serviceName() as AnyObject,
        kSecAttrAccount as String: account as AnyObject,
        kSecAttrSynchronizable as String: kSecAttrSynchronizableAny,
        ])
    } catch KeychainError.itemNotFound {
      // Ignore this error.
    } catch let error {
      NSLog("deleteAccount error: \(error)")
    }
  }
  
  static func dataForAccount(_ account: String) -> Data? {
    do {
      let query = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: serviceName(),
        kSecAttrAccount as String: account,
        kSecAttrSynchronizable as String: kSecAttrSynchronizableAny,
        kSecReturnData as String: kCFBooleanTrue as CFTypeRef,
      ] as [String : Any]
      let result = try SecItemWrapper.matching(query as [String : AnyObject])
      return result as? Data
    } catch KeychainError.itemNotFound {
      // Ignore this error, simply return nil.
      return nil
    } catch let error {
      NSLog("dataForAccount error: \(error)")
      return nil
    }
  }
  
  static func stringForAccount(_ account: String) -> String? {
    if let data = dataForAccount(account) {
      return NSString(data: data,
        encoding: String.Encoding.utf8.rawValue) as String?
    } else {
      return nil
    }
  }
  
  static func setData(_ data: Data,
    forAccount account: String,
    synchronizable: Bool,
    background: Bool) {
      do {
        // Remove the item if it already exists.
        // This saves having to deal with SecItemUpdate.
        // Reasonable people may disagree with this approach.
        deleteAccount(account)
        
        // Add it.
        try _ = SecItemWrapper.add([
          kSecClass as String: kSecClassGenericPassword,
          kSecAttrService as String: serviceName() as AnyObject,
          kSecAttrAccount as String: account as AnyObject,
          kSecAttrSynchronizable as String: synchronizable ?
            kCFBooleanTrue : kCFBooleanFalse,
          kSecValueData as String: data as AnyObject,
          kSecAttrAccessible as String: background ?
            kSecAttrAccessibleAfterFirstUnlock :
          kSecAttrAccessibleWhenUnlocked,
          ])
      } catch let error {
        NSLog("setData error: \(error)")
      }
  }
  
  static func setString(_ string: String,
    forAccount account: String,
    synchronizable: Bool,
    background: Bool) {
      let data = string.data(using: String.Encoding.utf8)!
      setData(data,
        forAccount: account,
        synchronizable: synchronizable,
        background: background)
  }
    
  struct SecItemWrapper {
    static func matching(_ query: [String: AnyObject]) throws -> AnyObject? {
      var result: AnyObject?
      let rawStatus = SecItemCopyMatching(query as CFDictionary, &result)
      
      if let error = KeychainError.errorFromOSStatus(rawStatus) {
        throw error
      }
      return result
    }
    
    static func add(_ attributes: [String: AnyObject]) throws -> AnyObject? {
      var result: AnyObject?
      let rawStatus = SecItemAdd(attributes as CFDictionary, &result)
      
      if let error = KeychainError.errorFromOSStatus(rawStatus) {
        throw error
      }
      return result
    }
    
    static func update(_ query: [String: AnyObject],
      attributesToUpdate: [String: AnyObject]) throws {
        let rawStatus = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
        if let error = KeychainError.errorFromOSStatus(rawStatus) {
          throw error
        }
    }
    
    static func delete(_ query: [String: AnyObject]) throws {
      let rawStatus = SecItemDelete(query as CFDictionary)
      if let error = KeychainError.errorFromOSStatus(rawStatus) {
        throw error
      }
    }
  }
  
  enum KeychainError: Error {
    case unimplemented
    case param
    case allocate
    case notAvailable
    case authFailed
    case duplicateItem
    case itemNotFound
    case interactionNotAllowed
    case decode
    case unknown
    
    /// Returns the appropriate error for the status, or nil if it
    /// was successful, or Unknown for a code that doesn't match.
    static func errorFromOSStatus(_ rawStatus: OSStatus) -> KeychainError? {
      if rawStatus == errSecSuccess {
        return nil
      } else {
        // If the mapping doesn't find a match, return unknown.
        return mapping[rawStatus] ?? .unknown
      }
    }
    
    static let mapping: [Int32: KeychainError] = [
      errSecUnimplemented: .unimplemented,
      errSecParam: .param,
      errSecAllocate: .allocate,
      errSecNotAvailable: .notAvailable,
      errSecAuthFailed: .authFailed,
      errSecDuplicateItem: .duplicateItem,
      errSecItemNotFound: .itemNotFound,
      errSecInteractionNotAllowed: .interactionNotAllowed,
      errSecDecode: .decode
    ]
  }
}
