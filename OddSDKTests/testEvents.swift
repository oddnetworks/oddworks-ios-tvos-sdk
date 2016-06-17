//
//  testEvents.swift
//  OddSDK
//
//  Created by Patrick McConnell on 6/15/16.
//  Copyright © 2016 Patrick McConnell. All rights reserved.
//

import XCTest

struct MockEventsRequestHandler: OddHTTPRequestService {
  
//  func decodePayload(tokenstr: String) {
//    
//    //splitting JWT to extract payload
//    let arr = tokenstr.componentsSeparatedByString(".")
////    let arr = split(tokenstr) {$0 == "."}
//    
//    //base64 encoded string i want to decode
//    var base64String = arr[1] as String
//    if base64String.characters.count % 4 != 0 {
//      let padlen = 4 - base64String.characters.count % 4
//      base64String += String(count: padlen, repeatedValue: Character("="))
//    }
//    
//    if let data = NSData(base64EncodedString: base64String, options: []),
//      let str = String(data: data, encoding: NSUTF8StringEncoding) {
//      print(str) // {"exp":1426822163,"id":"550b07738895600e99000001"}
//    }
//  }

  
  func validateEvent(params: [String : AnyObject]?, url: String, altDomain: String?, callback: APICallback) -> Bool {
    if params == nil {
      callback(nil, NSError(domain: "EventsRequestHandlerError", code: 001, userInfo: ["error" : "missing Params"]) )
      return false
    }
    
    if url != "events" {
      callback(nil, NSError(domain: "EventsRequestHandlerError", code: 002, userInfo: ["error" : "incorrect url"]) )
      return false
    }
    
    guard let d = OddContentStore.sharedStore.API.authToken.decodeJWTPayload() else {
      callback(nil, NSError(domain: "EventsRequestHandlerError", code: 003, userInfo: ["error" : "missing JWT"]) )
      return false
    }
    
    guard let aud = d["aud"] as? Array<String> else {
      callback(nil, NSError(domain: "EventsRequestHandlerError", code: 004, userInfo: ["error" : "missing JWT AUD"]) )
      return false
    }
    
    if !aud.contains("odd-events-server") {
      callback(nil, NSError(domain: "EventsRequestHandlerError", code: 005, userInfo: ["error" : "incorrect JWT AUD"]) )
      return false
    }
    
//    print("d: \(d)")
    
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
      EventSettings(action: .VideoLoad, actionString: "video:load", enabled: true, interval: nil),
      EventSettings(action: .VideoPlay, actionString: "video:play", enabled: true, interval: nil),
      EventSettings(action: .VideoPlaying, actionString: "video:playing", enabled: true, interval: 3),
      EventSettings(action: .VideoStop, actionString: "video:stop", enabled: true, interval: nil),
      EventSettings(action: .VideoError, actionString: "video:error", enabled: true, interval: nil),
      EventSettings(action: .UserNew, actionString: "user:new", enabled: true, interval: nil)
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
    XCTAssertEqual(sessionId, e.sessionId(), "Events Service SessionId should stay constant between app launches")
    XCTAssertEqual(sessionId, e.sessionId(), "Events Service SessionId should stay constant between app launches")
    XCTAssertEqual(sessionId, e.sessionId(), "Events Service SessionId should stay constant between app launches")
  }
  
  func testEventServiceIssuesNewVideoSessionIds() {
    let e = OddEventsService.defaultService
    e.resetVideoSessionId()
    let oldId = e.videoSessionId
    e.resetVideoSessionId()
    XCTAssertNotEqual(oldId, e.videoSessionId, "Event Service should issue new video session ids on demand")
  }
  
  func testEventServiceSendsAppInit() {
    let okExpectation = expectationWithDescription("ok")
    configureForAllEvents()
    
    let e = OddEventsService.defaultService
    e.deliveryService = MockEventsRequestHandler()
    e.postAppInitMetric { (res, err) in
      guard let response = res as? jsonObject,
        attribs = response["attributes"] as? jsonObject else { okExpectation.fulfill(); return }
      
      XCTAssertEqual(response["type"] as? String, "event", "Events Service should post an app init")
      XCTAssertEqual(attribs["userId"] as? String, OddEventsService.defaultService.userId(), "Events Service should post an app init with UserId")
      XCTAssertEqual(attribs["sessionId"] as? String, OddEventsService.defaultService.sessionId(), "Events Service should post an app init with SessionId")
      XCTAssertEqual(attribs["action"] as? String, "app:init", "Events Service should post an app init")
      okExpectation.fulfill()
      
    }
    
    waitForExpectationsWithTimeout(5, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }
  
  func testEventServiceSendsViewLoad() {
    let okExpectation = expectationWithDescription("ok")
    configureForAllEvents()
    
    let e = OddEventsService.defaultService
    e.deliveryService = MockEventsRequestHandler()
    e.postMetricForAction(.ViewLoad, playerInfo: nil, content: nil) { (res, err) in
      guard let response = res as? jsonObject,
        attribs = response["attributes"] as? jsonObject else { okExpectation.fulfill(); return }
      
      XCTAssertEqual(response["type"] as? String, "event", "Events Service should post an app init")
      XCTAssertEqual(attribs["userId"] as? String, OddEventsService.defaultService.userId(), "Events Service should post a view load event with UserId")
      XCTAssertEqual(attribs["sessionId"] as? String, OddEventsService.defaultService.sessionId(), "Events Service should post a view load event with SessionId")
      XCTAssertEqual(attribs["action"] as? String, "view:load", "Events Service should post a view load event")
      okExpectation.fulfill()
    }
    
    waitForExpectationsWithTimeout(5, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }
  
  func testEventServiceSendsVideoLoad() {
    let okExpectation = expectationWithDescription("ok")
    configureForAllEvents()
    
    let e = OddEventsService.defaultService
    e.deliveryService = MockEventsRequestHandler()
    
    e.resetVideoSessionId()
    let playerInfo = OddMediaPlayerInfo(playerType:"native", elapsed: 0, duration: 30000, videoSessionId: e.videoSessionId, errorMessage: nil)
    let video = OddVideo()
    video.id = "abcd1234"
    video.title = "an odd video"
    let image = OddImage(url: "http://somewhere.com/someimage.png", mimeType: "image/png", width: 1024, height: 760, label: "an image")
    video.images = [ image ]
    
    e.postMetricForAction(.VideoLoad, playerInfo: playerInfo, content: video) { (res, err) in
      guard let response = res as? jsonObject,
        attribs = response["attributes"] as? jsonObject else { okExpectation.fulfill(); return }
      
      XCTAssertEqual(response["type"] as? String, "event", "Events Service should post an app init")
      XCTAssertEqual(attribs["userId"] as? String, OddEventsService.defaultService.userId(), "Events Service should post a video load with UserId")
      XCTAssertEqual(attribs["sessionId"] as? String, OddEventsService.defaultService.sessionId(), "Events Service should post a video load with SessionId")
      XCTAssertEqual(attribs["videoSessionId"] as? String, OddEventsService.defaultService.videoSessionId, "Events Service should post a video load with VideoSessionId")
      XCTAssertEqual(attribs["action"] as? String, "video:load", "Events Service should post a video load event")
      XCTAssertEqual(attribs["duration"] as? Int, 30000, "Events Service should post a video load event")
      XCTAssertEqual(attribs["elapsed"] as? Int, 0, "Events Service should post a video load event")
      okExpectation.fulfill()
    }
    
    waitForExpectationsWithTimeout(5, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }
  
  func testEventServiceSendsVideoPlay() {
    let okExpectation = expectationWithDescription("ok")
    configureForAllEvents()
    
    let e = OddEventsService.defaultService
    e.deliveryService = MockEventsRequestHandler()
    
    // this is normally set on video:load but testing...
    e.resetVideoSessionId()
    let playerInfo = OddMediaPlayerInfo(playerType:"native", elapsed: 0, duration: 30000, videoSessionId: e.videoSessionId, errorMessage: nil)
    let video = OddVideo()
    video.id = "abcd1234"
    video.title = "an odd video"
    let image = OddImage(url: "http://somewhere.com/someimage.png", mimeType: "image/png", width: 1024, height: 760, label: "an image")
    video.images = [ image ]
    
    e.postMetricForAction(.VideoPlay, playerInfo: playerInfo, content: video) { (res, err) in
      guard let response = res as? jsonObject,
        attribs = response["attributes"] as? jsonObject else { okExpectation.fulfill(); return }
      
      XCTAssertEqual(response["type"] as? String, "event", "Events Service should post an app init")
      XCTAssertEqual(attribs["userId"] as? String, OddEventsService.defaultService.userId(), "Events Service should post a video play with UserId")
      XCTAssertEqual(attribs["sessionId"] as? String, OddEventsService.defaultService.sessionId(), "Events Service should post a video play with SessionId")
      XCTAssertEqual(attribs["videoSessionId"] as? String, OddEventsService.defaultService.videoSessionId, "Events Service should post a video play with VideoSessionId")
      XCTAssertEqual(attribs["action"] as? String, "video:play", "Events Service should post a video play event")
      XCTAssertEqual(attribs["duration"] as? Int, 30000, "Events Service should post a video play event")
      XCTAssertEqual(attribs["elapsed"] as? Int, 0, "Events Service should post a video play event")
      okExpectation.fulfill()
    }
    
    waitForExpectationsWithTimeout(5, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }
  
  func testEventServiceSendsVideoPlaying() {
    let okExpectation = expectationWithDescription("ok")
    configureForAllEvents()
    
    let e = OddEventsService.defaultService
    e.deliveryService = MockEventsRequestHandler()
    
    // this is normally set on video:load but testing...
    e.resetVideoSessionId()
    let playerInfo = OddMediaPlayerInfo(playerType:"native", elapsed: 2345, duration: 30000, videoSessionId: e.videoSessionId, errorMessage: nil)
    let video = OddVideo()
    video.id = "abcd1234"
    video.title = "an odd video"
    let image = OddImage(url: "http://somewhere.com/someimage.png", mimeType: "image/png", width: 1024, height: 760, label: "an image")
    video.images = [ image ]
    
    e.postMetricForAction(.VideoPlaying, playerInfo: playerInfo, content: video) { (res, err) in
      guard let response = res as? jsonObject,
        attribs = response["attributes"] as? jsonObject else { okExpectation.fulfill(); return }
      
      XCTAssertEqual(response["type"] as? String, "event", "Events Service should post an app init")
      XCTAssertEqual(attribs["userId"] as? String, OddEventsService.defaultService.userId(), "Events Service should post a video playing event with UserId")
      XCTAssertEqual(attribs["sessionId"] as? String, OddEventsService.defaultService.sessionId(), "Events Service should post a video playing event with SessionId")
      XCTAssertEqual(attribs["videoSessionId"] as? String, OddEventsService.defaultService.videoSessionId, "Events Service should post a video playing event with VideoSessionId")
      XCTAssertEqual(attribs["action"] as? String, "video:playing", "Events Service should post a video playing event")
      XCTAssertEqual(attribs["duration"] as? Int, 30000, "Events Service should post a video playing event")
      XCTAssertEqual(attribs["elapsed"] as? Int, 2345, "Events Service should post a video playing event")
      okExpectation.fulfill()
    }
    
    waitForExpectationsWithTimeout(5, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }

  func testEventServiceSendsVideoStop() {
    let okExpectation = expectationWithDescription("ok")
    configureForAllEvents()
    
    let e = OddEventsService.defaultService
    e.deliveryService = MockEventsRequestHandler()
    
    // this is normally set on video:load but testing...
    e.resetVideoSessionId()
    let playerInfo = OddMediaPlayerInfo(playerType:"native", elapsed: 2345, duration: 30000, videoSessionId: e.videoSessionId, errorMessage: nil)
    let video = OddVideo()
    video.id = "abcd1234"
    video.title = "an odd video"
    let image = OddImage(url: "http://somewhere.com/someimage.png", mimeType: "image/png", width: 1024, height: 760, label: "an image")
    video.images = [ image ]
    
    e.postMetricForAction(.VideoStop, playerInfo: playerInfo, content: video) { (res, err) in
      guard let response = res as? jsonObject,
        attribs = response["attributes"] as? jsonObject else { okExpectation.fulfill(); return }
      
      XCTAssertEqual(response["type"] as? String, "event", "Events Service should post an app init")
      XCTAssertEqual(attribs["userId"] as? String, OddEventsService.defaultService.userId(), "Events Service should post a video playing event with UserId")
      XCTAssertEqual(attribs["sessionId"] as? String, OddEventsService.defaultService.sessionId(), "Events Service should post a video playing event with SessionId")
      XCTAssertEqual(attribs["videoSessionId"] as? String, OddEventsService.defaultService.videoSessionId, "Events Service should post a video playing event with VideoSessionId")
      XCTAssertEqual(attribs["action"] as? String, "video:stop", "Events Service should post a video playing event")
      XCTAssertEqual(attribs["duration"] as? Int, 30000, "Events Service should post a video playing event")
      XCTAssertEqual(attribs["elapsed"] as? Int, 2345, "Events Service should post a video playing event")
      okExpectation.fulfill()
    }
    
    waitForExpectationsWithTimeout(5, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }

  
  func testEventServiceSendsVideoError() {
    let okExpectation = expectationWithDescription("ok")
    configureForAllEvents()
    
    let e = OddEventsService.defaultService
    e.deliveryService = MockEventsRequestHandler()
    
    // this is normally set on video:load but testing...
    e.resetVideoSessionId()
    let playerInfo = OddMediaPlayerInfo(playerType:"native", elapsed: 2345, duration: 30000, videoSessionId: e.videoSessionId, errorMessage: "an error message")
    let video = OddVideo()
    video.id = "abcd1234"
    video.title = "an odd video"
    let image = OddImage(url: "http://somewhere.com/someimage.png", mimeType: "image/png", width: 1024, height: 760, label: "an image")
    video.images = [ image ]
    
    e.postMetricForAction(.VideoError, playerInfo: playerInfo, content: video) { (res, err) in
      guard let response = res as? jsonObject,
        attribs = response["attributes"] as? jsonObject else { okExpectation.fulfill(); return }
      
      XCTAssertEqual(response["type"] as? String, "event", "Events Service should post an app init")
      XCTAssertEqual(attribs["userId"] as? String, OddEventsService.defaultService.userId(), "Events Service should post a video error event with UserId")
      XCTAssertEqual(attribs["sessionId"] as? String, OddEventsService.defaultService.sessionId(), "Events Service should post a video error event with SessionId")
      XCTAssertEqual(attribs["videoSessionId"] as? String, OddEventsService.defaultService.videoSessionId, "Events Service should post a video error event with VideoSessionId")
      XCTAssertEqual(attribs["action"] as? String, "video:error", "Events Service should post a video error event")
      XCTAssertEqual(attribs["duration"] as? Int, 30000, "Events Service should post a video duration with a video error event")
      XCTAssertEqual(attribs["elapsed"] as? Int, 2345, "Events Service should post a video elapsed time with a video error event")
      XCTAssertEqual(attribs["errorMessage"] as? String, "an error message", "Events Service should post a video error with a video error event")
      okExpectation.fulfill()
    }
    
    waitForExpectationsWithTimeout(5, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }

  func testEventServiceSendsUserNew() {
    let okExpectation = expectationWithDescription("ok")
    configureForAllEvents()
    
    let e = OddEventsService.defaultService
    e.deliveryService = MockEventsRequestHandler()
    
    e.postMetricForAction(.UserNew, playerInfo: nil, content: nil) { (res, err) in
      guard let response = res as? jsonObject,
        attribs = response["attributes"] as? jsonObject else { okExpectation.fulfill(); return }
      
      XCTAssertEqual(response["type"] as? String, "event", "Events Service should post a user new event")
      XCTAssertEqual(attribs["userId"] as? String, OddEventsService.defaultService.userId(), "Events Service should post a user new event with UserId")
      XCTAssertEqual(attribs["sessionId"] as? String, OddEventsService.defaultService.sessionId(), "Events Service should post a user new event with SessionId")
      XCTAssertEqual(attribs["action"] as? String, "user:new", "Events Service should post a user new event")
      okExpectation.fulfill()
    }
    
    waitForExpectationsWithTimeout(5, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }
  
  // this test will only work with an actual events service instance 
  // as we don't want to validate JWTs in the app
  func testEventServiceFailsWithIncorrectJWT() {
    let okExpectation = expectationWithDescription("ok")
    configureForAllEvents()
   
    // this JWT has no AUD 
    OddContentStore.sharedStore.API.authToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ2ZXJzaW9uIjoxLCJjaGFubmVsIjoibmFzYSIsInBsYXRmb3JtIjoiYXBwbGUtaW9zIiwic2NvcGUiOlsicGxhdGZvcm0iXSwiaWF0IjoxNDYxMzMxNTI5fQ.lsVlk7ftYKxxrYTdl8rP-dCUfk9odhCxvwm9jsUE1dU"
    
    let e = OddEventsService.defaultService
    e.deliveryService = MockEventsRequestHandler()
    
    e.postAppInitMetric { (res, err) in
      XCTAssertNotNil(err, "Events submission should fail with incorrect JWT")
      XCTAssertEqual(err?.userInfo["error"] as? String, "missing JWT AUD", "Events submission should fail if missing JWT AUD")
      okExpectation.fulfill()
    }
    
    waitForExpectationsWithTimeout(5, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }
  
}
