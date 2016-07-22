//
//  OddGateKeeper.swift
//  OddSDK
//
//  Created by Patrick McConnell on 1/19/16.
//  Copyright © 2016 Odd Networks, LLC. All rights reserved.
//

import UIKit

/// Options for Authorization Status
///
///
public enum AuthenticationStatus: String {
  //  case Inactive = "inactive"                // this application is not using authentication/authorization
  case Uninitialized = "uninitialized"      // the auth process has not been completed
  case Initialized = "initialized"          // the auth process started but failed to complete
  case Authorized = "authorized"            // the user is authorized
}

class AuthenticationCredentials: NSObject, NSCoding {
  
  var url: String? = nil
  var userCode: String? = nil
  var deviceToken: String? = nil
  var state: AuthenticationStatus = .Uninitialized
  var accessToken : String? = nil
  var entitlementCredentials: jsonObject? = nil
  
  override var description : String {
    return "URL: \(url)\n User Code: \(userCode)\n Device Token: \(deviceToken)\n State: \(state.rawValue)\n Access Token: \(accessToken)\n Creds: \(entitlementCredentials)"
  }
  
  class func emptyCredentials() -> AuthenticationCredentials {
    return AuthenticationCredentials(
      url: nil,
      userCode : nil,
      deviceToken: nil,
      state: .Uninitialized,
      accessToken: nil,
      entitlementCredentials: nil
    )
  }
  
  class func activeCredentials() -> AuthenticationCredentials {
    if let credentialData: NSData = Keychain.dataForAccount(OddConstants.kAuthenticationCredentialsAccountName) {
      guard let creds: AuthenticationCredentials = NSKeyedUnarchiver.unarchiveObjectWithData( credentialData ) as? AuthenticationCredentials else {
        return AuthenticationCredentials.emptyCredentials()
      }
      return creds
    } else {
      return AuthenticationCredentials.emptyCredentials()
    }
  }
  
  init( url: String?, userCode: String?, deviceToken: String?, state: AuthenticationStatus, accessToken: String?, entitlementCredentials : jsonObject?) {
    self.url = url
    self.userCode = userCode
    self.deviceToken = deviceToken
    self.state = state
    self.accessToken = accessToken
    self.entitlementCredentials = entitlementCredentials
  }
  
  // removed for now. Auth -> Enabled in the config now means the entire app is paywalled
  //  class func credentialsFromJson(json: jsonObject) {
  //    if let enabled = json["enabled"] as? Bool {
  //      if enabled && AuthenticationCredentials.activeCredentials().state == .Inactive {
  //        AuthenticationCredentials(
  //          url: nil,
  //          userCode: nil,
  //          deviceToken: nil,
  //          state: .Uninitialized,
  //          authenticationToken: nil
  //        ).save()
  //      } else if !enabled  {
  //        AuthenticationCredentials(
  //          url: nil,
  //          userCode: nil,
  //          deviceToken: nil,
  //          state: .Inactive,
  //          authenticationToken: nil
  //        ).save()
  //      }
  //    }
  //  }
  
  required convenience init?(coder decoder: NSCoder) {
    guard let url = decoder.decodeObjectForKey(OddConstants.kAuthenticationCredentialsURLKey) as? String?,
      let userCode = decoder.decodeObjectForKey(OddConstants.kAuthenticationCredentialsUserCodeKey) as? String?,
      let deviceToken = decoder.decodeObjectForKey(OddConstants.kAuthenticationCredentialsDeviceTokenKey) as? String?,
      let stateString = decoder.decodeObjectForKey(OddConstants.kAuthenticationCredentialsStateKey) as? String,
      let state: AuthenticationStatus = AuthenticationStatus( rawValue: stateString ),
      let accessToken = decoder.decodeObjectForKey(OddConstants.kAuthenticationCredentialsAccessTokenKey) as? String?,
      let entitlementCredentials = decoder.decodeObjectForKey(OddConstants.kAuthenticationCredentialsEntitlementCredentialsKey) as? jsonObject else { return nil }
    
    self.init(
      url: url,
      userCode : userCode,
      deviceToken: deviceToken,
      state: state,
      accessToken: accessToken,
      entitlementCredentials: entitlementCredentials
    )
  }
  
  func encodeWithCoder(coder: NSCoder) {
    coder.encodeObject(self.url, forKey: OddConstants.kAuthenticationCredentialsURLKey)
    coder.encodeObject(self.userCode, forKey: OddConstants.kAuthenticationCredentialsUserCodeKey)
    coder.encodeObject(self.deviceToken, forKey: OddConstants.kAuthenticationCredentialsDeviceTokenKey)
    coder.encodeObject(self.state.rawValue, forKey: OddConstants.kAuthenticationCredentialsStateKey)
    coder.encodeObject(self.entitlementCredentials, forKey: OddConstants.kAuthenticationCredentialsEntitlementCredentialsKey)
    coder.encodeObject(self.accessToken, forKey: OddConstants.kAuthenticationCredentialsAccessTokenKey)
  }
  
  func save() {
    let encodedcredentials = NSKeyedArchiver.archivedDataWithRootObject(self)
    Keychain.setData(encodedcredentials, forAccount: OddConstants.kAuthenticationCredentialsAccountName, synchronizable: true, background: false)
  }
  
  func updateAuthenticationCredentials(url url: String?, userCode: String?, deviceToken: String?, state: AuthenticationStatus?, accessToken: String?, entitlementCredentials: jsonObject?) {
    
    if let url = url {
      self.url = url
    }
    
    if let userCode = userCode {
      self.userCode = userCode
    }
    
    if let deviceToken = deviceToken {
      self.deviceToken = deviceToken
    }
    
    if let state = state {
      self.state = state
    }
    
    if let accessToken = accessToken {
      self.accessToken = accessToken
    }
    
    if let entitlementCredentials = entitlementCredentials {
      self.entitlementCredentials = entitlementCredentials
    }
    
    self.save()
  }
  
}


public class OddGateKeeper: NSObject {
  
  /// A singleton instance of the `GateKeeper` class
  /// All access to the users authentication credentials should be made
  /// through this singleton instance
  static public let sharedKeeper = OddGateKeeper()
  
  // The current user/device `AuthenticationCredentials`
  lazy var authenticationCredentials = AuthenticationCredentials.activeCredentials()
  
  /// The amount of times between requesting the Authentication status from the server
  ///
  /// When a user attempts to link a device they are directed to a web site in order
  /// to connect their device to their account on the clients platform. The SDK will
  /// poll the API for updates in the user/devices Authentication state.
  var authAttemptTimeDelta: NSTimeInterval = 5  // check for Authentication every 5 seconds
  
  /// Number of times the server will be contacted to check for Authentication status changes.
  /// This number multiplied by `authAttemptTimeDelta` will determine how long the SDK will
  /// attempt to detecet a change in state before stopping.
  var numberOfAuthAttempts: Int = 60            // number of times to try before failing
  
  /// A counter to track the number of attempts we have made to check auth state changes
  var authAttemptCount = 0
  
  /// A timer to trigger Authentication state change checks
  var pollingTimer: NSTimer?
  
  /// The device token for this user/device
  var deviceToken: String?
  
  var userMeta: jsonObject?
  
  /// The user/device Authentication Status
  public var authenticationStatus: AuthenticationStatus {
    get {
      return self.authenticationCredentials.state
    }
  }
  
  public func fetchAuthenticationConfig( callback: (url: String?, userCode: String?, deviceToken: String?, error: NSError?) -> Void ) {
    OddContentStore.sharedStore.API.post(nil, url: "auth/device/code") { (res, err) -> () in
      if let e = err {
        OddLogger.error("Error fetching auth config: \(e)")
        callback(url: nil, userCode: nil, deviceToken: nil, error: e)
      } else {
        if let json = res as? Dictionary<String, AnyObject> {
          OddLogger.info("Auth Config: \(json)")
          if let data = json["data"] as? Dictionary<String, AnyObject> {
            if let url: String? = data["attributes"]?["verification_url"] as? String,
              deviceToken: String? = data["attributes"]?["device_code"] as? String,
              userCode: String? = data["attributes"]?["user_code"] as? String {
              
              self.authenticationCredentials.updateAuthenticationCredentials( url: url,
                                                                              userCode: userCode,
                                                                              deviceToken: deviceToken,
                                                                              state: .Initialized,
                                                                              accessToken: nil,
                                                                              entitlementCredentials: nil )
              
              callback(url: url, userCode: userCode, deviceToken: deviceToken, error: nil)
            }
          }
        }
      }
    }
  }
  
  public func blowAwayCredentials() {
    self.authenticationCredentials.updateAuthenticationCredentials( url: nil,
                                                                    userCode: nil,
                                                                    deviceToken: nil,
                                                                    state: .Uninitialized,
                                                                    accessToken: nil,
                                                                    entitlementCredentials: nil
    )
  }
  
  public func fetchAuthenticationToken() {
    print("checking for Authentication")
    
    guard let deviceToken = self.authenticationCredentials.deviceToken else { return }
    
    print("checking token: \(deviceToken)")
    
    let currentAuthenticationState = self.authenticationStatus
    
    OddContentStore.sharedStore.API.post(["type":"authorized_user","attributes":["device_code":"\(deviceToken)"]], url:"auth/device/token") { (res, err) -> () in
      if let error = err,
        response = res {
        print("Error:\(error.localizedDescription)")
        if response.statusCode == 401 {
          self.authenticationCredentials.updateAuthenticationCredentials( url: nil,
                                                                          userCode: nil,
                                                                          deviceToken: nil,
                                                                          state: .Uninitialized,
                                                                          accessToken: nil,
                                                                          entitlementCredentials: nil
          )
        } else {
          NSNotificationCenter.defaultCenter().postNotificationName(OddConstants.OddAuthenticationErrorCheckingStateNotification, object: self.authenticationCredentials, userInfo: nil)
        }
      } else {
        guard let json = res as? jsonObject,
          let data = json["data"] as? jsonObject,
          let attribs = data["attributes"] as? jsonObject,
          let accessToken = attribs["access_token"] as? String,
          let userProfile = attribs["deviceUserProfile"] else { return }
        
        let creds = userProfile["entitlementCredentials"] as? jsonObject
        
        print("AUTH DATA: \(data)")
        self.authenticationCredentials.updateAuthenticationCredentials( url: nil,
                                                                        userCode: nil,
                                                                        deviceToken: deviceToken,
                                                                        state: .Authorized,
                                                                        accessToken: accessToken,
                                                                        entitlementCredentials: creds
        )
        /* debugging only
         print(json)
         print("Auth status changed")
         */
        if currentAuthenticationState != .Authorized {
          NSNotificationCenter.defaultCenter().postNotificationName(OddConstants.OddAuthenticationStateChangedNotification, object: self.authenticationCredentials, userInfo: nil)
        }
        self.pollingTimer?.invalidate()
      }
    }
  }
  
  func checkForAuthentication() {
    if authAttemptCount < numberOfAuthAttempts {
      authAttemptCount += 1
      print("Checking for change in auth status: \(authAttemptCount)")
      fetchAuthenticationToken()
    } else {
      print("Stopping check for change in auth status")
      pollingTimer?.invalidate()
    }
  }
  
  public func pollForAuthentication() {
    print("Starting polling timer")
    authAttemptCount = 0
    pollingTimer?.invalidate()
    // timer must be configured on the main thread or it will not fire
    dispatch_async(dispatch_get_main_queue(), { () -> Void in
      self.pollingTimer = NSTimer.scheduledTimerWithTimeInterval(self.authAttemptTimeDelta, target: self, selector: #selector(OddGateKeeper.checkForAuthentication), userInfo: nil, repeats: true)
    })
    print("Timer started")
  }
  
  public func userIsAuthenticated() -> Bool {
    return OddGateKeeper.sharedKeeper.authenticationStatus == .Authorized
  }
  
  /// Convenience method to retun all keys in the
  /// entitlements credentials dictionary
  public func entitlementKeys() -> Set<String>? {
    var result = Set<String>()
    if let meta = OddGateKeeper.sharedKeeper.authenticationCredentials.entitlementCredentials {
      meta.keys.forEach({ (key) -> () in
        result.insert(key)
      })
      return result
    }
    return nil
  }
  
  /// Convenience method to return a given keys value
  /// or nil if it is not found
  public func valueForEntitlementKey(key: String) -> AnyObject? {
    if let keys = entitlementKeys() {
      if keys.contains(key) {
        return OddGateKeeper.sharedKeeper.authenticationCredentials.entitlementCredentials![key]!
      }
    }
    return nil
  }
  
  public func entitlementCredentials() -> jsonObject? {
    guard let creds = OddGateKeeper.sharedKeeper.authenticationCredentials.entitlementCredentials else { return nil }
    return creds
  }
  
  public func updateEntitlementCredentials(creds: jsonObject) {
    self.authenticationCredentials.updateAuthenticationCredentials( url: nil,
                                                                    userCode: nil,
                                                                    deviceToken: nil,
                                                                    state: nil,
                                                                    accessToken: nil,
                                                                    entitlementCredentials: creds
    )
  }
  
  
  // MARK: - Login
  typealias JSONCallback = ( (jsonObject?, NSError?) -> Void)
  
  private func get(params: [ String : String ]?, url: String, callback: JSONCallback) {
    request("GET", params: params, url: url, callback: callback)
  }
  
  private func post(params: [ String : AnyObject ]?, url: String, callback: JSONCallback) {
    request("POST", params: params, url: url, callback: callback)
  }
  
  private func request(type: String, params: [ String : AnyObject ]?, url: String, callback: JSONCallback) {
    let request = NSMutableURLRequest(URL: NSURL(string: url)!)
    let session = NSURLSession.sharedSession()
    request.HTTPMethod = type
    
    let err: NSError?
    
    if let parameters = params {
      do {
        request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(parameters, options: [])
      } catch let error as NSError {
        err = error
        request.HTTPBody = nil
        OddLogger.error("Error attaching HTTP request params: \(err?.localizedDescription)")
      }
    }
    
    //Utility Headers:
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("application/json", forHTTPHeaderField: "Accept")
    
    let task = session.dataTaskWithRequest(request, completionHandler: { data, response, error -> Void in
      
      if let e = error {
        if e.code < -999 { // NSURLError.NotConnectedToInternet.rawValue {
          NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: OddConstants.OddConnectionOfflineNotification, object: e) )
        }
        callback(nil, e)
        return
      }
      
      if let res = response as! NSHTTPURLResponse! {
        
        if res.statusCode != 200 {
          OddLogger.error("Error, server responded with: \(res.statusCode)" )
          let e = NSError(domain: "ODD", code: 101, userInfo: [ "statusCode": res.statusCode, "message" : "unable to complete http request" ])
          callback(nil, e)
          return
        }
      }
      
      if error == nil {
        do {
          let json = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers) as? jsonObject
          callback(json, nil)
          return
        } catch {
          let e = NSError(domain: "ODD", code: 102, userInfo: [ "message" : "JSON Parsing Error" ])
          callback(nil, e)
        }
      }
    })
    
    task.resume()
  }
  
  public func autoLoginWithURL(url: String, success: (Bool) -> Void) {
    let defaults = NSUserDefaults.standardUserDefaults()
    guard let email = defaults.stringForKey(OddConstants.kOddLoginName),
      let password = defaults.stringForKey(OddConstants.kOddLoginPassword) else { success(false); return }
    print("Attempting autologin with: \(email) - \(password)")
    self.loginWithURL(url, email: email, password: password) { (result, error) -> () in
      success(result)
    }
  }
  
  // the server should return 200 with a payload of any credentials required for metrics, etc
  public func loginWithURL(url: String, email: String, password: String, callback: (Bool, NSError?) -> Void) {
    let params = [ "email" : email, "password" : password ]
    
    self.post(params, url: url) { (response, error) in
      if error != nil {
        callback(false, error)
      }
      else {
        guard let json = response,
          let success = json["success"] as? Bool else { callback(false, nil); return }
        if let meta = json["meta"] as? jsonObject {
          self.userMeta = meta
          OddLogger.info("Received Login Meta: \(self.userMeta)");
        }
        if success {
          self.updateLoginCredentialsWithEmail(email, password: password)
        }
        OddLogger.info("Login User Result: \(success)")
        callback(success, nil)
      }
    }
  }
  
  func updateLoginCredentialsWithEmail(email: String, password: String) {
    print("Saving login info")
    let defaults = NSUserDefaults.standardUserDefaults()
    defaults.setValue(email, forKey: OddConstants.kOddLoginName)
    defaults.setValue(password, forKey: OddConstants.kOddLoginPassword)
    defaults.synchronize()
  }
  
  // prior to creating a subscription on the clients servers we request verification that 
  // it is possible to create a subscription using these credentials. No subscription should
  // be created. This is called prior to contacting Apple to process payment for a subscription
  public func validateSubscription(url: String,
                                   level: String,
                                   email: String,
                                   firstName: String,
                                   lastName: String,
                                   password: String, callback: (Bool, jsonObject?, NSError?) -> Void ) {
    let params = [
      "level" : level,
      "email" : email,
      "firstName" : firstName,
      "lastName" : lastName,
      "password" : password,
      "deviceId" : "abcd",
      "applicationId" : "1234"
    ]
    
    self.post(params, url: url) { (response, error) in
      if error != nil {
        callback(false, nil, error)
      } else {
        guard let json = response,
          let success = json["success"] as? Bool else { callback (false, nil, nil); return }
        
        callback(success, json["meta"] as? jsonObject, nil)
        OddLogger.info("Validate Subscription result: \(success)")
      }
    }
  }
  
  // after Apple has taken payment and created a subscription this method is used to create a subscription
  // on the clients servers
  public func createSubscription(url: String,
                                 level: String,
                                 email: String,
                                 firstName: String,
                                 lastName: String,
                                 password: String, callback: (Bool, jsonObject?, NSError?) -> Void ) {
    
    guard let receiptURL = NSBundle.mainBundle().appStoreReceiptURL,
      receiptData = NSData(contentsOfURL: receiptURL)?.base64EncodedStringWithOptions(.Encoding64CharacterLineLength) else {
      OddLogger.error("Unable to retrieve app store receipt")
      callback (false, nil, nil)
      return
    }
    
    let params = [
      "level" : level,
      "email" : email,
      "firstName" : firstName,
      "lastName" : lastName,
      "password" : password,
      "deviceId" : "abcd",
      "applicationId" : "1234",
      "receiptId" : receiptData
    ]
    
    self.post(params, url: url) { (response, error) in
      if error != nil {
        callback(false, nil, error)
      } else {
        guard let json = response,
          let success = json["success"] as? Bool else { callback (false, nil, nil); return }
        
        callback(success, json["meta"] as? jsonObject, nil)
        OddLogger.info("Create Subscription result: \(success)")
      }
    }
  }
  
  
}
