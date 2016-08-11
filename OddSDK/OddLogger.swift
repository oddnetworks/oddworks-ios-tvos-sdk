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
  case info
  case warn
  case error
  
  func glyph() -> String {
    switch self {
    case .info: return "✅"
    case .warn: return "⚠️"
    case .error: return "❌"
    }
  }
  
  func atLeast(_ level: OddLogLevel) -> Bool {
    return level.rawValue >= self.rawValue
  }
}

public class OddLogger: NSObject {
  
  public static var tag : String = ""
  
  public static var logLevel: OddLogLevel = .error
  
  private static func formattedTag() -> String {
    return self.tag.isEmpty ? "" : "\(self.tag): "
  }
  
  private static func log( message: String) {
    if tag.isEmpty {
      print("\(logLevel.glyph()) \(message)")
    } else {
      print("\(logLevel.glyph()) \(tag): \(message)")
    }
    
  }
  
  public static func info(_ message: String) {
    if OddLogger.logLevel.atLeast(.info)   {
      log(message: message)
    }
  }
  
  public static func warn(_ message: String) {
    if OddLogger.logLevel.atLeast(.warn)  {
      log(message: message)
    }
  }
  
  public static func error(_ message: String) {
    log(message: message)
  }
  
  // grabs the topmost viewController and presents an alert dialog to the user
  public static func presentMessageToUser(title: String, message: String, kind: OddLogLevel? = nil) {
    let decoratedTitle = kind != nil ? "\(kind!.glyph()) \(title)" : title
    guard let topVC = UIApplication.topViewController() else { return }
    let alert = UIAlertController(title: decoratedTitle, message: message, preferredStyle: .alert)
    let okAction = UIAlertAction(title: "OK", style: .default, handler: { (action) in
      topVC.dismiss(animated: true, completion: {
        
      })
    })
    alert.addAction(okAction)
    topVC.present(alert, animated: true, completion: { print("done") })
  }

  
}
