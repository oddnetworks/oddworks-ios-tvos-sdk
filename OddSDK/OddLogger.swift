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
  case debug
  case info
  case warn
  case error
  
  func glyph() -> String {
    switch self {
    case .debug: return "🛠"
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
  
  
  private static func log( logLevel: OddLogLevel, message: String) {
    if tag.isEmpty {
      print("\(logLevel.glyph()) \(message)")
    } else {
      print("\(logLevel.glyph()) \(tag): \(message)")
    }
    
  }
  
  public static func debug(_ message: String) {
    if OddLogger.logLevel.atLeast(.debug) {
      log(logLevel: .debug, message: message)
    }
  }
  
  public static func info(_ message: String) {
    if OddLogger.logLevel.atLeast(.info)   {
      log(logLevel: .info, message: message)
    }
  }
  
  public static func warn(_ message: String) {
    if OddLogger.logLevel.atLeast(.warn)  {
      log(logLevel: .warn, message: message)
    }
  }
  
  public static func error(_ message: String) {
    log(logLevel: .error, message: message)
  }
  
  // grabs the topmost viewlkController and presents an alert dialog to the user
  public static func showAlert(withTitle title: String, message: String, kind: OddLogLevel? = nil) {
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
  
  
  //ERRORS
  public static func showErrorAlert(error: String) {
    OddLogger.showAlert(withTitle: "Error", message: error, kind: .error)
  }
  
  public static func logAndDisplayError(error: String) {
    OddLogger.error(error)
    OddLogger.showErrorAlert(error: error)
  }

  //WARNINGS
  public static func showWarningAlert(warning: String) {
    OddLogger.showAlert(withTitle: "Warning", message: warning, kind: .warn)
  }
  
  public static func logAndDisplayWarning(warning: String) {
    OddLogger.error(warning)
    OddLogger.showWarningAlert(warning: warning)
  }
  
  //INFO
  public static func showInfoAlert(info: String) {
    OddLogger.showAlert(withTitle: "Information", message: info, kind: .info)
  }
  
  public static func logAndDisplayInfo(info: String) {
    OddLogger.info(info)
    OddLogger.showInfoAlert(info: info)
  }
  
  //DEBUG
  public static func showDebugAlert(debug: String) {
    OddLogger.showAlert(withTitle: "Debug", message: debug, kind: .debug)
  }
  
  public static func logAndDisplayDebug(debug: String) {
    OddLogger.info(debug)
    OddLogger.showDebugAlert(debug: debug)
  }

  
  
  
}
