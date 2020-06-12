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
    
    let date = Date()
    var calendar = Calendar.current
    
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
      
        let currentMonth = calendar.component(.month, from: date)
        let currentDay = calendar.component(.day, from: date)
        let currentYear = calendar.component(.year, from: date)
        
        for assignment in assignments {
            
            let dueMonth = assignment.dueDate?.month as? Int
            let dueDay = assignment.dueDate?.day as? Int
            let dueYear = assignment.dueDate?.year as? Int
            
            
            outputText += "Title: \(assignment.title ?? "No title")\nDue Date: \(dueMonth ?? 0)/\(dueDay ?? 0)/\(dueYear ?? 0)\n"
            
            if dueYear ?? 100 >= currentYear {
                if dueMonth ?? 100 >= currentMonth {
                    if dueDay ?? 100 >= currentDay {
                        
                        print(assignment.title ?? "no title")
                        //Append these assignments to an array --> this is what the user will be able to see
                        
                    }
                }
            }
                
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
    }

  override func viewDidLoad() {
    super.viewDidLoad()

    GIDSignIn.sharedInstance()?.presentingViewController = self
    GIDSignIn.sharedInstance().scopes = scopes
    service.authorizer = myAuth
    calendar.timeZone = TimeZone.current
    
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
