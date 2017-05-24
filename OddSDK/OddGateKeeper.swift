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
    return "URL: \(String(describing: url))\n User Code: \(String(describing: userCode))\n Device Token: \(String(describing: deviceToken))\n State: \(state.rawValue)\n Access Token: \(String(describing: accessToken))\n Creds: \(String(describing: entitlementCredentials))"
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
    if let credentialData: Data = Keychain.dataForAccount(OddConstants.kAuthenticationCredentialsAccountName) {
      guard let creds: AuthenticationCredentials = NSKeyedUnarchiver.unarchiveObject( with: credentialData ) as? AuthenticationCredentials else {
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
    guard let url = decoder.decodeObject(forKey: OddConstants.kAuthenticationCredentialsURLKey) as? String?,
      let userCode = decoder.decodeObject(forKey: OddConstants.kAuthenticationCredentialsUserCodeKey) as? String?,
      let deviceToken = decoder.decodeObject(forKey: OddConstants.kAuthenticationCredentialsDeviceTokenKey) as? String?,
      let stateString = decoder.decodeObject(forKey: OddConstants.kAuthenticationCredentialsStateKey) as? String,
      let state: AuthenticationStatus = AuthenticationStatus( rawValue: stateString ),
      let accessToken = decoder.decodeObject(forKey: OddConstants.kAuthenticationCredentialsAccessTokenKey) as? String?,
      let entitlementCredentials = decoder.decodeObject(forKey: OddConstants.kAuthenticationCredentialsEntitlementCredentialsKey) as? jsonObject else { return nil }
    
    self.init(
      url: url,
      userCode : userCode,
      deviceToken: deviceToken,
      state: state,
      accessToken: accessToken,
      entitlementCredentials: entitlementCredentials
    )
  }
  
  func encode(with coder: NSCoder) {
    coder.encode(self.url, forKey: OddConstants.kAuthenticationCredentialsURLKey)
    coder.encode(self.userCode, forKey: OddConstants.kAuthenticationCredentialsUserCodeKey)
    coder.encode(self.deviceToken, forKey: OddConstants.kAuthenticationCredentialsDeviceTokenKey)
    coder.encode(self.state.rawValue, forKey: OddConstants.kAuthenticationCredentialsStateKey)
    coder.encode(self.entitlementCredentials, forKey: OddConstants.kAuthenticationCredentialsEntitlementCredentialsKey)
    coder.encode(self.accessToken, forKey: OddConstants.kAuthenticationCredentialsAccessTokenKey)
  }
  
  func save() {
    let encodedcredentials = NSKeyedArchiver.archivedData(withRootObject: self)
    Keychain.setData(encodedcredentials, forAccount: OddConstants.kAuthenticationCredentialsAccountName, synchronizable: true, background: false)
  }
  
  func updateAuthenticationCredentials(url: String?, userCode: String?, deviceToken: String?, state: AuthenticationStatus?, accessToken: String?, entitlementCredentials: jsonObject?) {
    
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


open class OddGateKeeper: NSObject {
  
  /// A singleton instance of the `GateKeeper` class
  /// All access to the users authentication credentials should be made
  /// through this singleton instance
  static open let sharedKeeper = OddGateKeeper()
  
  // The current user/device `AuthenticationCredentials`
  lazy var authenticationCredentials = AuthenticationCredentials.activeCredentials()
  
  /// The amount of times between requesting the Authentication status from the server
  ///
  /// When a user attempts to link a device they are directed to a web site in order
  /// to connect their device to their account on the clients platform. The SDK will
  /// poll the API for updates in the user/devices Authentication state.
  var authAttemptTimeDelta: TimeInterval = 5  // check for Authentication every 5 seconds
  
  /// Number of times the server will be contacted to check for Authentication status changes.
  /// This number multiplied by `authAttemptTimeDelta` will determine how long the SDK will
  /// attempt to detecet a change in state before stopping.
  var numberOfAuthAttempts: Int = 60            // number of times to try before failing
  
  /// A counter to track the number of attempts we have made to check auth state changes
  var authAttemptCount = 0
  
  /// A timer to trigger Authentication state change checks
  var pollingTimer: Timer?
  
  /// The device token for this user/device
  var deviceToken: String?
  
  var userMeta: jsonObject?
  
  // custome http headers to be added to all requests to the login/authorization server 
  open var customUserHeaders: Dictionary<String, String> = Dictionary()
  
  /// The user/device Authentication Status
  open var authenticationStatus: AuthenticationStatus {
    get {
      return self.authenticationCredentials.state
    }
  }
  
    // fetches the user authorization info from oddworks.
    public func fetchAuthenticationConfig( _ callback: @escaping (_ url: String?, _ userCode: String?, _ deviceToken: String?, _ error: NSError?) -> Void ) {
        OddContentStore.sharedStore.API.post(nil, url: "auth/device/code") { (res, err) -> () in
            if let e = err {
                OddLogger.error("Error fetching auth config: \(e)")
                callback(nil, nil, nil, e)
            } else {
                if let json = res as? Dictionary<String, AnyObject> {
                    //          OddLogger.info("Auth Config: \(json)")
                    
                    // old swift
                    //          if let data = json["data"] as? Dictionary<String, AnyObject> {
                    //            if let url: String? = data["attributes"]?["verification_url"] as? String,
                    //              let deviceToken: String? = data["attributes"]?["device_code"] as? String,
                    //              let userCode: String? = data["attributes"]?["user_code"] as? String {
                    
                    guard let data = json["data"] as? jsonObject,
                        let attribs = data["attributes"] as? jsonObject,
                        let url = attribs["verification_url"] as? String,
                        let deviceToken = attribs["device_code"] as? String,
                        let userCode = attribs["user_code"] as? String else {
                            let error = NSError(domain: "Odd", code: 100, userInfo: ["error" : "Unable to decode response"])
                            callback(nil, nil, nil, error)
                            return
                    }
                    
                    self.authenticationCredentials.updateAuthenticationCredentials( url: url,
                                                                                    userCode: userCode,
                                                                                    deviceToken: deviceToken,
                                                                                    state: .Initialized,
                                                                                    accessToken: nil,
                                                                                    entitlementCredentials: nil )
                    
                    callback(url, userCode, deviceToken, nil)
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
  
  // checks that a user has completed the authorization process
  open func fetchAuthenticationToken() {
    print("checking for Authentication")
    
    guard let deviceToken = self.authenticationCredentials.deviceToken else { return }
    
    print("checking token: \(deviceToken)")
    
    let currentAuthenticationState = self.authenticationStatus
    
    OddContentStore.sharedStore.API.post(["type":"authorized_user" as AnyObject,"attributes":["device_code":"\(deviceToken)"] as AnyObject], url:"auth/device/token") { (res, err) -> () in
      if let error = err {
//        response = res {
        print("Error:\(error.localizedDescription)")
        OddLogger.logAndDisplayError("Unable to authorize user. Error code: \(error.code)")
        if error.code == 401 {
          self.blowAwayCredentials()
        } else {
          NotificationCenter.default.post(name: OddConstants.OddAuthenticationErrorCheckingStateNotification, object: self.authenticationCredentials, userInfo: nil)
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
          NotificationCenter.default.post(name: OddConstants.OddAuthenticationStateChangedNotification, object: self.authenticationCredentials, userInfo: nil)
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
  
  open func pollForAuthentication() {
    print("Starting polling timer")
    authAttemptCount = 0
    pollingTimer?.invalidate()
    // timer must be configured on the main thread or it will not fire
    DispatchQueue.main.async(execute: { () -> Void in
      self.pollingTimer = Timer.scheduledTimer(timeInterval: self.authAttemptTimeDelta, target: self, selector: #selector(OddGateKeeper.checkForAuthentication), userInfo: nil, repeats: true)
    })
    print("Timer started")
  }
  
  open func userIsAuthenticated() -> Bool {
    return OddGateKeeper.sharedKeeper.authenticationStatus == .Authorized
  }
  
  /// Convenience method to retun all keys in the
  /// entitlements credentials dictionary
  open func entitlementKeys() -> Set<String>? {
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
  open func valueForEntitlementKey(_ key: String) -> AnyObject? {
    if let keys = entitlementKeys() {
      if keys.contains(key) {
        return OddGateKeeper.sharedKeeper.authenticationCredentials.entitlementCredentials![key]!
      }
    }
    return nil
  }
  
  open func entitlementCredentials() -> jsonObject? {
    guard let creds = OddGateKeeper.sharedKeeper.authenticationCredentials.entitlementCredentials else { return nil }
    return creds
  }
  
  open func updateEntitlementCredentials(_ creds: jsonObject) {
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
  
  fileprivate func get(_ params: [ String : String ]?, url: String, callback: @escaping JSONCallback) {
    self.request("GET", params: params as jsonObject?, url: url, callback: callback)
  }
  
  fileprivate func post(_ params: [ String : AnyObject ]?, url: String, callback: @escaping JSONCallback) {
    self.request("POST", params: params, url: url, callback: callback)
  }
  
  fileprivate func request(_ type: String, params: [ String : AnyObject ]?, url: String, callback: @escaping JSONCallback) {
    let request = NSMutableURLRequest(url: URL(string: url)!)
    let session = URLSession.shared
    request.httpMethod = type
    
    let err: NSError?
    
    if let parameters = params {
      do {
        request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
      } catch let error as NSError {
        err = error
        request.httpBody = nil
        OddLogger.error("Error attaching HTTP request params: \(String(describing: err?.localizedDescription))")
      }
    }
    
    //Utility Headers:
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("application/json", forHTTPHeaderField: "Accept")
    
    
    self.customUserHeaders.forEach({ (headerName, headerValue) in
      print("Adding custom header: \(headerName)")
        request.addValue(headerValue, forHTTPHeaderField: headerName)
    })
    
    
    // custom headers...
    
    let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error -> Void in
      
      if let e = error as? URLError {
        if e.code == .notConnectedToInternet {
          NotificationCenter.default.post(Notification(name: OddConstants.OddConnectionOfflineNotification, object: e) )
        }
        callback(nil, e as NSError?)
        return
      }
      
      if let res = response as! HTTPURLResponse! {
        
        if res.statusCode != 200 {
          if res.statusCode == 401 {
            self.blowAwayCredentials()
          }
          OddLogger.logAndDisplayError("Error, server responded with: \(res.statusCode)" )
          let e = NSError(domain: "ODD", code: res.statusCode, userInfo: [ "statusCode": res.statusCode, "message" : "unable to complete http request" ])
          callback(nil, e)
          return
        }
      }
      
      if error == nil {
        do {
          let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? jsonObject
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
  
//  public func autoLoginWithURL(url: String, success: (Bool) -> Void) {
//    let defaults = NSUserDefaults.standardUserDefaults()
//    guard let email = defaults.stringForKey(OddConstants.kOddLoginName),
//      let password = defaults.stringForKey(OddConstants.kOddLoginPassword) else { success(false); return }
//    print("Attempting autologin with: \(email) - \(password)")
//    self.loginWithURL(url, email: email, password: password) { (result, error) -> () in
//      success(result)
//    }
//  }
  
  // the server should return 200 with a payload of any credentials required for metrics, etc
//  public func loginWithURL(url: String, email: String, password: String, callback: (Bool, NSError?) -> Void) {
  open func loginWithURL(_ url: String, params: [ String : AnyObject ]?, callback: @escaping (Bool, NSError?) -> Void) {
  
    self.post(params, url: url) { (response, error) in
      if error != nil {
        callback(false, error)
      }
      else {
        guard let json = response,
          let success = json["success"] as? Bool,
          let meta = json["meta"] as? jsonObject else { callback(false, nil); return }
        if success {
          print("LOGIN SUCCESS")
          self.userMeta = meta
          OddLogger.info("Received Login Meta: \(String(describing: self.userMeta))");
//          self.updateLoginCredentialsWithEmail(email, password: password)
        } else {
          if let title = meta["lead"] as? String,
            let message = meta["message"] as? String{
            print("ERROR: \(title): \(message)")
            OddLogger.showAlert(withTitle: title, message: message, kind: .error)
          }
        }
        OddLogger.info("Login User Result: \(success)")
        callback(success, nil)
      }
    }
  }
  
  func updateLoginCredentialsWithEmail(_ email: String, password: String) {
    print("Saving login info")
    let defaults = UserDefaults.standard
    defaults.setValue(email, forKey: OddConstants.kOddLoginName)
    defaults.setValue(password, forKey: OddConstants.kOddLoginPassword)
    defaults.synchronize()
  }
  
  // prior to creating a subscription on the clients servers we request verification that 
  // it is possible to create a subscription using these credentials. No subscription should
  // be created. This is called prior to contacting Apple to process payment for a subscription
  open func validateSubscription(_ url: String, params: [ String : AnyObject ]?, callback: @escaping (Bool, jsonObject?, NSError?) -> Void ) {
    
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
  open func createSubscription(_ url: String, params: [ String : AnyObject ]?, callback: @escaping (Bool, jsonObject?, NSError?) -> Void ) {
    
    guard let params = params,
      let receiptURL = Bundle.main.appStoreReceiptURL,
      let receiptData = (try? Data(contentsOf: receiptURL))?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) else {
      OddLogger.error("Unable to retrieve app store receipt (Subscribe)")
      callback (false, nil, nil)
      return
    }
    
    var fullParams = params
    
    fullParams["receiptId"] = receiptData as AnyObject
    
    print("FULL PARAMS subscribe: \(fullParams)")
    
    self.post(fullParams, url: url) { (response, error) in
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
  
  open func restoreSubscription(_ url: String, params: [String : AnyObject]?, callback: @escaping (Bool, jsonObject?, NSError?) -> Void) {
    guard let params = params,
      let receiptURL = Bundle.main.appStoreReceiptURL,
      let receiptData = (try? Data(contentsOf: receiptURL))?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) else {
        OddLogger.error("Unable to retrieve app store receipt (Restore)")
        callback (false, nil, nil)
        return
    }
    
    var fullParams = params
    
    fullParams["receiptId"] = receiptData as AnyObject
    
    print("FULL PARAMS restore: \(fullParams)")
    
    self.post(fullParams, url: url) { (response, error) in
      if error != nil {
        callback(false, nil, error)
      } else {
        guard let json = response,
          let success = json["success"] as? Bool else { callback (false, nil, nil); return }
        
        callback(success, json["meta"] as? jsonObject, nil)
        OddLogger.info("Restore Subscription result: \(success)")
      }
    }
  }
  
  
}
