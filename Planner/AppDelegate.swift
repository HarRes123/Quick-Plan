//
//  AppDelegate.swift
//  Planner
//
//  Created by Harrison Resnick on 6/9/20.
//  Copyright © 2020 Harrison Resnick. All rights reserved.
//

import UIKit
import GoogleSignIn

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {

  var window: UIWindow?
    
  // [START didfinishlaunching]
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

    GIDSignIn.sharedInstance().clientID = "136124065580-737s6o2l8t0jsj975oskchvr2jrmpljq.apps.googleusercontent.com"
    GIDSignIn.sharedInstance().delegate = self

    return true
  }

  func application(_ application: UIApplication,
                   open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
    return GIDSignIn.sharedInstance().handle(url)
  }

  @available(iOS 9.0, *)
  func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
    return GIDSignIn.sharedInstance().handle(url)
  }
    
  func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!,
            withError error: Error!) {

    if let error = error {
      if (error as NSError).code == GIDSignInErrorCode.hasNoAuthInKeychain.rawValue {
        print("The user has not signed in before or they have since signed out.")
        
      } else {
        print("\(error.localizedDescription)")
      }
      NotificationCenter.default.post(
        name: Notification.Name(rawValue: "ToggleAuthUINotification"), object: nil, userInfo: nil)
      return
    }
//    let userId = user.userID                  // For client-side use only!
//    let idToken = user.authentication.idToken // Safe to send to the server
      let fullName = user.profile.name
//    let givenName = user.profile.givenName
//    let familyName = user.profile.familyName
//    let email = user.profile.email
    NotificationCenter.default.post(
      name: Notification.Name(rawValue: "ToggleAuthUINotification"),
      object: nil,
      userInfo: ["statusText": "Signed in user:\n\(fullName!)"])
  }

  func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!,
            withError error: Error!) {

    NotificationCenter.default.post(
      name: Notification.Name(rawValue: "ToggleAuthUINotification"),
      object: nil,
      userInfo: ["statusText": "User has disconnected."])
  }
}
