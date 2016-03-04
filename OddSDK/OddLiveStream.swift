//
//  OddLiveStream.swift
//  PokerCentral
//
//  Created by Patrick McConnell on 7/31/15.
//  Copyright (c) 2015 Patrick McConnell. All rights reserved.
//

import UIKit

class OddLiveStream: OddMediaObject {
  
  override var contentTypeString: String { return "livestream" }
  
  class func streamFromJson(json: jsonObject) -> OddLiveStream {
    let newStream = OddLiveStream()
    newStream.configureWithJson(json)
    
    newStream.defaultTitle = "Poker Central Live Stream"
    newStream.defaultSubtitle = "Another fine video stream from Poker Central"

    return newStream
  }
}
