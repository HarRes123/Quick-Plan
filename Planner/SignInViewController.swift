//
//  SignInViewController.swift
//  Planner
//
//  Created by Harrison Resnick on 6/20/20.
//  Copyright © 2020 Harrison Resnick. All rights reserved.
//

import UIKit
import FirebaseUI

class SignInViewController: UIViewController, FUIAuthDelegate {

    @IBOutlet weak var logInOutlet: UIButton!
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            logInOutlet.layer.cornerRadius = 8

        }
        
        @IBAction func loginTapped(_ sender: Any) {
            
            let authUI = FUIAuth.defaultAuthUI()
                
            // Check that it isn't nil
            guard authUI != nil else {
                return
            }
            
            // Set delegate and specify sign in options
            authUI?.delegate = self
            authUI?.providers = [FUIEmailAuth(), FUIGoogleAuth()]
            
            // Get the auth view controller and present it
            let authViewController = authUI!.authViewController()
            
            //                let backItem = UIBarButtonItem()
            //                backItem.title = "Back"
            //                self.navigationItem.backBarButtonItem = backItem
            
            self.present(authViewController, animated: true, completion: nil)
        }

    }


