//
//  testEvents.swift
//  OddSDK
//
//  Created by Patrick McConnell on 6/15/16.
//  Copyright © 2016 Patrick McConnell. All rights reserved.
//

import XCTest

struct RequestHandler: OddHTTPRequestService {
  func post(params: [String : AnyObject]?, url: String, altDomain: String?, callback: APICallback) {
    
    let domain = altDomain == nil ? "" : altDomain!
    let params = params == nil ? ["none": ""] : params!
    
    print("received post to: \(domain)\(url) with params: \(params)")
    callback(params, nil)
  }
}

class OddEventsTests: XCTestCase {
  
  override func setUp() {
    super.setUp()
    OddLogger.logLevel = .Info

    // if making actual requests this JWT will be required
    OddContentStore.sharedStore.API.authToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ2ZXJzaW9uIjoxLCJjaGFubmVsIjoibmFzYSIsInBsYXRmb3JtIjoiYXBwbGUtaW9zIiwic2NvcGUiOlsicGxhdGZvcm0iXSwiaWF0IjoxNDYxMzMxNTI5fQ.lsVlk7ftYKxxrYTdl8rP-dCUfk9odhCxvwm9jsUE1dU"
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }
  
  func testEventsServiceHasAUserId() {
    let e = OddEventsService.defaultService
    XCTAssertNotEqual(e.userId(), "", "Events Service should have a UserId")
  }
  
  func testEventsServiceHasASessionId() {
    let e = OddEventsService.defaultService
    XCTAssertNotEqual(e.sessionId(), "", "Events Service should have a SessionId")
  }
  
  func testSessionIdIsMaintainedForASession() {
    let e = OddEventsService.defaultService
    let sessionId = e.sessionId()
    XCTAssertNotEqual(sessionId, e.sessionId(), "Events Service SessionId should stay constant between app launches")
    XCTAssertNotEqual(sessionId, e.sessionId(), "Events Service SessionId should stay constant between app launches")
    XCTAssertNotEqual(sessionId, e.sessionId(), "Events Service SessionId should stay constant between app launches")
  }
  
  func testEventServiceSendsAppInit() {
    let config = OddConfig()
    let eventsConfig = EventsConfiguration( enabledStats: [
      EventSettings(action: .AppInit, actionString: "app:init", enabled: true, interval: nil),
      EventSettings(action: .ViewLoad, actionString: "view:load", enabled: true, interval: nil),
      EventSettings(action: .VideoPlay, actionString: "video:play", enabled: true, interval: nil),
      EventSettings(action: .VideoPlaying, actionString: "video:playing", enabled: true, interval: 3),
      EventSettings(action: .VideoStop, actionString: "video:stop", enabled: true, interval: nil),
      EventSettings(action: .VideoError, actionString: "video:error", enabled: true, interval: nil)
    ])
    config.analyticsManager = eventsConfig
    
    OddContentStore.sharedStore.config = config
    
    
    let e = OddEventsService.defaultService
    e.deliveryService = RequestHandler()
    e.postAppInitMetric()
  }
}
