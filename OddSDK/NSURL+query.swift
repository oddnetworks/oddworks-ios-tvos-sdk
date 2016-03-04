//
//  NSURL+query.swift
//  Odd-iOS
//
//  Created by Patrick McConnell on 10/23/15.
//  Copyright © 2015 Patrick McConnell. All rights reserved.
//

import UIKit

// hat tip to http://blog.matthewcheok.com/parsing-query-parameters/

extension NSURL {
  var queryDictionary: [String:String]? {
    if let query = self.query {
      var dict = [String:String]()
      for parameter in query.componentsSeparatedByString("&") {
        let components = parameter.componentsSeparatedByString("=")
        if components.count == 2 {
          let key = components[0].stringByRemovingPercentEncoding!
          let value = components[1].stringByRemovingPercentEncoding!
          dict[key] = value
        }
      }
      return dict
    }
    else {
      return nil
    }
  }
}