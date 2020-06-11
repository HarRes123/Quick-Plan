//
//  ViewController.swift
//  Planner
//
//  Created by Harrison Resnick on 6/9/20.
//  Copyright © 2020 Harrison Resnick. All rights reserved.
//

import UIKit
import GoogleSignIn

class ViewController: UIViewController, GIDSignInDelegate {
    var myAuth: GTMFetcherAuthorizationProtocol? = nil
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {

            // Logged into google services successfully!
            // Save relevant details from user.authentication to refresh the token when needed.

            // Set GTMOAuth2Authentication authoriser for your Google Drive service
            GIDSignIn.sharedInstance().delegate=self
            GIDSignIn.sharedInstance().scopes = scopes
            myAuth = user.authentication.fetcherAuthorizer()
         //   myAuth = user.authentication.fetcherAuthorizer()
 
        
        
    }
    
    private let scopes = [OIDScopeEmail, OIDScopeProfile, OIDScopeOpenID, "https://www.googleapis.com/auth/classroom.student-submissions.students.readonly", "https://www.googleapis.com/auth/classroom.courses.readonly", "https://www.googleapis.com/auth/classroom.rosters.readonly", "https://www.googleapis.com/auth/classroom.student-submissions.me.readonly", "https://www.googleapis.com/auth/classroom.coursework.me"]

    
    private let service = GTLRClassroomService()
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        myAuth = nil
    }
 

    func fetchCourses() {
        
        
        GIDSignIn.sharedInstance().delegate=self
        GIDSignIn.sharedInstance().scopes = scopes

        print("Getting classes...")

        let query = GTLRClassroomQuery_CoursesList.query()

        query.pageSize = 30

        service.executeQuery(query,

                             delegate: self,
                             didFinish: #selector(displayResultWithTicket(ticket:finishedWithObject:error:)))

    }

    @objc func displayResultWithTicket(ticket: GTLRServiceTicket,

                                 finishedWithObject result : GTLRClassroom_ListCoursesResponse,

                                 error : NSError?) {

        if let error = error {

            // showAlert(title: "Error", message: error.localizedDescription)
            print(error.localizedDescription)

            return

        }

    
        guard let courses = result.courses, !courses.isEmpty else {

            print("No courses.")

            return

        }

        var outputText = "Courses:\n"

        for course in courses {

            // The API field "id" is renamed "identifier" in this library.

            outputText += "\(course.name ?? "") (\(course.identifier!))\n"

        }

        print(outputText)

    }

  override func viewDidLoad() {
    super.viewDidLoad()

    GIDSignIn.sharedInstance()?.presentingViewController = self

    // Automatically sign in the user.
    //GIDSignIn.sharedInstance()?.restorePreviousSignIn()
    
    GIDSignIn.sharedInstance().scopes = scopes
    
    service.authorizer = myAuth
    // [END_EXCLUDE]
  }
    
    

    @IBAction func signOut(_ sender: Any) {
        GIDSignIn.sharedInstance().signOut()
        GIDSignIn.sharedInstance().disconnect()
        service.authorizer = myAuth
    }
    @IBAction func signIn(_ sender: Any) {
        GIDSignIn.sharedInstance().signIn()
        service.authorizer = myAuth
    }
    
    @IBAction func getClasses(_ sender: Any) {

        if GIDSignIn.sharedInstance()?.currentUser != nil {
            
            myAuth = GIDSignIn.sharedInstance()?.currentUser.authentication.fetcherAuthorizer()
        } else {
            myAuth = nil
        }
        service.authorizer = myAuth
        fetchCourses()
        
    }
    
}


