//
//  UIApplication+TopVC.swift
//  
//
//  Created by Patrick McConnell on 9/11/15.
//  Copyright (c) 2015 Patrick McConnell. All rights reserved.
//

import Foundation
import UIKit

extension UIApplication {
  class func topViewController(base: UIViewController? = UIApplication.sharedApplication().keyWindow?.rootViewController) -> UIViewController? {
    
    if let nav = base as? UINavigationController {
      return topViewController(nav.visibleViewController)
    }
    
    if let tab = base as? UITabBarController {
      let moreNavigationController = tab.moreNavigationController
      
      if let top = moreNavigationController.topViewController where top.view.window != nil {
        return topViewController(top)
      } else if let selected = tab.selectedViewController {
        return topViewController(selected)
      }
    }
    
    if let presented = base?.presentedViewController {
      return topViewController(presented)
    }
    
    return base
  }
}