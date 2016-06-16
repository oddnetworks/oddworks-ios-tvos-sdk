//
//  testEvents.swift
//  OddSDK
//
//  Created by Patrick McConnell on 6/15/16.
//  Copyright © 2016 Patrick McConnell. All rights reserved.
//

import XCTest

class OddEventsTests: XCTestCase {
  
  override func setUp() {
    super.setUp()
    OddLogger.logLevel = .Info
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
  
}
