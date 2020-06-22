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
import Firebase

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
    
    var assignmentAndDueDate = [String : String]()
    
    var daysFromToday = 0
    
    let date = Date()
    var calendar = Calendar.current
                
    @IBOutlet weak var calendarTableView: UITableView!
    @IBOutlet weak var assignmentTableView: UITableView!
    
    lazy var refreshController = UIRefreshControl()
    
    private let scopes = [OIDScopeEmail, OIDScopeProfile, OIDScopeOpenID,kGTLRAuthScopeClassroomStudentSubmissionsStudentsReadonly, kGTLRAuthScopeClassroomCoursesReadonly, kGTLRAuthScopeClassroomCourseworkMe]
        
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        
        // if the table view in question is the left table view then read from leftItems, otherwise read from rightItems
        let assignment = classNameAndAssignments[classes[indexPath.section]]?[indexPath.row] ?? ""
        let dueDate = assignmentAndDueDate[assignment] ?? ""
        let string = tableView == assignmentTableView ? "\(assignment)\n\n\(dueDate)" : calendarItems[indexPath.row]
        
        // Attempt to convert the string to a Data object so it can be passed around using drag and drop
        guard let data = string.data(using: .utf8) else { return [] }
        
        // Place that data inside an NSItemProvider, marking it as containing a plain text string so other apps know what to do with it
        let itemProvider = NSItemProvider(item: data as NSData, typeIdentifier: kUTTypePlainText as String)
        
        // place that item provider inside a UIDragItem so that it can be used for drag and drop by UIKit
        return [UIDragItem(itemProvider: itemProvider)]
    }
    
    func isKeyPresentInUserDefaults(key: String) -> Bool {
        return UserDefaults.standard.object(forKey: key) != nil
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
            let defaults = UserDefaults.standard
            defaults.set(self.calendarItems, forKey: self.getViewedDate())
            self.assignmentTableView.reloadData()
            
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
        //print("test")
        return showAllClassInfo(assignmentTableView, cellForRowAt: indexPath)
        
    }
    
    var classButtonTitle = "Import Classes"
   
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        
        if tableView == assignmentTableView {
        
            classes = Array<String>(classNameAndAssignments.keys)
            let button = UIButton(type: .custom)
            
            button.setTitleColor(.black, for: .normal)
            button.setTitleColor(.gray, for: .selected)
            button.titleLabel?.lineBreakMode = .byWordWrapping
            button.titleLabel?.textAlignment = .center

            button.tag = section
       //     print("test")
            
            if classNameAndAssignments.count > 0 {
                if section == 0 {
                    button.setTitle("\n\n" + classes[section] + "\n", for: .normal)
                } else {
                    button.setTitle("\n" + classes[section] + "\n", for: .normal)
                }
                button.addTarget(self, action: #selector(tapSection(sender:)), for: .touchUpInside)

              //  button.removeTarget(self, action: #selector(tapImport(sender:)), for: .touchUpInside)
                
            } else {
                
                
                button.addTarget(self, action: #selector(tapImport(sender:)), for: .touchUpInside)
                button.setTitle(classButtonTitle, for: .normal)

               
              //  button.removeTarget(self, action: #selector(tapSection(sender:)), for: .touchUpInside)
                
                              
            }
            
          
            button.setTitleColor(.black, for: .normal)
            button.setTitleColor(.lightGray, for: .selected)
            button.titleLabel?.lineBreakMode = .byWordWrapping
            button.titleLabel?.textAlignment = .center
             //assignmentTableView.reloadData()
           
    //        return button
            return button
        } else {
           // return nil
            if section == 0 {
            
                let currentDate = getViewedDate()
                
                let view = UIView(frame: .zero)
                view.backgroundColor = UIColor(hexFromString: "E8E8E8") //tableView.backgroundColor
                let labelWidth = 110
                let labelX = Int(tableView.frame.size.width)/2
                let label = UIButton(frame: CGRect(x: labelX - labelWidth/2, y: 5, width: labelWidth, height: 40))
                let leftButton = UIButton(type: .custom)
                let rightButton = UIButton(type: .custom)
                leftButton.frame = CGRect(x: labelX - 15 - 75, y: 5, width: 30, height: 40)
                rightButton.frame = CGRect(x: labelX - 15 + 75  , y: 5, width: 30, height: 40)
                label.setTitle(currentDate, for: .normal)
                label.setTitleColor(.black, for: .normal)
                label.setTitleColor(.gray, for: .selected)
                leftButton.setImage(UIImage(named: "backwards"), for: .normal)

                leftButton.setTitleColor(.black, for: .normal)
                leftButton.setTitleColor(.gray, for: .selected)
               // rightButton.setTitle(">", for: .normal)
                rightButton.setImage(UIImage(named: "fowards"), for: .normal)
                rightButton.setTitleColor(.gray, for: .selected)
                rightButton.setTitleColor(.black, for: .normal)
                
                leftButton.addTarget(self, action: #selector(backDay(sender:)), for: .touchUpInside)
                rightButton.addTarget(self, action: #selector(aheadDay(sender:)), for: .touchUpInside)
                label.addTarget(self, action: #selector(pressedOnDate(sender:)), for: .touchUpInside)
              //   self.calendarTableView.addGestureRecognizer(lpgr)
                
                view.sizeToFit()
                view.addSubview(label)
                view.addSubview(leftButton)
                view.addSubview(rightButton)
                return view
            } else {
                return nil
            }
            
        }
    }
    
    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {

        if session.localDragSession != nil { // Drag originated from the same app.
            return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        }

        return UITableViewDropProposal(operation: .cancel, intent: .unspecified)
    }
    
    func getViewedDate() -> String {
        
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        return formatter.string(from: date.getDate(dayDifference: daysFromToday))
        
        
    }
    
    @objc func backDay(sender: UIButton) {
        
        daysFromToday -= 1
        setUpCalendar()
        calendarTableView.reloadData()
        assignmentTableView.reloadData()
        
    }
    
    @objc func aheadDay(sender: UIButton) {
        
        daysFromToday += 1
        setUpCalendar()
        calendarTableView.reloadData()
        assignmentTableView.reloadData()
        
    }

    
    @objc func tapImport(sender: UIButton) {

        
        if GIDSignIn.sharedInstance()?.currentUser == nil {
            print("YESYES")
            if sender.title(for: .normal) == "Show Classes" {
                print("yes")
                let alert = UIAlertController(title: "Unable to Show Classes", message: "Please sign in", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Sign In", style: .default, handler: { action in
                    //run your function here
                    GIDSignIn.sharedInstance().signIn()
                }))
                self.present(alert, animated: true)
            } else {
                GIDSignIn.sharedInstance().signIn()
                sender.setTitle("Show Classes", for: .normal)
                
                
            }
            classButtonTitle = "Show Classes"
        } else {
            print("NONO")
            getInfo()
            classButtonTitle = ""

        }
     //   assignmentTableView.reloadData()
         service.authorizer = myAuth
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
        cell.backgroundColor = .white
        
        if classNameAndAssignments.count > 0 {

            if cell.classAssignments.text == "Assignments" {
                cell.classAssignments.text = ""
            } else {
               // cell.classTitle.text = classes[indexPath.row]
//                let assignments = classNameAndAssignments[classes[indexPath.row]]?.joined(separator: "; ") // "1-2-3"
  //              cell.classAssignments.text = assignments//
                if indexPath.row < classNameAndAssignments[classes[indexPath.section]]!.count {
                    let cellText = classNameAndAssignments[classes[indexPath.section]]?[indexPath.row] ?? ""
                    
                    let dueDate = assignmentAndDueDate[cellText] ?? ""
                    cell.classAssignments.text = "\(cellText)\n\n\(dueDate)"
                   // print(dueDate)
    //                    for assignment in 0...classNameAndAssignments[classes[indexPath.section]]!.count-1 {
    //    //
    //                        cell.classAssignments.text! += classNameAndAssignments[classes[indexPath.section]]?[assignment] ?? "No assignment"
                }
//
//                    }
            }
            
            if calendarItems.contains(cell.classAssignments.text) {
                
                cell.classAssignments.textColor = .lightGray
            } else {
                cell.classAssignments.textColor = .black
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
            var fixedTime = ""
            
            if calendarItems[indexPath.row].first == "0" {
                fixedTime = String(calendarItems[indexPath.row].dropFirst())
            } else {
                fixedTime = calendarItems[indexPath.row]
            }
            
            cell.calendarEventText.text = fixedTime

            if checkTimeIsValid(from: cell.calendarEventText.text) {
                
                cell.backgroundColor = UIColor(hexFromString: "f5bc49")
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
    
  func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {return}
    
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
    
    func setUpCalendar() {
        
        if isKeyPresentInUserDefaults(key: getViewedDate()) {
            let defaults = UserDefaults.standard
            calendarItems = defaults.stringArray(forKey: getViewedDate()) ?? [String]()
        } else {
        
            let lastTime: Double = 23
            var currentTime: Double = 0
            let incrementMinutes: Double = 30 // increment by 15 minutes
            calendarItems = []
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
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }

    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    
 
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
            let movedObject = self.calendarItems[sourceIndexPath.row]
            calendarItems.remove(at: sourceIndexPath.row)
            calendarItems.insert(movedObject, at: destinationIndexPath.row)
            let defaults = UserDefaults.standard
            defaults.set(self.calendarItems, forKey: self.getViewedDate())
            self.assignmentTableView.reloadData()
        
    }
    
    @objc func pressedOnDate(sender: UIButton) {
        
        if calendarTableView.isEditing == false {
            calendarTableView.isEditing = true
        } else {
            calendarTableView.isEditing = false
        }
    
    }
    
    override func viewDidLoad() {
      super.viewDidLoad()
        
        setUpCalendar()
        GIDSignIn.sharedInstance()?.signOut()

        configureRefreshControl()
        self.navigationItem.title = Auth.auth().currentUser?.displayName

        GIDSignIn.sharedInstance()?.presentingViewController = self
        GIDSignIn.sharedInstance().scopes = scopes
        
        
        assignmentTableView.delegate = self
        assignmentTableView.dataSource = self
        
        calendarTableView.delegate = self
        calendarTableView.dataSource = self
        
        calendarTableView.backgroundColor = UIColor(hexFromString: "E8E8E8")
        assignmentTableView.backgroundColor = UIColor(hexFromString: "5FD7EC")
        
        assignmentTableView.estimatedRowHeight = 250.0 // Replace with your actual estimation
        // Automatic dimensions to tell the table view to use dynamic height
        assignmentTableView.rowHeight = UITableView.automaticDimension
        
        calendarTableView.estimatedRowHeight = 250.0 // Replace with your actual estimation
        // Automatic dimensions to tell the table view to use dynamic height
        calendarTableView.rowHeight = UITableView.automaticDimension

        assignmentTableView.dragDelegate = self
        calendarTableView.dropDelegate = self
        assignmentTableView.dragInteractionEnabled = true
       // calendarTableView.dragInteractionEnabled = true
        
      //  self.assignmentTableView.register(AssignmentTableViewCell.self, forCellReuseIdentifier: "assignmentCell")
        let nibClassroom = UINib.init(nibName: "AssignmentTableViewCell", bundle: nil)
        self.assignmentTableView.register(nibClassroom, forCellReuseIdentifier: "assignmentCell")
        
        let nibCalendar = UINib.init(nibName: "CalendarTableViewCell", bundle: nil)
        self.calendarTableView.register(nibCalendar, forCellReuseIdentifier: "calendarCell")
        
        service.authorizer = myAuth
        
        setUpUI(view: assignmentTableView)
        setUpUI(view: calendarTableView)
        
        self.navigationController?.navigationBar.transparentNavigationBar()
        self.view.backgroundColor = UIColor(hexFromString: "9eb5e8")
//        self.navigationController?.navigationBar.layer.shadowColor = UIColor.darkGray.cgColor
//        self.navigationController?.navigationBar.layer.shadowOffset = CGSize(width: 0, height: 3)
//        self.navigationController?.navigationBar.layer.shadowRadius = 1.5
//        self.navigationController?.navigationBar.layer.shadowOpacity = 1.0
//        self.navigationController?.navigationBar.layer.masksToBounds = false

    }
    
    func setUpUI(view: UIView) {
        
        let containerView:UIView = UIView(frame: view.frame)
        containerView.backgroundColor = UIColor.clear
        containerView.layer.shadowColor = UIColor.darkGray.cgColor
        containerView.layer.shadowOffset = CGSize(width: -3, height: 3)
        containerView.layer.shadowOpacity = 1.0
        containerView.layer.shadowRadius = 1.5
        
        view.layer.borderColor = UIColor.darkGray.cgColor
        view.layer.borderWidth = 2

        view.layer.cornerRadius = 15
        view.layer.masksToBounds = true
        self.view.addSubview(containerView)
        containerView.addSubview(view)
        
    }
    
    func configureRefreshControl () {
        self.assignmentTableView.refreshControl = UIRefreshControl()
        self.assignmentTableView.refreshControl?.addTarget(self, action:
            #selector(handleRefreshControl), for: .valueChanged)
    }
    
    @objc func handleRefreshControl() {
        
        if assignmentsPerCourse.count > 0 {
            self.showInfo()
        }
        self.assignmentTableView.reloadData()

        DispatchQueue.main.async {
            self.assignmentTableView.refreshControl?.endRefreshing()
        }
    }
        
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
        

        let query = GTLRClassroomQuery_CoursesList.query()
        query.pageSize = 100
        query.executionParameters.shouldFetchNextPages = true
        service.executeQuery(query,
                             delegate: self,
                             didFinish: #selector(obtainClassIds(ticket:finishedWithObject:error:)))

    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {

        let deleteAction = UITableViewRowAction(style: .default, title: "Delete", handler: { (action, indexPath) in
            print("Delete tapped")
            self.calendarItems.remove(at: indexPath.row)
            //         self.tableView.deleteRows(at: [indexPath], with: .automatic)
                     tableView.deleteRows(at: [indexPath], with: .automatic)
        })
        deleteAction.backgroundColor = UIColor.red

        return [deleteAction]
    }
    
    func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        
        let defaults = UserDefaults.standard
        defaults.set(self.calendarItems, forKey: self.getViewedDate())
        self.assignmentTableView.reloadData()
    }
    

    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if tableView == calendarTableView {
            if checkTimeIsValid(from: calendarItems[indexPath.row]) {
                return false
            } else {
                return true
            }
        }
        return false
    }

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if tableView == assignmentTableView {
        
//            let indexPath = tableView.indexPathForSelectedRow
//
//            let currentCell = tableView.cellForRow(at: indexPath!)! as! AssignmentTableViewCell

        }
    }
    
    
    func fetchAssignments() {
        print("FETCH")
        
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
        
        let alert = UIAlertController(title: "Information Fetched", message: "Dismiss to view classes", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: { action in
            //run your function here
            self.showInfo()
        }))
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
                let dueMonth = assignment.dueDate?.month as? Int ?? 0
                let dueDay = assignment.dueDate?.day as? Int ?? 0
                let dueYear = assignment.dueDate?.year as? Int ?? 0
                
                var finalDate = "\(dueMonth)/\(dueDay)/\(dueYear)"
                
                if finalDate == "0/0/0" {
                    finalDate = "No Due Date"
                }
                
                assignmentAndDueDate.updateValue("Due: \(finalDate)", forKey: assignment.title ?? "no title")
//
                
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
    
    func resetDefaults() {
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            defaults.removeObject(forKey: key)
        }
        setUpCalendar()
        self.calendarTableView.reloadData()
    }
  
    @IBAction func signOut(_ sender: Any) {
        
       let alert = UIAlertController(title: "Would You Like to Sign Out of Your Account?", message: "", preferredStyle: .alert)
       let yes = UIAlertAction(title: "Yes", style: .default) { (action:UIAlertAction) in
           
           
            self.assignmentsPerCourse = [Array<String>]()
            self.assignmentIndex = 0
            self.classIDAndName = [String:String]()
            self.classNameAndAssignments = [String: Array<String>]()

            // resetDefaults()
            self.navigationItem.title = "Planner"

            GIDSignIn.sharedInstance().signOut()
            GIDSignIn.sharedInstance().disconnect()
            self.service.authorizer = self.myAuth


            self.assignmentTableView.reloadData()
            try! Auth.auth().signOut()
            self.performSegue(withIdentifier: "logOut", sender: self)
       }
       
       let no = UIAlertAction(title: "No", style: .cancel) { (action:UIAlertAction) in
           alert.dismiss(animated: true, completion: nil)
       }
       alert.addAction(yes)
       alert.addAction(no)
       self.present(alert, animated: true)
        
    
    }
    
    func getInfo() {
        
        if GIDSignIn.sharedInstance()?.currentUser != nil {
            
            myAuth = GIDSignIn.sharedInstance()?.currentUser.authentication.fetcherAuthorizer()
        } else {
            myAuth = nil
        }
        service.authorizer = myAuth
        fetchCourses()
               
        
    }
    
    func showInfo() {
    
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
