//
//  OddLogger.swift
//  OddSDK
//
//  Created by Patrick McConnell on 1/6/16.
//  Copyright © 2016 Odd Networks, LLC. All rights reserved.
//

import UIKit

/// The level of logging to be displayed on the console.
/// Levels in order are 
@objc public enum OddLogLevel: Int {
  case Info
  case Warn
  case Error
  
  func atLeast(level: OddLogLevel) -> Bool {
    return level.rawValue >= self.rawValue
  }
}

public class OddLogger: NSObject {

  public static var logLevel: OddLogLevel = .Error
  
  public static func info(message: String) {
    if OddLogger.logLevel.atLeast(.Info)   {
      print("✅ \(message)")
    }
  }
  
  public static func warn(message: String) {
    if OddLogger.logLevel.atLeast(.Warn)  {
      print("⚠️ \(message)")
    }
  }
  
  public static func error(message: String) {
    print("❌ \(message)")
  }
}
