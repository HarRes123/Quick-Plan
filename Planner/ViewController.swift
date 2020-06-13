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
    
    var assignmentsPerCourse = [Array<String>]()
    var assignmentIndex = 0
    
    var classIDAndName = [String : String]()
    var classNameAndAssignments = [String : Array<String>]()
    
    let date = Date()
    var calendar = Calendar.current


    private let scopes = [OIDScopeEmail, OIDScopeProfile, OIDScopeOpenID,kGTLRAuthScopeClassroomStudentSubmissionsStudentsReadonly, kGTLRAuthScopeClassroomCoursesReadonly, kGTLRAuthScopeClassroomRostersReadonly, kGTLRAuthScopeClassroomCourseworkMe]
    
    @IBOutlet weak var textViewTest: UITextView!
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {}
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        myAuth = nil
    }

 
    func fetchCourses() {
        
        let fullName = UserDefaults.standard.string(forKey: "fullName") ?? "Planner"
        self.navigationItem.title = fullName

        let query = GTLRClassroomQuery_CoursesList.query()
        query.pageSize = 100
        query.executionParameters.shouldFetchNextPages = true
        service.executeQuery(query,
                             delegate: self,
                             didFinish: #selector(obtainClassIds(ticket:finishedWithObject:error:)))

    }
    
    
    func fetchAssignments() {
        
        assignmentsPerCourse = Array(repeating: [], count:classIDAndName.count)
        
        for (key, _) in classIDAndName {
            if classIDAndName != [:] {
               // let intClassID = Int(classIDAndName[key] ?? "0")
                let query = GTLRClassroomQuery_CoursesCourseWorkList.query(withCourseId: key)
                query.pageSize = 100
                query.executionParameters.shouldFetchNextPages = true
                
                service.executeQuery(query,
                                     delegate: self,
                                     didFinish: #selector(obtainClasses))
                
                
            } else {
                print("Obtain classes first")
                break
            }
        }
        textViewTest.text = "Information fetched"
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
        
//        let currentMonth = calendar.component(.month, from: date)
//        let currentDay = calendar.component(.day, from: date)
//        let currentYear = calendar.component(.year, from: date)
        
        //  for classCount in 0...classNames.count - 1 {
         
            for assignment in assignments {
                
//                let dueMonth = assignment.dueDate?.month as? Int
//                let dueDay = assignment.dueDate?.day as? Int
//                let dueYear = assignment.dueDate?.year as? Int
                
                //outputText += "Title: \(assignment.title ?? "No title")\nDue Date: \(dueMonth ?? 0)/\(dueDay ?? 0)/\(dueYear ?? 0)\n"
                
                if assignmentsPerCourse.count != 0 {
                    if assignmentsPerCourse[assignmentIndex].count == 0 {
                        assignmentsPerCourse[assignmentIndex].append(classIDAndName[assignment.courseId ?? "0"] ?? "No name")
                    }
                }

                assignmentsPerCourse[assignmentIndex].append(assignment.title ?? "No title")

//                if dueYear ?? 100 >= currentYear {
//                    if dueMonth ?? 100 >= currentMonth {
//                        if dueDay ?? 100 >= currentDay {
//
//                          //  print(assignment.title ?? "no title")
//                            //Append these assignments to an array --> this is what the user will be able to see
//
//                        }
//                    }
//                    //       }
//
//
//            }
            //    print(assignmentsPerCourse)
           // break
        }
        assignmentIndex += 1

        //print(outputText)
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
            classIDAndName.updateValue(course.name ?? "no name", forKey: course.identifier ?? "00000")
        }
    //    print(outputText)
        textViewTest.text = outputText
        fetchAssignments()
    }

  override func viewDidLoad() {
    super.viewDidLoad()

    GIDSignIn.sharedInstance()?.presentingViewController = self
    GIDSignIn.sharedInstance().scopes = scopes
    service.authorizer = myAuth
    calendar.timeZone = TimeZone.current
    
  }
  
    @IBAction func signOut(_ sender: Any) {
        
        assignmentsPerCourse = [Array<String>]()
        assignmentIndex = 0
        classIDAndName = [String:String]()
        classNameAndAssignments = [String: Array<String>]()
        textViewTest.text = ""
        
        UserDefaults.standard.removeObject(forKey: "fullName")
        self.navigationItem.title = "Planner"
        
        GIDSignIn.sharedInstance().signOut()
        GIDSignIn.sharedInstance().disconnect()
        service.authorizer = myAuth
    }
    @IBAction func signIn(_ sender: Any) {
        GIDSignIn.sharedInstance().signIn()
        service.authorizer = myAuth
    }
    
    @IBAction func getInfo(_ sender: Any) {

        if GIDSignIn.sharedInstance()?.currentUser != nil {
            
            myAuth = GIDSignIn.sharedInstance()?.currentUser.authentication.fetcherAuthorizer()
        } else {
            myAuth = nil
        }
        service.authorizer = myAuth
        fetchCourses()
        
    }
    
    @IBAction func showInfo(_ sender: Any) {
        assignmentIndex = 0
        textViewTest.text = ""
        if assignmentsPerCourse.count != 0 {
            for i in 0...assignmentsPerCourse.count - 1 {
                classNameAndAssignments.updateValue(assignmentsPerCourse[i].arrayWithoutFirstElement(), forKey: assignmentsPerCourse[i].first ?? "no name")
    
            }
            for (key, value) in classNameAndAssignments {
                textViewTest.text += "\(key):\n\(value)\n\n"
            }
        } else {
            textViewTest.text = "Unable to show info"
        }
    }
    
        
    
    
//    private func addToolbar(_ toolbar: UIToolbar, toView view: UIView) {
//        toolbar.frame = CGRect(x: 0,
//                               y: 0,
//                               width: view.frame.size.width,
//                               height: 0)
//        toolbar.sizeToFit() // This sets the standard height for the toolbar.
//
//        // Create a view to contain the toolbar:
//        let toolbarParent = UIView()
//        toolbarParent.frame = CGRect(x: 0,
//                                     y: view.frame.size.height - toolbar.frame.size.height,
//                                     width: toolbar.frame.size.width,
//                                     height: toolbar.frame.size.height)
//
//        // Adjust the position and height of the toolbar's parent view to account for safe area:
//        if #available(iOS 11, *) {
//            toolbarParent.frame.origin.y -= view.safeAreaInsets.bottom
//            toolbarParent.frame.size.height += view.safeAreaInsets.bottom
//        }
//
//
//        toolbarParent.addSubview(toolbar)
//        view.addSubview(toolbarParent)
//    }
    
}
