//
//  AppDelegate.swift
//  DebugApp
//
//  Created by Patrick McConnell on 1/13/16.
//  Copyright © 2016 Odd Networks LLC. All rights reserved.
//

import UIKit

/*
  This simple app is useful for testing and debuging changes to the SDK. 
  By default the method: configureOnContentLoaded is called after the 
  OddContentStore is initialized. Place any test methods in that location
  to have them executed after the store is initialized.

  It is difficult to debug in apps with compiled frameworks. It is not 
  possible to set breakpoints or otherwise monitor execution of code
  within the SDK. We use this app as a launching point for those sorts of
  tests.
*/

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    initializeSDK()
    return true
  }

  func applicationWillResignActive(application: UIApplication) {
  }

  func applicationDidEnterBackground(application: UIApplication) {
  }

  func applicationWillEnterForeground(application: UIApplication) {
  }

  func applicationDidBecomeActive(application: UIApplication) {
  }

  func applicationWillTerminate(application: UIApplication) {
  }

  
  func registerForNotifications() {
    OddLogger.info("Registering For Notifications")
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "configureOnContentLoaded", name: OddConstants.OddContentStoreCompletedInitialLoadNotification, object: nil)
  }
  

  func configureOnContentLoaded() {
    print("Store Info: \( OddContentStore.sharedStore.mediaObjectInfo() )")
    if let featured = OddContentStore.sharedStore.featuredCollections,
      collection = featured.first {
        collection.fetchAllObjects({ (objects) -> Void in
          print("Objects: \(objects)")
      })
    }

  }

  func initializeSDK() {
    registerForNotifications()
    
    OddContentStore.sharedStore.API.serverMode = .Staging
    
//    Uncomment to see additional log messages from the SDK.
//    OddLogger.logLevel = .Info

//    Enter your authToken here
//    OddContentStore.sharedStore.API.authToken = "YOUR AUTHTOKEN"
    
    OddContentStore.sharedStore.API.authToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ2ZXJzaW9uIjoxLCJkZXZpY2VJRCI6ImFiMGUzNTAwLWU1NDQtMTFlNS04MGQxLTY1MTMzMTM1ZDk1MiIsInNjb3BlIjpbImRldmljZSJdLCJpYXQiOjE0NTc0NjI5MDR9.49KEckf_NvAAFmKp6GrC5sqFUAOzmJ1xI6IpzT4UhgY"

    OddContentStore.sharedStore.initialize()
  }
  
}

