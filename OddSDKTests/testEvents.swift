//
//  testEvents.swift
//  OddSDK
//
//  Created by Patrick McConnell on 6/15/16.
//  Copyright © 2016 Patrick McConnell. All rights reserved.
//

import XCTest

struct MockEventsRequestHandler: OddHTTPRequestService {
  
  func validateEvent(params: [String : AnyObject]?, url: String, altDomain: String?, callback: APICallback) -> Bool {
    if params == nil {
      callback(nil, NSError(domain: "EventsRequestHandlerError", code: 001, userInfo: ["error" : "missing Params"]) )
      return false
    }
    
    if url != "events" {
      callback(nil, NSError(domain: "EventsRequestHandlerError", code: 002, userInfo: ["error" : "incorrect url"]) )
      return false
    }
    
    print("Event passed validation")
    return true
  }
  
  func post(params: [String : AnyObject]?, url: String, altDomain: String?, callback: APICallback) {
    
    if !validateEvent(params, url: url, altDomain: altDomain, callback: callback) { return }
    
    let domain = altDomain == nil ? "" : altDomain!
    let params = params == nil ? ["none": ""] : params!
    
    print("received post to: \(domain)\(url) with params: \(params)")
    callback(params, nil)
  }
}

class OddEventsTests: XCTestCase {
  
  func configureForAllEvents() {
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
  }
  
  override func setUp() {
    super.setUp()
    OddLogger.logLevel = .Info

    // if making actual requests this JWT will be required
    
    OddContentStore.sharedStore.API.authToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJjaGFubmVsIjoibmFzYSIsInBsYXRmb3JtIjoid2ViIiwiaWF0IjoxNDY2MDE0MzMwLCJhdWQiOlsib2RkLWV2ZW50cy1zZXJ2ZXIiXSwiaXNzIjoib2RkLXdlYi1jaGFubmVsIn0.GVz3k6ym_kkeqCcrC7W3JMBpyKwHZ8EMHJovmK6sSt4"
    
//    OddContentStore.sharedStore.API.authToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ2ZXJzaW9uIjoxLCJjaGFubmVsIjoibmFzYSIsInBsYXRmb3JtIjoiYXBwbGUtaW9zIiwic2NvcGUiOlsicGxhdGZvcm0iXSwiaWF0IjoxNDYxMzMxNTI5fQ.lsVlk7ftYKxxrYTdl8rP-dCUfk9odhCxvwm9jsUE1dU"
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
    let okExpectation = expectationWithDescription("ok")
    configureForAllEvents()
    
    let e = OddEventsService.defaultService
//    e.deliveryService = MockEventsRequestHandler()
    e.postAppInitMetric { (success, err) in
      XCTAssertEqual(success as? String, "success: app:init", "Events Service should post an app init")
      okExpectation.fulfill()
    }
    
    waitForExpectationsWithTimeout(5, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }
}
