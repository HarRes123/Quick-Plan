//
//  ViewController.swift
//  Planner
//
//  Created by Harrison Resnick on 6/9/20.
//  Copyright © 2020 Harrison Resnick. All rights reserved.
//

import UIKit
import GoogleSignIn
import MobileCoreServices

class ViewController: UIViewController, GIDSignInDelegate, UITableViewDelegate, UITableViewDataSource, UITableViewDragDelegate, UITableViewDropDelegate  {
    
    var myAuth: GTMFetcherAuthorizationProtocol? = nil
    private let service = GTLRClassroomService()
    
    var assignmentsPerCourse = [Array<String>]()
    var assignmentIndex = 0
    
    var classIDAndName = [String : String]()
    var classNameAndAssignments = [String : Array<String>]()
    
    var classes = Array<String>()
    var arrayHeader = [Int]()
    
    var calendarItems = [String]()
    
    let date = Date()
    var calendar = Calendar.current
                
    @IBOutlet weak var calendarTableView: UITableView!
    @IBOutlet weak var assignmentTableView: UITableView!
    
    lazy var refreshController = UIRefreshControl()
    
    private let scopes = [OIDScopeEmail, OIDScopeProfile, OIDScopeOpenID,kGTLRAuthScopeClassroomStudentSubmissionsStudentsReadonly, kGTLRAuthScopeClassroomCoursesReadonly, kGTLRAuthScopeClassroomRostersReadonly, kGTLRAuthScopeClassroomCourseworkMe]
        
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        
        // if the table view in question is the left table view then read from leftItems, otherwise read from rightItems
        let string = tableView == assignmentTableView ? classNameAndAssignments[classes[indexPath.section]]?[indexPath.row] : calendarItems[indexPath.row]
        
        // Attempt to convert the string to a Data object so it can be passed around using drag and drop
        guard let data = string?.data(using: .utf8) else { return [] }
        
        // Place that data inside an NSItemProvider, marking it as containing a plain text string so other apps know what to do with it
        let itemProvider = NSItemProvider(item: data as NSData, typeIdentifier: kUTTypePlainText as String)
        
        // place that item provider inside a UIDragItem so that it can be used for drag and drop by UIKit
        return [UIDragItem(itemProvider: itemProvider)]
    }
    
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        let destinationIndexPath: IndexPath
        
        if let indexPath = coordinator.destinationIndexPath {
            destinationIndexPath = indexPath
        } else {
            let section = tableView.numberOfSections - 1
            let row = tableView.numberOfRows(inSection: section)
            destinationIndexPath = IndexPath(row: row, section: section)
        }
        
        // attempt to load strings from the drop coordinator
        coordinator.session.loadObjects(ofClass: NSString.self) { items in
            // convert the item provider array to a string array or bail out
            guard let strings = items as? [String] else { return }
            
            // create an empty array to track rows we've copied
            var indexPaths = [IndexPath]()
            
            // loop over all the strings we received
            for (index, string) in strings.enumerated() {
                // create an index path for this new row, moving it down depending on how many we've already inserted
                let indexPath = IndexPath(row: destinationIndexPath.row + index, section: destinationIndexPath.section)
    
                self.calendarItems.insert(string, at: indexPath.row)
                indexPaths.append(indexPath)
                tableView.insertRows(at: indexPaths, with: .automatic)
                
                
                // keep track of this new row
                //indexPaths.append(indexPath)
            }
            
            // insert them all into the table view at once
            
//            tableView.insertRows(at: indexPaths, with: .automatic)
        }
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if tableView == assignmentTableView {
        
            classes = Array<String>(classNameAndAssignments.keys)
            if classNameAndAssignments.count > 0 {
                //return classNameAndAssignments[classes[section]]?.count ?? 1
                return (self.arrayHeader[section] == 0) ? 0 : classNameAndAssignments[classes[section]]?.count ?? 1
            } else {
                return 0
            }
        } else {
            return calendarItems.count
        }

    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        if tableView == assignmentTableView {
            var numberOfSections = Int()
            if classNameAndAssignments.count > 0 {
                numberOfSections = classNameAndAssignments.count
            } else {
                numberOfSections = 1
            }
            return numberOfSections
        } else {
            return 1
        }
    }
    
    func scrollViewWillBeginDragging(cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("test")
        return showAllClassInfo(assignmentTableView, cellForRowAt: indexPath)
        
    }
    
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if tableView == assignmentTableView {
        
            classes = Array<String>(classNameAndAssignments.keys)
            let button = UIButton(type: .custom)
            if classNameAndAssignments.count > 0 {
                button.setTitle("\n" + classes[section] + "\n", for: .normal)
                
            } else {
                button.setTitle("\nClass\n", for: .normal)
            }
            
          
            button.setTitleColor(.darkGray, for: .normal)
            button.setTitleColor(.lightGray, for: .selected)
            button.titleLabel?.lineBreakMode = .byWordWrapping
            button.titleLabel?.textAlignment = .center

            button.tag = section // Assign section tag to this button
            button.addTarget(self, action: #selector(tapSection(sender:)), for: .touchUpInside)
           
    //        return button
            return button
        } else {
            return nil
        }
    }
    
    @objc func tapSection(sender: UIButton) {
        if classNameAndAssignments.count > 0 {
            self.arrayHeader[sender.tag] = (self.arrayHeader[sender.tag] == 0) ? 1 : 0
            self.assignmentTableView.reloadSections([sender.tag], with: .fade)
        }
    }
    
    func tableView( _ tableView : UITableView,  titleForHeaderInSection section: Int)->String? {
        
        if tableView == calendarTableView {
            return "Calendar"

        } else {
            return nil
        }
        
    }
    

    func showAllClassInfo (_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    
        let cell = tableView.dequeueReusableCell(withIdentifier: "assignmentCell", for: indexPath) as! AssignmentTableViewCell
 
        classes = Array<String>(classNameAndAssignments.keys)
       // let assignments: Array<Array<String>> = Array<Array<String>>(classNameAndAssignments.values)
        
        
        if classNameAndAssignments.count > 0 {

            if cell.classAssignments.text == "Assignments" {
                cell.classAssignments.text = ""
            } else {
               // cell.classTitle.text = classes[indexPath.row]
//                let assignments = classNameAndAssignments[classes[indexPath.row]]?.joined(separator: "; ") // "1-2-3"
  //              cell.classAssignments.text = assignments//
                if indexPath.row < classNameAndAssignments[classes[indexPath.section]]!.count {
                    let cellText = classNameAndAssignments[classes[indexPath.section]]?[indexPath.row]
                    cell.classAssignments.text = cellText
    //                    for assignment in 0...classNameAndAssignments[classes[indexPath.section]]!.count-1 {
    //    //
    //                        cell.classAssignments.text! += classNameAndAssignments[classes[indexPath.section]]?[assignment] ?? "No assignment"
                }
//
//                    }
            }
            
                
        } else {
            cell.classAssignments.text = "Assignment"
            
        }
        
        
        
        

        return cell
    }
    
    func checkTimeIsValid(from string: String) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a"
        if (dateFormatter.date(from: string) != nil) {
            return true
        }else{
            return false
        }
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView == assignmentTableView {
            return showAllClassInfo(tableView, cellForRowAt: indexPath)
        } else {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "calendarCell", for: indexPath) as! CalendarTableViewCell
            cell.calendarEventText.text = calendarItems[indexPath.row]

            if checkTimeIsValid(from: cell.calendarEventText.text) {
                
                cell.backgroundColor = .random
                cell.isUserInteractionEnabled = false
            } else {
                cell.backgroundColor = .white
                cell.isUserInteractionEnabled = true
            }
            
            return cell
            
        }
        
    }

    
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 200
//    }
    
  func timeConversion12(time24: String) -> String {
      let dateAsString = time24
      let df = DateFormatter()
      df.dateFormat = "HH:mm"

      let date = df.date(from: dateAsString)
      df.dateFormat = "hh:mm a"

      let time12 = df.string(from: date!)
      print(time12)
      return time12
  }
    override func viewDidLoad() {
      super.viewDidLoad()
        
        
        let lastTime: Double = 23
        var currentTime: Double = 0
        let incrementMinutes: Double = 30 // increment by 15 minutes
        
        calendarItems.append("12:00 AM")

        while currentTime <= lastTime {
            currentTime += (incrementMinutes/60)
                

            let hours = Int(floor(currentTime))
            let minutes = Int(currentTime.truncatingRemainder(dividingBy: 1)*60)
            
            if minutes == 0 {
                let time24 = "\(hours):00"
                calendarItems.append(timeConversion12(time24: time24))
            } else {
                let time24 = "\(hours):\(minutes)"
                calendarItems.append(timeConversion12(time24: time24))
            }
        }
        
        configureRefreshControl()

        GIDSignIn.sharedInstance()?.presentingViewController = self
        GIDSignIn.sharedInstance().scopes = scopes
        
        assignmentTableView.delegate = self
        assignmentTableView.dataSource = self
        
        calendarTableView.delegate = self
        calendarTableView.dataSource = self
        
        assignmentTableView.estimatedRowHeight = 250.0 // Replace with your actual estimation
        // Automatic dimensions to tell the table view to use dynamic height
        assignmentTableView.rowHeight = UITableView.automaticDimension
        
        calendarTableView.estimatedRowHeight = 250.0 // Replace with your actual estimation
        // Automatic dimensions to tell the table view to use dynamic height
        calendarTableView.rowHeight = UITableView.automaticDimension

        assignmentTableView.dragDelegate = self
        calendarTableView.dropDelegate = self
        assignmentTableView.dragInteractionEnabled = true
        calendarTableView.dragInteractionEnabled = true
        
      //  self.assignmentTableView.register(AssignmentTableViewCell.self, forCellReuseIdentifier: "assignmentCell")
        let nibClassroom = UINib.init(nibName: "AssignmentTableViewCell", bundle: nil)
        self.assignmentTableView.register(nibClassroom, forCellReuseIdentifier: "assignmentCell")
        
        let nibCalendar = UINib.init(nibName: "CalendarTableViewCell", bundle: nil)
        self.calendarTableView.register(nibCalendar, forCellReuseIdentifier: "calendarCell")
        
        service.authorizer = myAuth
      
    }
    
    func configureRefreshControl () {
        self.assignmentTableView.refreshControl = UIRefreshControl()
        self.assignmentTableView.refreshControl?.addTarget(self, action:
            #selector(handleRefreshControl), for: .valueChanged)
    }
    
    @objc func handleRefreshControl() {
        
        self.assignmentTableView.reloadData()

        DispatchQueue.main.async {
            self.assignmentTableView.refreshControl?.endRefreshing()
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {return}
    
//    func dayView(dayView: DayView, didTapTimelineAt date: Date) {
//        let format = DateFormatter()
//        format.timeZone = .current
//        format.dateFormat = "MMM d, yyyy; h:mm a"
//        let dateString = format.string(from: date)
//
//        print(dateString)
//        textViewTest.text = "Selected Date: \(dateString)"
//    }
    
    
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if tableView == assignmentTableView {
        
//            let indexPath = tableView.indexPathForSelectedRow
//
//            let currentCell = tableView.cellForRow(at: indexPath!)! as! AssignmentTableViewCell

        }
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
        
        let alert = UIAlertController(title: "Information Fetched", message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: true)
        self.assignmentTableView.reloadData()
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
        arrayHeader = Array(repeating: 0, count:classIDAndName.count)
        assignmentIndex = 0
        fetchAssignments()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        if tableView == assignmentTableView {
        
            return 100
        } else {
            return 50
        }
    }

  
    @IBAction func signOut(_ sender: Any) {
        
        assignmentsPerCourse = [Array<String>]()
        assignmentIndex = 0
        classIDAndName = [String:String]()
        classNameAndAssignments = [String: Array<String>]()
        
        UserDefaults.standard.removeObject(forKey: "fullName")
        self.navigationItem.title = "Planner"
        
        GIDSignIn.sharedInstance().signOut()
        GIDSignIn.sharedInstance().disconnect()
        service.authorizer = myAuth
        
        self.assignmentTableView.reloadData()
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
        
        if assignmentsPerCourse.count != 0 {
            for i in 0...assignmentsPerCourse.count - 1 {
                if assignmentsPerCourse[i].first != nil {
                    classNameAndAssignments.updateValue(assignmentsPerCourse[i].arrayWithoutFirstElement(), forKey: assignmentsPerCourse[i].first ?? "no name")
                }
            }
        } else {
            let alert = UIAlertController(title: "Unable to Show Info", message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true)
        }
        
        assignmentTableView.reloadData()
    }
}
