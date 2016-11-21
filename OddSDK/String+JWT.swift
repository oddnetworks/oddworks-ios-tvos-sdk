//
//  String+JWT.swift
//  OddSDK
//
//  Created by Patrick McConnell on 6/17/16.
//  Copyright © 2016 Patrick McConnell. All rights reserved.
//

import Foundation

extension String {
  
  func decodeJWTPayload() -> Dictionary<String, AnyObject?>? {
    
    //splitting JWT to extract payload
    let arr = self.components(separatedBy: ".")
  
    //base64 encoded string i want to decode
    var base64String = arr[1] as String
    if base64String.characters.count % 4 != 0 {
      let padlen = 4 - base64String.characters.count % 4
//      base64String += String(count: padlen, repeatedValue: Character("="))
      base64String += String(repeating: "=", count: padlen )
    }
    
    if let data = NSData(base64Encoded: base64String, options: []),
      let str = String(data: data as Data, encoding: String.Encoding.utf8) {
      print(str) // {"exp":1426822163,"id":"550b07738895600e99000001"}
      
      var json: AnyObject?
      do {
        json = try JSONSerialization.jsonObject(with: data as Data, options: .mutableLeaves) as AnyObject?
        guard let dict = json as? Dictionary<String, AnyObject> else { return nil }
        return dict
      } catch {
        print("Error decoding JWT payload")
      }
    }
    return nil
  }

}
