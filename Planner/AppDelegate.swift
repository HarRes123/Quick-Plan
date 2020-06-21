//
//  AppDelegate.swift
//  Planner
//
//  Created by Harrison Resnick on 6/9/20.
//  Copyright © 2020 Harrison Resnick. All rights reserved.
//

import UIKit
import GoogleSignIn
import Firebase

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {
    
    var window: UIWindow?
    
  // [START didfinishlaunching]
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

    GIDSignIn.sharedInstance().clientID = "822317343063-e7vjk7hv66ungvddj0nu82a4n857m9cp.apps.googleusercontent.com"
    GIDSignIn.sharedInstance().delegate = self
    FirebaseApp.configure()
    
    let storyboard = UIStoryboard.init(name: "Main", bundle: nil)

    // controller identifier sets up in storyboard utilities
    // panel (on the right), it called Storyboard ID
    var viewController = UIViewController()
    if Auth.auth().currentUser != nil && Auth.auth().currentUser!.isEmailVerified == true {
        viewController = storyboard.instantiateViewController(withIdentifier: "mainVC")
    } else {
        viewController = storyboard.instantiateViewController(withIdentifier: "signInVC") as! SignInViewController
    }

    self.window?.rootViewController = viewController
    self.window?.makeKeyAndVisible()


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
    //  print(fullName)
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
