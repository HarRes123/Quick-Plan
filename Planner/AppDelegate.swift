//
//  AppDelegate.swift
//  Planner
//
//  Created by Harrison Resnick on 6/9/20.
//  Copyright © 2020 Harrison Resnick. All rights reserved.
//

import Firebase
import GoogleSignIn
import UIKit

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    // [START didfinishlaunching]
    func application(_: UIApplication,
                     didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        GIDSignIn.sharedInstance().clientID = "822317343063-e7vjk7hv66ungvddj0nu82a4n857m9cp.apps.googleusercontent.com"
        
        // controller identifier sets up in storyboard utilities
        // panel (on the right), it called Storyboard ID
        var viewController = UIViewController()
        if Auth.auth().currentUser != nil, Auth.auth().currentUser!.isEmailVerified == true {
            viewController = storyboard.instantiateViewController(withIdentifier: "mainVC")
        } else {
            viewController = storyboard.instantiateViewController(withIdentifier: "signInVC") as! SignInViewController
        }
        
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        
        window?.rootViewController = viewController
        window?.makeKeyAndVisible()
        
        return true
    }
    
    func application(_: UIApplication, performFetchWithCompletionHandler _: @escaping (UIBackgroundFetchResult) -> Void) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "performFetch"), object: nil)
    }
}
