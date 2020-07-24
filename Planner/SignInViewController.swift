//
//  SignInViewController.swift
//  Planner
//
//  Created by Harrison Resnick on 6/20/20.
//  Copyright © 2020 Harrison Resnick. All rights reserved.
//

import FirebaseUI
import UIKit

class SignInViewController: UIViewController, FUIAuthDelegate {
    @IBOutlet var logInOutlet: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpButton(button: logInOutlet, darkTint: UIColor.gray.cgColor)
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) {
            granted, _ in
            if granted {
                print("yes")
            } else {
                print("No")
            }

        }
    }

    @IBAction func loginTapped(_: UIButton) {
        let authUI = FUIAuth.defaultAuthUI()

        // Check that it isn't nil
        guard authUI != nil else {
            return
        }

        // Set delegate and specify sign in options
        authUI?.delegate = self
        authUI?.providers = [FUIEmailAuth(), FUIGoogleAuth()]

        // Get the auth view controller and present it
        let authViewController = FUIAuthCustomPickerViewController(authUI: authUI!)

        present(authViewController, animated: true, completion: nil)
    }
}
