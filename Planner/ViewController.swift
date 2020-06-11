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
    private let service = GTLRClassroomService()
    var classIds = [String]()
    var classNames = [String]()
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {

            GIDSignIn.sharedInstance().delegate=self
            GIDSignIn.sharedInstance().scopes = scopes
            myAuth = user.authentication.fetcherAuthorizer()
    }
    
    private let scopes = [OIDScopeEmail, OIDScopeProfile, OIDScopeOpenID, "https://www.googleapis.com/auth/classroom.student-submissions.students.readonly", "https://www.googleapis.com/auth/classroom.courses.readonly", "https://www.googleapis.com/auth/classroom.rosters.readonly", "https://www.googleapis.com/auth/classroom.student-submissions.me.readonly", "https://www.googleapis.com/auth/classroom.coursework.me"]

    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        myAuth = nil
    }
 
    func fetchCourses() {

        let query = GTLRClassroomQuery_CoursesList.query()
        query.pageSize = 30
        query.executionParameters.shouldFetchNextPages = true
        service.executeQuery(query,
                             delegate: self,
                             didFinish: #selector(obtainClassIds(ticket:finishedWithObject:error:)))

    }
    
    func fetchAssignments() {
        
        for classID in 0...classIds.endIndex-1 {
        
            if classIds != [] {
                let query = GTLRClassroomQuery_CoursesCourseWorkList.query(withCourseId: classIds[classID])
                query.pageSize = 30
                query.executionParameters.shouldFetchNextPages = true
                service.executeQuery(query,
                                     delegate: self,
                                     didFinish: #selector(obtainClasses))
            } else {
                print("Obtain classes first")
            }
        }
        
    }
    
    @objc func obtainClasses(ticket: GTLRServiceTicket,
                                 finishedWithObject result : GTLRClassroom_ListCourseWorkResponse,
                                 error : NSError?) {
        if let error = error {
            print(error.localizedDescription)
            return
        }
        
        guard let assignments = result.courseWork, !assignments.isEmpty else {
            print("No assignments.")
            return
        }
        
        var outputText = ""
        
        for assignment in assignments {
            outputText += "\(assignment.title ?? "No title")\n"
        }
          print(outputText)
    }

    

    @objc func obtainClassIds(ticket: GTLRServiceTicket,
                                 finishedWithObject result : GTLRClassroom_ListCoursesResponse,
                                 error : NSError?) {
        if let error = error {
            print(error.localizedDescription)
            return
        }
        
        guard let courses = result.courses, !courses.isEmpty else {
            print("No courses.")
            return
        }

        var outputText = "Courses:\n"

        for course in courses {
            outputText += "\(course.name ?? "") (\(course.identifier!))\n"
            classIds.append(course.identifier!)
            classNames.append(course.name!)
        }
        print(outputText)
        print(classIds)
    }

  override func viewDidLoad() {
    super.viewDidLoad()

    GIDSignIn.sharedInstance()?.presentingViewController = self
    GIDSignIn.sharedInstance().scopes = scopes
    service.authorizer = myAuth
    
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
    
    @IBAction func getAssignments(_ sender: Any) {

        if GIDSignIn.sharedInstance()?.currentUser != nil {
            
            myAuth = GIDSignIn.sharedInstance()?.currentUser.authentication.fetcherAuthorizer()
        } else {
            myAuth = nil
        }
        service.authorizer = myAuth
        fetchAssignments()
        
    }
    
}


