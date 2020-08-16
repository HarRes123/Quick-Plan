//
//  SettingsViewController.swift
//  Planner
//
//  Created by Harrison Resnick on 8/15/20.
//  Copyright © 2020 Harrison Resnick. All rights reserved.
//

import UIKit
import GoogleSignIn
import Firebase

class SettingsViewController: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet var stackView: UIStackView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var quickPlanEmail: UITextField!
    @IBOutlet weak var classroomEmail: UITextField!
    @IBOutlet weak var signOutButton: UIButton!
    @IBOutlet weak var tutorialButton: UIButton!
    @IBOutlet var dismissButton: UIBarButtonItem!
    
    @IBOutlet var quickPlanLabel: UILabel!
    @IBOutlet var classroomLabel: UILabel!
    @IBOutlet var dummyView: UIView!
    
    var showTutorial = false
    
    @IBOutlet var navBar: UINavigationBar!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.addSubview(stackView)
        scrollView.delegate = self
        quickPlanEmail.text = Auth.auth().currentUser?.email ?? "Email"
        
        if let classroomEmailText = GIDSignIn.sharedInstance()?.currentUser?.profile.email {
            classroomEmail.text = classroomEmailText
        } else {
            classroomEmail.text = "No Classroom Account"
        }
        
        navBar.titleTextAttributes = [NSAttributedString.Key.font: UIFont(name: "AvenirNext-Regular", size: 18)!]
        navBar.shadowImage = UIImage()
        
        UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedString.Key.font: UIFont(name: "AvenirNext-Regular", size: 17)!], for: .normal)

        stackView.setCustomSpacing(35, after: dummyView)
        stackView.setCustomSpacing(12, after: quickPlanLabel)
        stackView.setCustomSpacing(64, after: quickPlanEmail)
        stackView.setCustomSpacing(12, after: classroomLabel)
        stackView.setCustomSpacing(64, after: classroomEmail)
        stackView.setCustomSpacing(25, after: tutorialButton)

    }
    
    @IBAction func signOut(_: Any) {
        let alert = UIAlertController(title: "Would You Like to Sign Out of Your Account?", message: "", preferredStyle: .alert)
        let yes = UIAlertAction(title: "Yes", style: .default) { (_: UIAlertAction) in

            self.navigationItem.title = "Planner"

            GIDSignIn.sharedInstance().signOut()

            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
  
            try! Auth.auth().signOut()
            UserDefaults.standard.set(true, forKey: "isClassroomEnabled")
            UserDefaults.standard.set(false, forKey: "hasSignedIn")
            
            let vc =  UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier:"signInVC") as! SignInViewController
            //vc.delegate = self
            vc.modalPresentationStyle = .fullScreen
            vc.modalTransitionStyle = .crossDissolve
            self.present(vc, animated: true, completion: nil)
        }

        let no = UIAlertAction(title: "No", style: .cancel) { (_: UIAlertAction) in
            alert.dismiss(animated: true, completion: nil)
        }

        alert.addAction(yes)
        alert.addAction(no)
        present(alert, animated: true)
    }
    
    override func traitCollectionDidChange(_: UITraitCollection?) {
        setUpButton(button: signOutButton, darkTint: UIColor.black.cgColor)
        setUpButton(button: tutorialButton, darkTint: UIColor.black.cgColor)
        classroomEmail.layer.borderColor = UIColor.blue.cgColor
        if traitCollection.userInterfaceStyle == .light {
            view.backgroundColor = .customGray
            dismissButton.tintColor = .darkGray
            
        } else {
            view.backgroundColor = .darkGray
            dismissButton.tintColor = .customGray
           
        }
    }

    @IBAction func dismissButton(_: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func showTutorial(_: Any) {
        if globalVariables.selectTutorial == .full {
            dismiss(animated: true, completion: nil)
            showTutorial = true
        } else {
            let alert = UIAlertController(title: "Please Import or Create at Least One Class", message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            present(alert, animated: true)
        }
       
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if isBeingDismissed, showTutorial {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "showTutorial"), object: nil)
        }
    }

    override func viewDidLayoutSubviews() {
        stackView.translatesAutoresizingMaskIntoConstraints = false

        stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
        stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true
        stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
        stackView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
        
        quickPlanEmail.bounds.size.height = 28
        classroomEmail.bounds.size.height = 28

        stackView.center.x = scrollView.center.x
        stackView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: stackView.frame.height)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.x != 0 {
            scrollView.contentOffset.x = 0
        }
    }
}
