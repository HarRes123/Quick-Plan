//
//  ViewController.swift
//  Planner
//
//  Created by Harrison Resnick on 6/9/20.
//  Copyright © 2020 Harrison Resnick. All rights reserved.
//

import BetterSegmentedControl
import Firebase
import GoogleSignIn
import Instructions
import MobileCoreServices
import UIKit
import UserNotifications

class ViewController: UIViewController, GIDSignInDelegate, UITableViewDelegate, UITableViewDataSource, UITableViewDragDelegate, UITableViewDropDelegate, CoachMarksControllerDataSource, CoachMarksControllerDelegate {

    let coachMarksController = CoachMarksController()

    var myAuth: GTMFetcherAuthorizationProtocol?
    private let service = GTLRClassroomService()

    var assignmentsPerCourse = [[String]]()
    var newAssignmentsPerCourse = [[String]]()
    var assignmentIndex = 0

    var classIDAndNameClassroom = [String: String]()
    var classNameAndAssignments = [String: [String]]()
    var newClassNameAndAssignments = [String: [String]]()

    var classes = [String]()
    var arrayHeader = [Int]()

    var isClassroomEnabled = true

    let calVC = FullCalendarViewController(nibName: "FullCalendarViewController", bundle: nil)

    var calendarItems = [String]()

    var reminderTime = String()

    var notificationDay = String()

    var assignmentCellWidth = CGFloat()

    var refResponse: DatabaseReference!

    let center = UNUserNotificationCenter.current()

    var loadCalendar = true

    var importButtonText = "Loading..."

    var hasSignedIn = false

    var assignmentAndDueDate = [String: String]()

    var calView = UIView(frame: .zero)
    var dateButton = UIButton()
    var assignmentButton = UIButton(type: .custom)

    @IBOutlet var manualEntryButton: UIBarButtonItem!
    @IBOutlet var toggleView: BetterSegmentedControl!

    let enabledImageView = UIImageView(image: UIImage(named: "classroom")!)
    let disabledImageView = UIImageView(image: UIImage(named: "classroom_disabled")!)

    let date = Date()
    var calendar = Calendar.current

    @IBOutlet var calendarTableView: UITableView!
    @IBOutlet var assignmentTableView: UITableView!

    private let scopes = [kGTLRAuthScopeClassroomCourseworkMeReadonly, kGTLRAuthScopeClassroomCoursesReadonly]

    func tableView(_ tableView: UITableView, itemsForBeginning _: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        // if the table view in question is the left table view then read from leftItems, otherwise read from rightItems
        var assignment = ""
        var dueDate = ""

        if tableView == assignmentTableView {
            if arrayHeader[indexPath.section] == 1 {
                assignment = newClassNameAndAssignments[classes[indexPath.section]]?[indexPath.row] ?? ""
            } else if arrayHeader[indexPath.section] == 2 {
                assignment = classNameAndAssignments[classes[indexPath.section]]?[indexPath.row] ?? ""
            }

            dueDate = assignmentAndDueDate[assignment] ?? ""
        }
        var string = String()

        string = tableView == assignmentTableView ? "\(assignment)\n\n\(dueDate)" : calendarItems[indexPath.row]

        // Attempt to convert the string to a Data object so it can be passed around using drag and drop
        guard let data = string.data(using: .utf8) else { return [] }

        // Place that data inside an NSItemProvider, marking it as containing a plain text string so other apps know what to do with it
        let itemProvider = NSItemProvider(item: data as NSData, typeIdentifier: kUTTypePlainText as String)

        // place that item provider inside a UIDragItem so that it can be used for drag and drop by UIKit
        return [UIDragItem(itemProvider: itemProvider)]
    }

    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        let destinationIndexPath: IndexPath
        print("CALLED")
        if let indexPath = coordinator.destinationIndexPath {
            destinationIndexPath = indexPath
        } else {
            let section = tableView.numberOfSections - 1
            let row = tableView.numberOfRows(inSection: section)
            destinationIndexPath = IndexPath(row: row, section: section)
        }

        // attempt to load strings from the drop coordinator
        coordinator.session.loadObjects(ofClass: NSString.self) { [self] items in
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

                print("DATE: \(self.notificationDay)")
                self.getReminderTime(indexPath: indexPath)

                let nameAndDueDate = string.components(separatedBy: "\n\nDue: ")
                let dateFormatter = DateFormatter()
                dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                dateFormatter.timeZone = .current
                if self.is12Hours() {
                    dateFormatter.dateFormat = "MMM dd, yyyy hh:mm a"
                } else {
                    dateFormatter.dateFormat = "MMM dd, yyyy HH:mm"
                }
                let notifcationDate = "\(self.notificationDay) \(self.reminderTime)"

                let identifier = "\(nameAndDueDate[0])\(nameAndDueDate[1])\(notifcationDate)"

                self.setUpNotificationsFirebase(identifer: identifier)

                // keep track of this new row
                // indexPaths.append(indexPath)
            }

            // insert them all into the table view at once

            self.addResponse()
            self.calendarTableView.reloadData()
            self.assignmentTableView.reloadData()

            //            tableView.insertRows(at: indexPaths, with: .automatic)
        }
    }

    func getReminderTime(indexPath: IndexPath) {
        for i in 0 ... 30 {
            if checkTimeIsValid(from: calendarItems[indexPath.row - i]) {
                print("TIME: \(calendarItems[indexPath.row - i])")
                reminderTime = calendarItems[indexPath.row - i]
                break
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == assignmentTableView {
            classes = [String](classNameAndAssignments.keys)
            if arrayHeader.count > 0 {
                // return classNameAndAssignments[classes[section]]?.count ?? 1
                if arrayHeader[section] == 0 {
                    return 0
                } else if arrayHeader[section] == 1 {
                    return newClassNameAndAssignments[classes[section]]?.count ?? 1
                } else {
                    return classNameAndAssignments[classes[section]]?.count ?? 1
                }
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
        // print("test")
        return showAllClassInfo(assignmentTableView, cellForRowAt: indexPath)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if tableView == assignmentTableView {
            // assignmentButton = UIButton(type: .custom)
            classes = [String](classNameAndAssignments.keys)
            let button = UIButton(type: .custom)
            button.setTitleColor(.black, for: .normal)
            button.titleLabel?.lineBreakMode = .byWordWrapping
            button.titleLabel?.textAlignment = .center
            button.titleLabel?.font = UIFont(name: "AvenirNext-Regular", size: (button.titleLabel?.font.pointSize)!)
            button.tag = section

            //     print("test")

            if classNameAndAssignments.count > 0 {
                button.setTitle(classes[section], for: .normal)
                button.addTarget(self, action: #selector(tapSection(sender:)), for: .touchUpInside)

            } else {
                button.setTitle(importButtonText, for: .normal)
                button.addTarget(self, action: #selector(importClasses(sender:)), for: .touchUpInside)
            }

            // button.setTitleColor(.lightGray, for: .selected)
            button.titleLabel?.lineBreakMode = .byWordWrapping
            button.titleLabel?.textAlignment = .center
            // assignmentTableView.reloadData()

            if section == 0 {
                assignmentButton = button
            }

            return button
        } else {
            // return nil
            if section == 0 {
                calView = UIView(frame: .zero)
                notificationDay = getViewedDate()

                let buttonWidth = 110
                let buttonX = Int(tableView.frame.size.width) / 2
                //  var button = UIButton()
                let leftButton = UIButton(type: .custom)
                let rightButton = UIButton(type: .custom)
                // button.center = view.center
                leftButton.frame = CGRect(x: 5, y: 5, width: 30, height: 65)
                rightButton.frame = CGRect(x: tableView.frame.width - 35, y: 5, width: 30, height: 65)
                calendarTableView.backgroundColor = .customGray
                calView.backgroundColor = .customGray
                dateButton = UIButton(frame: CGRect(x: buttonX - buttonWidth / 2, y: 5, width: buttonWidth, height: 65))
                dateButton.titleLabel?.adjustsFontSizeToFitWidth = true
                if !loadCalendar {
                    dateButton.setTitle(notificationDay, for: .normal)
                    dateButton.addTarget(self, action: #selector(pressedOnDate(sender:)), for: .touchUpInside)
                    // label.removeTarget(self, action: #selector(loadCal(sender:)), for: .touchUpInside)
                    assignmentTableView.dragInteractionEnabled = true
                    calendarTableView.separatorStyle = .singleLine
                    calView.addSubview(leftButton)
                    calView.addSubview(rightButton)
                } else {
                    dateButton.setTitle("Loading...", for: .normal)
                    calendarTableView.separatorStyle = .none
                    assignmentTableView.dragInteractionEnabled = false
                }

                dateButton.setTitleColor(.black, for: .normal)
                dateButton.setTitleColor(.gray, for: .selected)
                dateButton.titleLabel?.font = UIFont(name: "AvenirNext-Regular", size: (dateButton.titleLabel?.font.pointSize)!)
                leftButton.setImage(UIImage(named: "backwards"), for: .normal)
                print("WIDTH", dateButton.frame.width)

                leftButton.setTitleColor(.black, for: .normal)
                leftButton.setTitleColor(.gray, for: .selected)
                // rightButton.setTitle(">", for: .normal)
                rightButton.setImage(UIImage(named: "fowards"), for: .normal)
                rightButton.setTitleColor(.gray, for: .selected)
                rightButton.setTitleColor(.black, for: .normal)
                leftButton.addTarget(self, action: #selector(backDay(sender:)), for: .touchUpInside)
                rightButton.addTarget(self, action: #selector(aheadDay(sender:)), for: .touchUpInside)

                //  label.addTarget(self, action: #selector(pressedOnDate(sender:)), for: .touchUpInside)
                //   self.calendarTableView.addGestureRecognizer(lpgr)

                calView.sizeToFit()
                calView.addSubview(dateButton)

                return calView
            } else {
                return nil
            }
        }
    }

    func addCalendarSwipe() {
        let directions: [UISwipeGestureRecognizer.Direction] = [.left, .right]
        for direction in directions {
            let gesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(sender:)))
            gesture.direction = direction
            calendarTableView.addGestureRecognizer(gesture)
        }
    }

    @objc func handleSwipe(sender: UISwipeGestureRecognizer) {
        if !loadCalendar {
            if sender.direction == .left {
                changeDays(sign: 1)
            } else {
                changeDays(sign: -1)
            }
        }
    }

    func tableView(_: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        if session.localDragSession != nil { // Drag originated from the same app.
            if withDestinationIndexPath?.row == 0 {
                return UITableViewDropProposal(operation: .forbidden)
            } else {
                return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
            }
        }

        return UITableViewDropProposal(operation: .forbidden)
    }

    func changeDays(sign: Int) {
        print("PRESSED")
        globalVariables.daysFromToday += sign
        let indexPath = IndexPath(row: 0, section: 0)
        calendarTableView.scrollToRow(at: indexPath, at: .top, animated: false)
        showSpinner(onView: calendarTableView)
        calendarTableView.isUserInteractionEnabled = false
        assignmentTableView.isUserInteractionEnabled = false
        toggleView.isUserInteractionEnabled = false
        navigationController?.navigationBar.isUserInteractionEnabled = false
        setUpCalendar()
        //    setUpInitialNotifications()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.setUpCalendar()
            self.calendarTableView.isUserInteractionEnabled = true
            self.assignmentTableView.isUserInteractionEnabled = true
            self.toggleView.isUserInteractionEnabled = true
            self.navigationController?.navigationBar.isUserInteractionEnabled = true
            self.removeSpinner()
        }
    }

    @objc func manualEntryDismissed() {
        print("POPOVER DISMISSED")
        beginClassImport()
    }

    @objc func calendarFromMainDismissed() {
        print("CALLED")
        changeDays(sign: 0)
    }
    @objc func showTutorial() {
        coachMarksController.start(in: .window(over: self))
    }

    @objc func performFetch() {
        print("FETCHING INFO")
        if Auth.auth().currentUser != nil {
            setUpInitialNotifications()
            setUpCalendar()
            if isClassroomEnabled {
                getInfo()
            } else {
                getClassesNoClassroom()
            }
            assignmentTableView.reloadData()
            calendarTableView.reloadData()
        } else {
            print("USER NOT SIGNED IN")
        }
    }

    @objc func backDay(sender _: UIButton) {
        changeDays(sign: -1)
    }

    @objc func aheadDay(sender _: UIButton) {
        changeDays(sign: 1)
    }

    @objc func tapSection(sender: UIButton) {
        if classNameAndAssignments.count > 0 {
            arrayHeader[sender.tag] = (arrayHeader[sender.tag] == 0) ? 1 : 0
            assignmentTableView.reloadSections([sender.tag], with: .fade)
            print(arrayHeader)
        }
    }

    func beginClassImport() {
        service.authorizer = myAuth

        assignmentTableView.isUserInteractionEnabled = false
        calendarTableView.isUserInteractionEnabled = false
        toggleView.isUserInteractionEnabled = false
        navigationController?.navigationBar.isUserInteractionEnabled = false
        arrayHeader = Array(repeating: 0, count: arrayHeader.count)
        classNameAndAssignments = [String: [String]]()
        newClassNameAndAssignments = [String: [String]]()
        //  if toggleView.segments[0].selectedView.
        if isClassroomEnabled {
            getInfo()
        } else {
            getClassesNoClassroom()
        }

        if isClassroomEnabled {
            showSpinner(onView: assignmentTableView)
        }

        assignmentTableView.reloadData()
        calendarTableView.reloadData()
    }

    @objc func importClasses(sender _: UIButton) {
        Database.database().reference().child("users").child((Auth.auth().currentUser?.uid) ?? "").child("Added Assignments").observeSingleEvent(of: .value, with: { [self] snapshot in

            if snapshot.exists() || self.isClassroomEnabled {
                self.beginClassImport()
                self.importButtonText = "Loading..."
            } else {
                self.noAssignmentsAlert()
            }
        })
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection _: Int) -> String? {
        if tableView == calendarTableView {
            return "Calendar"

        } else {
            return nil
        }
    }

    func showAllClassInfo(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "assignmentCell", for: indexPath) as! AssignmentTableViewCell

        assignmentCellWidth = cell.bounds.width
        assignmentTableView.bounds.size.width = 142
        //     cell.frame = CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: cell.frame.size.height)

        classes = [String](classNameAndAssignments.keys)
        // let assignments: Array<Array<String>> = Array<Array<String>>(classNameAndAssignments.values)
        cell.backgroundColor = .white
        cell.selectionStyle = .none

        if classNameAndAssignments.count > 0 {
            if cell.classAssignments.text == "Assignments" {
                cell.classAssignments.text = ""
            } else {
                // cell.classTitle.text = classes[indexPath.row]
                //                let assignments = classNameAndAssignments[classes[indexPath.row]]?.joined(separator: "; ") // "1-2-3"
                //              cell.classAssignments.text = assignments//
                if indexPath.row < classNameAndAssignments[classes[indexPath.section]]!.count {
                    var cellText = ""

                    var dueDate = ""
                    if arrayHeader[indexPath.section] == 1 {
                        cellText = newClassNameAndAssignments[classes[indexPath.section]]?[indexPath.row] ?? ""
                        dueDate = assignmentAndDueDate[cellText] ?? ""
                    } else if arrayHeader[indexPath.section] == 2 {
                        cellText = classNameAndAssignments[classes[indexPath.section]]?[indexPath.row] ?? ""
                        dueDate = assignmentAndDueDate[cellText] ?? ""
                    }
                    cell.classAssignments.text = "\(cellText)\n\n\(dueDate)"
                }
            }

            if calendarItems.contains(cell.classAssignments.text), !loadCalendar {
                cell.classAssignments.textColor = .lightGray
            } else {
                cell.classAssignments.textColor = .black
            }

        } else {
            cell.classAssignments.text = "Assignments"
        }

        return cell
    }

    func checkTimeIsValid(from string: String) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a"
        if dateFormatter.date(from: string) != nil {
            return true
        } else {
            return false
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == assignmentTableView {
            return showAllClassInfo(tableView, cellForRowAt: indexPath)
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "calendarCell", for: indexPath) as! CalendarTableViewCell
            var fixedTime = ""
            cell.selectionStyle = .none

            if !loadCalendar {
                if calendarItems[indexPath.row].first == "0" {
                    fixedTime = String(calendarItems[indexPath.row].dropFirst())
                } else {
                    fixedTime = calendarItems[indexPath.row]
                }
            }

            cell.calendarEventText.text = fixedTime

            if checkTimeIsValid(from: cell.calendarEventText.text) {
                cell.backgroundColor = .customOrange
                cell.isUserInteractionEnabled = false
            } else {
                if loadCalendar {
                    cell.backgroundColor = .clear
                } else {
                    cell.backgroundColor = .white
                }
                cell.isUserInteractionEnabled = true
            }

            return cell
        }
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if tableView == assignmentTableView {
            if classNameAndAssignments.count > 0 {
                if arrayHeader[section] == 1 || arrayHeader[section] == 2 {
                    return 50
                } else {
                    return 0
                }
            } else {
                return 0
            }
        } else {
            return 0
        }
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if tableView == assignmentTableView {
            if classNameAndAssignments.count > 0 {
                // tableView.frame.size.width/4
                classes = [String](classNameAndAssignments.keys)
                let view = UIView()
                view.backgroundColor = .clear
                let button = UIButton()

                button.layer.cornerRadius = 10

                if newClassNameAndAssignments[classes[section]]!.count > 0 {
                    button.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
                } else {
                    if arrayHeader[section] == 2 {
                        button.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
                    } else {
                        button.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMinXMinYCorner]
                    }
                }

                button.backgroundColor = .customGray
                button.tag = section

                button.addTarget(self, action: #selector(showAllClasses(sender:)), for: .touchUpInside)

                view.addSubview(button)
                button.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
                button.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
                button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15).isActive = true
                button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15).isActive = true
                button.translatesAutoresizingMaskIntoConstraints = false
                button.setTitleColor(.black, for: .normal)
                button.titleLabel!.font = UIFont(name: "AvenirNext-Regular", size: 15)
                if arrayHeader[section] == 1 {
                    button.setTitle("Show All", for: .normal)

                    return view

                } else if arrayHeader[section] == 2 {
                    // let minusImage = UIImage(named: "minus")
                    button.setTitle("Hide All", for: .normal)

                    return view
                } else {
                    return nil
                }
            } else {
                return nil
            }

        } else {
            return nil
        }
    }

    @objc func showAllClasses(sender: UIButton) {
        print("PRESSED")

        if classNameAndAssignments.count > 0 {
            arrayHeader[sender.tag] = (arrayHeader[sender.tag] == 1) ? 2 : 1
            assignmentTableView.reloadSections([sender.tag], with: .fade)

            print(arrayHeader)
        }
    }

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

    func setUpInitialNotifications() {
        var notifcationList = [String]()
        Database.database().reference().child("users").child((Auth.auth().currentUser?.uid) ?? "").child("Reminders").observe(.value, with: { snapshot in
            if snapshot.exists() {
                //  self.followButton.isEnabled = true
                // self.calendarItems.append("12:00 AM")
                self.center.removeAllPendingNotificationRequests()
                if let notifcationData = snapshot.value as? NSArray {
                    notifcationList = notifcationData as! [String]

                    for identifer in notifcationList {
                        self.setUpNotificationsFirebase(identifer: identifer)
                        print("IDIDID", identifer)
                    }
                }
            }
        })

        calendarTableView.reloadData()
        assignmentTableView.reloadData()
    }

    func setUpCalendar() {
        // print("DATA", Database.database().reference().child((Auth.auth().currentUser?.displayName)!).value(forKey: getViewedDate()) as! [String])

        Database.database().reference().child("users").child((Auth.auth().currentUser?.uid) ?? "").child(getViewedDate()).observe(.value, with: { snapshot in
            if snapshot.exists() {
                //  self.followButton.isEnabled = true
                self.calendarItems = []
                // self.calendarItems.append("12:00 AM")
                if let calendarData = snapshot.value as? NSArray {
                    self.calendarItems = calendarData as! [String]
                }
                print("ARRAY", self.refResponse.child((Auth.auth().currentUser?.uid)!).child(self.getViewedDate()))
            } else {
                print("Not in array")
                let lastTime: Double = 23
                var currentTime: Double = -0.5
                let incrementMinutes: Double = 30 // increment by 15 minutes
                self.calendarItems = []
                // self.calendarItems.append("12:00 AM")

                while currentTime <= lastTime {
                    currentTime += (incrementMinutes / 60)

                    let hours = Int(floor(currentTime))
                    let minutes = Int(currentTime.truncatingRemainder(dividingBy: 1) * 60)

                    if minutes == 0 {
                        let time24 = "\(hours):00"
                        self.calendarItems.append(self.timeConversion12(time24: time24))
                    } else {
                        let time24 = "\(hours):\(minutes)"
                        self.calendarItems.append(self.timeConversion12(time24: time24))
                    }
                }
                self.addResponse()
            }
        }) { error in
            print(error.localizedDescription)
        }

        calendarTableView.reloadData()
        assignmentTableView.reloadData()
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

    func tableView(_: UITableView, editingStyleForRowAt _: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }

    func tableView(_: UITableView, shouldIndentWhileEditingRowAt _: IndexPath) -> Bool {
        return false
    }

    func tableView(_: UITableView, canMoveRowAt _: IndexPath) -> Bool {
        return true
    }

    func tableView(_: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        getReminderTime(indexPath: sourceIndexPath)
        let oldReminderTime = reminderTime
        let assignment = calendarItems[sourceIndexPath.row]
        let nameAndDueDate = assignment.components(separatedBy: "\n\nDue: ")

        let movedObject = calendarItems[sourceIndexPath.row]
        calendarItems.remove(at: sourceIndexPath.row)
        calendarItems.insert(movedObject, at: destinationIndexPath.row)

        getReminderTime(indexPath: destinationIndexPath)

        let oldNotifcationDate = "\(notificationDay) \(oldReminderTime)"
        let newNotifcationDate = "\(notificationDay) \(reminderTime)"
        let identifier = "\(nameAndDueDate[0])\(nameAndDueDate[1])\(newNotifcationDate)"

        center.removePendingNotificationRequests(withIdentifiers: ["\(nameAndDueDate[0])\(nameAndDueDate[1])\(oldNotifcationDate)"])

        setUpNotificationsFirebase(identifer: identifier)

        addResponse()

        calendarTableView.reloadData()
        assignmentTableView.reloadData()
    }

    @objc func pressedOnDate(sender _: UIButton) {
        calVC.modalPresentationStyle = .popover
        calVC.rootIsMainViewContoller = true
        let popover: UIPopoverPresentationController = calVC.popoverPresentationController!
        popover.sourceView = view
        popover.sourceRect = CGRect(x: view.center.x, y: view.center.y, width: 0, height: 0)
        popover.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)

        present(calVC, animated: true, completion: nil)
    }

    func loadCal() {
        calendarTableView.isUserInteractionEnabled = false
        assignmentTableView.isUserInteractionEnabled = false
        toggleView.isUserInteractionEnabled = false
        navigationController?.navigationBar.isUserInteractionEnabled = false
        setUpCalendar()
        setUpInitialNotifications()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.loadCalendar = false
            self.setUpCalendar()
        }
    }

    func addResponse() {
        let currentDate = getViewedDate()

        var reminders = [String]()
        center.getPendingNotificationRequests { notifications in
            print("Count: \(notifications.count)")
            if notifications.count == 0 {
                self.center.removeAllPendingNotificationRequests()
                self.refResponse.child((Auth.auth().currentUser?.uid)!).child("Reminders").removeValue()
            } else {
                for item in notifications {
                    print("IDID", item.identifier)
                    reminders.append(item.identifier)
                    self.refResponse.child((Auth.auth().currentUser?.uid)!).child("Reminders").setValue(reminders)

                    print("Reminders", reminders)
                }
            }
        }
        //  self.setUpInitialNotifications()

        refResponse.child((Auth.auth().currentUser?.uid)!).child(currentDate).setValue(calendarItems)
        //  refResponse.child((Auth.auth().currentUser?.uid)!).child("Reminders").setValue(reminders)
    }

    func setUpNotificationsFirebase(identifer: String) {
        let content = UNMutableNotificationContent()

        let notificationComponents = identifer.components(separatedBy: "")
        let name = notificationComponents[0]
        let dueDate = notificationComponents[1]
        let notificationDate = notificationComponents[2]

        content.title = "Study for \"\(name)\""
        content.body = "Make sure to turn \"\(name)\" in by \(dueDate)"
        content.sound = .default

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = .current

        if is12Hours() {
            dateFormatter.dateFormat = "MMM dd, yyyy hh:mm a"
        } else {
            dateFormatter.dateFormat = "MMM dd, yyyy HH:mm"
        }

        let turnInDate = dateFormatter.date(from: notificationDate)!

        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute],
                                                          from: turnInDate)

        print(triggerDate)

        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let request = UNNotificationRequest(identifier: identifer, content: content, trigger: trigger)

        center.add(request, withCompletionHandler: { error in
            if let error = error {
                print("ERROR: \(error)")
            }
        })
    }

    func is12Hours() -> Bool {
        let dateString: String = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: Locale.current)!

        if dateString.contains("a") {
            // 12 h format
            return true
        } else {
            // 24 h format
            return false
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if size.width != view.frame.size.width {
            // Reload TableView to update cell's constraints.
            // Ensuring no dequeued cells have old constraints.
            DispatchQueue.main.async {
                self.calendarTableView.reloadData()
                self.assignmentTableView.reloadData()
                guard let calPopover: UIPopoverPresentationController = self.calVC.popoverPresentationController else { return }
                calPopover.sourceView = self.view
                calPopover.sourceRect = CGRect(x: self.view.center.x, y: self.view.center.y, width: 0, height: 0)
                
            }
        }
    }

    func application(_: UIApplication,
                     open url: URL, sourceApplication _: String?, annotation _: Any) -> Bool {
        return GIDSignIn.sharedInstance().handle(url)
    }

    @available(iOS 9.0, *)
    func application(_: UIApplication, open url: URL, options _: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
        return GIDSignIn.sharedInstance().handle(url)
    }

    func handleSignInError() {
        assignmentTableView.isUserInteractionEnabled = true
        calendarTableView.isUserInteractionEnabled = true
        toggleView.isUserInteractionEnabled = true
        globalVariables.selectTutorial = .noImport
        navigationController?.navigationBar.isUserInteractionEnabled = true
        importButtonText = "Import\nClasses"
        GIDSignIn.sharedInstance()?.signOut()
        assignmentTableView.reloadData()
        calendarTableView.reloadData()
    }

    func sign(_: GIDSignIn!, didSignInFor _: GIDGoogleUser!,
              withError error: Error!) {
        print("SIGN IN")

        if let error = error {
            if (error as NSError).code == GIDSignInErrorCode.hasNoAuthInKeychain.rawValue {
                print("The user has not signed in before or they have since signed out.")
                GIDSignIn.sharedInstance()?.signIn()
            } else {
                handleSignInError()
                removeSpinner()
            }
        } else {
            getInfo()
        }
    }

    func userAlreadyExist(kUsernameKey: String) -> Bool {
        return UserDefaults.standard.object(forKey: kUsernameKey) != nil
    }

    func sign(_: GIDSignIn!, didDisconnectWith _: GIDGoogleUser!,
              withError _: Error!) {}

    override func viewDidLoad() {
        super.viewDidLoad()

        coachMarksController.dataSource = self
        coachMarksController.delegate = self

        if !UserDefaults.standard.bool(forKey: "Notification Permission") {
            UserDefaults.standard.set(true, forKey: "Notification Permission")
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) {
                granted, _ in
                if granted {
                    print("yes")
                } else {
                    print("No")
                }
            }
        }

        if #available(iOS 13.0, *) {
            coachMarksController.statusBarStyle = .darkContent
        } else {
            coachMarksController.statusBarStyle = .default
        }

        // manualEntryButton.
        // self.coachMarksController.coa
        if userAlreadyExist(kUsernameKey: "isClassroomEnabled") {
            isClassroomEnabled = UserDefaults.standard.bool(forKey: "isClassroomEnabled")
        } else {
            isClassroomEnabled = true
        }

        if userAlreadyExist(kUsernameKey: "hasSignedIn") {
            hasSignedIn = UserDefaults.standard.bool(forKey: "hasSignedIn")
        } else {
            hasSignedIn = false
        }

        if #available(iOS 13.0, *) {
            self.overrideUserInterfaceStyle = .light
        }

        Database.database().reference().child("users").child((Auth.auth().currentUser?.uid) ?? "").child("Added Assignments").observeSingleEvent(of: .value, with: { [self] snapshot in

            if snapshot.exists() || self.isClassroomEnabled {
                if !self.hasSignedIn {
                    let alert = UIAlertController(title: "Welcome to Quick Plan!", message: "Would you like to connect your Google Classroom account?", preferredStyle: .alert)

                    let yes = UIAlertAction(title: "Yes", style: .default) { [] (_: UIAlertAction) in

                        self.beginClassImport()
                        self.importButtonText = "Loading..."
                    }
                    let no = UIAlertAction(title: "No", style: .cancel) { (_: UIAlertAction) in
                        alert.dismiss(animated: true, completion: nil)
                        self.handleSignInError()
                        GIDSignIn.sharedInstance()?.signOut()
                        // Add a tutorial shortened view by turning bool into enum
                    }

                    alert.addAction(no)
                    alert.addAction(yes)

                    self.present(alert, animated: true)

                } else {
                    self.beginClassImport()
                    self.importButtonText = "Loading..."
                }

            } else {
                self.noAssignmentsAlert()
            }

            loadCal()
        })

        //    classroomToggle.tintColor = .customGreen

        NotificationCenter.default.addObserver(self, selector: #selector(performFetch), name: Notification.Name("performFetchAuto"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(manualEntryDismissed), name: Notification.Name("manualEntryDismissed"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(calendarFromMainDismissed), name: Notification.Name("calendarFromMainDismissed"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showTutorial), name: Notification.Name("showTutorial"), object: nil)

        service.authorizer = myAuth

        refResponse = Database.database().reference().child("users")

        GIDSignIn.sharedInstance().delegate = self

        GIDSignIn.sharedInstance()?.presentingViewController = self
        GIDSignIn.sharedInstance().scopes = scopes

        assignmentTableView.delegate = self
        assignmentTableView.dataSource = self

        calendarTableView.delegate = self
        calendarTableView.dataSource = self

        assignmentTableView.separatorInset = UIEdgeInsets(top: .zero, left: 15, bottom: .zero, right: 15)
        calendarTableView.separatorInset = UIEdgeInsets(top: .zero, left: 15, bottom: .zero, right: 15)

        assignmentTableView.backgroundColor = .customBlue

        assignmentTableView.estimatedRowHeight = 250.0 // Replace with your actual estimation
        // Automatic dimensions to tell the table view to use dynamic height
        assignmentTableView.rowHeight = UITableView.automaticDimension

        calendarTableView.estimatedRowHeight = 250.0 // Replace with your actual estimation
        // Automatic dimensions to tell the table view to use dynamic height
        calendarTableView.rowHeight = UITableView.automaticDimension

        assignmentTableView.dragDelegate = self
        calendarTableView.dragDelegate = self
        calendarTableView.dropDelegate = self
        assignmentTableView.dragInteractionEnabled = true
        calendarTableView.dragInteractionEnabled = true

        //  self.assignmentTableView.register(AssignmentTableViewCell.self, forCellReuseIdentifier: "assignmentCell")
        let nibClassroom = UINib(nibName: "AssignmentTableViewCell", bundle: nil)
        assignmentTableView.register(nibClassroom, forCellReuseIdentifier: "assignmentCell")

        let nibCalendar = UINib(nibName: "CalendarTableViewCell", bundle: nil)
        calendarTableView.register(nibCalendar, forCellReuseIdentifier: "calendarCell")

        configureTitleView()

        setUpUI(view: assignmentTableView)
        setUpUI(view: calendarTableView)
        setUpUI(view: toggleView)
        toggleView.addTarget(self, action: #selector(controlValueChanged(_:)), for: .valueChanged)
        toggleView.segments = LabelSegment.segments(withTitles: ["", ""])

        enabledImageView.frame = CGRect(x: toggleView.frame.width / 4 - 20, y: toggleView.frame.height / 2 - 20, width: 40, height: 40)

        enabledImageView.image = enabledImageView.image?.withRenderingMode(.alwaysTemplate)
        enabledImageView.isUserInteractionEnabled = false

        disabledImageView.frame = CGRect(x: toggleView.frame.width * (3 / 4) - 20, y: toggleView.frame.height / 2 - 20, width: 40, height: 40)

        disabledImageView.image = disabledImageView.image?.withRenderingMode(.alwaysTemplate)

        disabledImageView.isUserInteractionEnabled = false

        toggleView.addSubview(enabledImageView)
        toggleView.addSubview(disabledImageView)

        if isClassroomEnabled {
            toggleView.setIndex(0)
            disabledImageView.tintColor = .red
            enabledImageView.tintColor = .black
            toggleView.indicatorViewBackgroundColor = .customGreen
        } else {
            toggleView.setIndex(1)
            disabledImageView.tintColor = .black
            enabledImageView.tintColor = .customGreen
            toggleView.indicatorViewBackgroundColor = .red
        }

        addCalendarSwipe()

        navigationController?.navigationBar.transparentNavigationBar()

        view.backgroundColor = .customPurple
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("APPEAR")
        setUpInitialNotifications()
    }

    func coachMarksController(_: CoachMarksController, willShow coachMark: inout CoachMark, beforeChanging _: ConfigurationChange, at index: Int) {
        switch globalVariables.selectTutorial {
        case .full:
            switch index {
            case 0:
                coachMark.arrowOrientation = .bottom
            case 1:
                coachMark.arrowOrientation = .top
            case 2:
                coachMark.arrowOrientation = .bottom
            case 3:
                coachMark.arrowOrientation = .top
            case 4:
                coachMark.arrowOrientation = .top
            case 5:
                coachMark.arrowOrientation = .top
            case 6:
                coachMark.arrowOrientation = .top
            case 7:
                coachMark.arrowOrientation = .top
            default:
                break
            }
        case .noAddedClasses:
            coachMark.arrowOrientation = .top
        case .noImport:
            return
        }
    }

    func coachMarksController(_ coachMarksController: CoachMarksController, coachMarkAt index: Int) -> CoachMark {
        var coachMark = CoachMark()
        let rightBarButton = navigationItem.rightBarButtonItem! as UIBarButtonItem
        let viewRight = rightBarButton.value(forKey: "view") as! UIView

        switch globalVariables.selectTutorial {
        case .full:
            switch index {
            case 0:
                coachMark = coachMarksController.helper.makeCoachMark(for: assignmentTableView)
            case 1:
                coachMark = coachMarksController.helper.makeCoachMark(for: assignmentButton.titleLabel)
            case 2:
                coachMark = coachMarksController.helper.makeCoachMark(for: calendarTableView)
            case 3:
                coachMark = coachMarksController.helper.makeCoachMark(for: assignmentButton.titleLabel)
            case 4:
                coachMark = coachMarksController.helper.makeCoachMark(for: calView)
            case 5:
                coachMark = coachMarksController.helper.makeCoachMark(for: dateButton)
            case 6:
                coachMark = coachMarksController.helper.makeCoachMark(for: viewRight)
            case 7:
                coachMark = coachMarksController.helper.makeCoachMark(for: toggleView)
            default:
                break
            }
        case .noAddedClasses:
            coachMark = coachMarksController.helper.makeCoachMark(for: viewRight)
        case .noImport:
            print("will add")
        }
        return coachMark
    }

    func coachMarksController(_ coachMarksController: CoachMarksController, coachMarkViewsAt index: Int, madeFrom coachMark: CoachMark) -> (bodyView: UIView & CoachMarkBodyView, arrowView: (UIView & CoachMarkArrowView)?) {
        let coachViews = coachMarksController.helper.makeDefaultCoachViews(withArrow: true, arrowOrientation: coachMark.arrowOrientation)

        coachViews.bodyView.hintLabel.font = UIFont(name: "AvenirNext-Regular", size: coachViews.bodyView.hintLabel.font!.pointSize)
        coachViews.bodyView.nextLabel.font = UIFont(name: "AvenirNext-Regular", size: coachViews.bodyView.nextLabel.font!.pointSize)

        coachViews.arrowView!.background.borderColor = .darkGray
        coachViews.bodyView.background.cornerRadius = 10
        coachViews.bodyView.background.borderColor = .darkGray

        coachViews.bodyView.layer.shadowColor = UIColor.darkGray.cgColor
        coachViews.bodyView.layer.shadowOffset = CGSize(width: -2, height: 2)
        coachViews.bodyView.layer.shadowOpacity = 1.0
        coachViews.bodyView.layer.shadowRadius = 1.5

        switch globalVariables.selectTutorial {
        case .full:
            switch index {
            case 0:
                coachViews.bodyView.hintLabel.text = "These are your classes"
            case 1:
                coachViews.bodyView.hintLabel.text = "You can click on a class to view its corresponding assignments"
            case 2:
                coachViews.bodyView.hintLabel.text = "This is your calendar"
            case 3:
                coachViews.bodyView.hintLabel.text = "You can drag the assignments onto the calendar, and you will receive a notification at the appropriate time and date"
            case 4:
                coachViews.bodyView.hintLabel.text = "You can use the arrows to change the date"
            case 5:
                coachViews.bodyView.hintLabel.text = "You can also click on the date to view a monthly calendar"
            case 6:
                coachViews.bodyView.hintLabel.text = "If an assignment is not in Google Classroom, you can click here to create it manually"
            case 7:
                coachViews.bodyView.hintLabel.text = "Lastly, you can use this toggle to seperate your Classroom assignments from your created assignments"
            default:
                break
            }
            if index != 7 {
                coachViews.bodyView.nextLabel.text = "Ok"
            } else {
                coachViews.bodyView.nextLabel.text = "Done"
            }
        case .noAddedClasses:
            coachViews.bodyView.hintLabel.text = "Please create a new class"
            coachViews.bodyView.nextLabel.text = "Ok"
        case .noImport:
            print("will add")
        }

        return (bodyView: coachViews.bodyView, arrowView: coachViews.arrowView)
    }

    func numberOfCoachMarks(for _: CoachMarksController) -> Int {
        switch globalVariables.selectTutorial {
        case .full:
            return 8
        case .noAddedClasses:
            return 1
        case .noImport:
            return 0
        }
    }

    func configureTitleView() {
        var firstName = Auth.auth().currentUser?.displayName ?? "User"
        var greeting = String()

        if let dotRange = firstName.range(of: " ") {
            firstName.removeSubrange(dotRange.lowerBound ..< firstName.endIndex)
        }

        let now = NSDate()
        let nowDateValue = now as Date

        let midnight1 = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: nowDateValue)
        let midnight2 = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: nowDateValue)
        let sixAM = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: nowDateValue)
        let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: nowDateValue)
        let sixPM = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: nowDateValue)

        if nowDateValue >= midnight1!, nowDateValue <= sixAM! {
            greeting = "Good Evening"
        } else if nowDateValue >= sixAM!, nowDateValue <= noon! {
            greeting = "Good Morning"
        } else if nowDateValue >= noon!, nowDateValue <= sixPM! {
            greeting = "Good Afternoon"
        } else if nowDateValue >= sixPM!, nowDateValue <= midnight2! {
            greeting = "Good Evening"
        }

        let titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: (navigationController?.navigationBar.frame.width)!, height: (navigationController?.navigationBar.frame.height)!))

        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        titleLabel.text = "\(greeting), \(firstName)!"
        titleLabel.font = UIFont(name: "AvenirNext-Regular", size: 22)
        titleLabel.adjustsFontSizeToFitWidth = true

        navigationItem.titleView = titleLabel
    }

    func setUpUI(view: UIView) {
        let containerView: UIView = UIView(frame: view.frame)
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

    @objc func controlValueChanged(_ sender: BetterSegmentedControl) {
        Database.database().reference().child("users").child((Auth.auth().currentUser?.uid) ?? "").child("Added Assignments").observeSingleEvent(of: .value, with: { [self] snapshot in

            if sender.index == 0 {
                print("Enabled")
                self.isClassroomEnabled = true
                sender.indicatorViewBackgroundColor = .customGreen
                self.enabledImageView.tintColor = .black
                self.disabledImageView.tintColor = .red
                self.importButtonText = "Loading..."
            } else {
                print("Disabled")
                self.isClassroomEnabled = false
                sender.indicatorViewBackgroundColor = .red
                self.enabledImageView.tintColor = .customGreen
                self.disabledImageView.tintColor = .black
            }
            UserDefaults.standard.set(self.isClassroomEnabled, forKey: "isClassroomEnabled")
            if snapshot.exists() || self.isClassroomEnabled {
                self.beginClassImport()
            } else {
                self.noAssignmentsAlert()
            }
        })
    }

    func fetchCourses() {
        let query = GTLRClassroomQuery_CoursesList.query()
        query.pageSize = 100
        query.executionParameters.shouldFetchNextPages = true
        service.executeQuery(query,
                             delegate: self,
                             didFinish: #selector(obtainClassIds(ticket:finishedWithObject:error:)))
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        if tableView == calendarTableView {
            let deleteAction = UITableViewRowAction(style: .default, title: "Delete", handler: { _, indexPath in

                self.getReminderTime(indexPath: indexPath)
                let notifcationDate = "\(self.notificationDay) \(self.reminderTime)"
                let assignment = self.calendarItems[indexPath.row]

                let nameAndDueDate = assignment.components(separatedBy: "\n\nDue: ")

                self.center.removePendingNotificationRequests(withIdentifiers: ["\(nameAndDueDate[0])\(nameAndDueDate[1])\(notifcationDate)"])

                self.calendarItems.remove(at: indexPath.row)
                self.addResponse()
                tableView.deleteRows(at: [indexPath], with: .automatic)

                tableView.reloadData()
                self.assignmentTableView.reloadData()

            })
            deleteAction.backgroundColor = UIColor.red

            return [deleteAction]
        } else {
            return nil
        }
    }

    func fetchAssignments() {
        print("FETCH")
        assignmentsPerCourse = Array(repeating: [], count: classIDAndNameClassroom.count)
        newAssignmentsPerCourse = Array(repeating: [], count: classIDAndNameClassroom.count)

        for (key, _) in classIDAndNameClassroom {
            if classIDAndNameClassroom != [:] {
                // let intClassID = Int(classIDAndNameClassroom[key] ?? "0")
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
    }

    func getCurrentDate() -> Date {
        let currentMonth = calendar.component(.month, from: date)
        let currentDay = calendar.component(.day, from: date)
        let currentYear = calendar.component(.year, from: date)

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = .current
        dateFormatter.dateFormat = "MM/dd/yyyy"

        return dateFormatter.date(from: "\(currentMonth)/\(currentDay)/\(currentYear)") ?? Date()
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    @objc func obtainClasses(ticket _: GTLRServiceTicket,
                             finishedWithObject result: GTLRClassroom_ListCourseWorkResponse,
                             error: NSError?) {
        if let error = error {
            print(error.localizedDescription)
            return
        }

        guard let assignments = result.courseWork, !assignments.isEmpty else {
            print("No assignments.")
            assignmentsPerCourse.remove(at: assignmentIndex)
            newAssignmentsPerCourse.remove(at: assignmentIndex)
            return
        }

        let currentDate = getCurrentDate()

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

            // outputText += "Title: \(assignment.title ?? "No title")\nDue Date: \(dueMonth ?? 0)/\(dueDay ?? 0)/\(dueYear ?? 0)\n"
            if assignmentsPerCourse.count != 0 {
                if assignmentsPerCourse[assignmentIndex].count == 0 {
                    assignmentsPerCourse[assignmentIndex].append(classIDAndNameClassroom[assignment.courseId ?? "0"] ?? "No name")
                    newAssignmentsPerCourse[assignmentIndex].append(classIDAndNameClassroom[assignment.courseId ?? "0"] ?? "No name")
                }
            }
            assignmentsPerCourse[assignmentIndex].append(assignment.title ?? "No title")

            //                    print("server:", finalDate)
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = .current
            dateFormatter.dateFormat = "MM/dd/yyyy"

            let dueDate = dateFormatter.date(from: finalDate) ?? Date()
            print(dueDate, currentDate)
            if dueDate > currentDate {
                newAssignmentsPerCourse[assignmentIndex].append(assignment.title ?? "No title")
            }

            print(newAssignmentsPerCourse)
        }

        if assignmentIndex + 1 >= assignmentsPerCourse.count {
            print("FINISHED")

            showInfo()
            //  assignmentTableView.reloadData()

        } else {
            assignmentIndex += 1
        }
    }

    func errorNotification() {
        let alert = UIAlertController(title: "Unable to Show Info", message: "Please use a different account", preferredStyle: .alert)

        let tryAgain = UIAlertAction(title: "Try Again", style: .default) { [] (_: UIAlertAction) in

            GIDSignIn.sharedInstance()?.signIn()
        }

        alert.addAction(tryAgain)

        present(alert, animated: true)
    }

    @objc func obtainClassIds(ticket _: GTLRServiceTicket,
                              finishedWithObject result: GTLRClassroom_ListCoursesResponse,
                              error: NSError?) {
        if let error = error {
            print("ERRORERRORO")
            print(error.localizedDescription)

            if error.localizedDescription == "Request had insufficient authentication scopes." {
                GIDSignIn.sharedInstance()?.signIn()
            } else if error.localizedDescription == "@ClassroomDisabled The user is not permitted to access Classroom." {
                errorNotification()
            } else if (GIDSignIn.sharedInstance()?.hasPreviousSignIn()) != nil {
                GIDSignIn.sharedInstance()?.restorePreviousSignIn()
            } else {
                errorNotification()
            }

            return
        }

        guard let courses = result.courses, !courses.isEmpty else {
            print("No courses.")
            errorNotification()
            return
        }

        var ownerIDs = Set<String>()
        for course in courses {
            if course.courseState == "ACTIVE" {
                let currentOwnerID = "\(course)".slice(from: "ownerId:\"", to: "\"")!
                ownerIDs.insert(currentOwnerID)
                if GIDSignIn.sharedInstance()?.currentUser.userID.description != currentOwnerID {
                    classIDAndNameClassroom.updateValue(course.name ?? "no name", forKey: course.identifier ?? "00000")
                }
            }
        }

        if [GIDSignIn.sharedInstance()?.currentUser.userID.description] == ownerIDs {
            errorNotification()
        }

        assignmentIndex = 0
        fetchAssignments()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        if tableView == assignmentTableView {
            if classNameAndAssignments.count > 0 {
                return 125
            } else {
                return 100
            }
        } else {
            return 75
            // }
        }
    }

    func noAssignmentsAlert() {
        arrayHeader = Array(repeating: 0, count: arrayHeader.count)
        classNameAndAssignments = [String: [String]]()
        newClassNameAndAssignments = [String: [String]]()
        print("NO ADDED ASSIGNMENTS")
        importButtonText = "Import\nClasses"

        globalVariables.selectTutorial = .noAddedClasses
        coachMarksController.start(in: .window(over: self))

        assignmentTableView.isUserInteractionEnabled = true
        calendarTableView.isUserInteractionEnabled = true
        toggleView.isUserInteractionEnabled = true
        navigationController?.navigationBar.isUserInteractionEnabled = true
        assignmentTableView.reloadData()
        calendarTableView.reloadData()
    }

    @IBAction func showManualEntry(_ sender: UIBarButtonItem) {
        print("YES")

        let vc = ManualEntryViewController(nibName: "ManualEntryViewController", bundle: nil)
        vc.classNames = [String](classNameAndAssignments.keys)
        vc.modalPresentationStyle = .popover
        let popover: UIPopoverPresentationController = vc.popoverPresentationController!
        popover.barButtonItem = sender

        present(vc, animated: true, completion: nil)
    }
    
    @IBAction func showSettings(_ sender: UIBarButtonItem) {
        
        let vc = SettingsViewController(nibName: "SettingsViewController", bundle: nil)
        vc.modalPresentationStyle = .popover
        let popover: UIPopoverPresentationController = vc.popoverPresentationController!
        popover.barButtonItem = sender

        present(vc, animated: true, completion: nil)
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

    func finishedGettingInfo() {
        print("RELOAD")
        assignmentIndex = 0
        importButtonText = "Import\nClasses"
        arrayHeader = Array(repeating: 0, count: classNameAndAssignments.count)
        print("COUNTCOUNT", arrayHeader.count)
        removeSpinner()
        assignmentTableView.isUserInteractionEnabled = true
        calendarTableView.isUserInteractionEnabled = true
        toggleView.isUserInteractionEnabled = true
        navigationController?.navigationBar.isUserInteractionEnabled = true
        assignmentTableView.reloadData()
        UserDefaults.standard.set(true, forKey: "hasSignedIn")
        globalVariables.selectTutorial = .full
        if !UserDefaults.standard.bool(forKey: "First Launch") {
            coachMarksController.start(in: .window(over: self))
            UserDefaults.standard.set(true, forKey: "First Launch")
        }
    }

    func getClassesNoClassroom() {
        Database.database().reference().child("users").child((Auth.auth().currentUser?.uid) ?? "").child("Added Assignments").observeSingleEvent(of: .value, with: { [self] snapshot in

            self.assignmentsPerCourse = Array(repeating: [], count: snapshot.children.allObjects.count)
            self.newAssignmentsPerCourse = Array(repeating: [], count: snapshot.children.allObjects.count)
            // self.arrayHeader = Array(repeating: 0, count: snapshot.children.allObjects.count)

            for i in 0 ... snapshot.children.allObjects.count - 1 {
                let encodedSnapshot = "\(snapshot.children.allObjects[i])"
                let className = "\(encodedSnapshot.removingPercentEncoding ?? "")".slice(from: "(", to: ")")!
                let classNameWithDivider = "\(className)"
                print("NAME", className)
                if self.classNameAndAssignments[className] == nil {
                    self.getClassesFromFirebase(assignmentsAndDueDate: snapshot.childSnapshot(forPath: classNameWithDivider.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!).value as! [String], assignmentsPerCourse: self.assignmentsPerCourse[i], newAsignmentsPerCourse: self.newAssignmentsPerCourse[i], className: className, classInClassroom: false)
                }

                if i >= snapshot.children.allObjects.count - 1 {
                    self.finishedGettingInfo()
                }
            }

        })
    }

    func getClassesFromFirebase(assignmentsAndDueDate: [String], assignmentsPerCourse: [String], newAsignmentsPerCourse: [String], className: String, classInClassroom: Bool) {
        var allNewNames = [String]()
        var allNames = [String]()

        let currentDate = getCurrentDate()

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = .current
        dateFormatter.dateFormat = "MM/dd/yyyy"

        for name in assignmentsAndDueDate {
            let nameAndDueDate = name.components(separatedBy: "\n\nDue: ")
            allNames.append(nameAndDueDate[0])
            assignmentAndDueDate.updateValue("Due: \(nameAndDueDate[1])", forKey: nameAndDueDate[0])
            let dueDate = dateFormatter.date(from: nameAndDueDate[1]) ?? Date()
            if dueDate > currentDate {
                allNewNames.append(nameAndDueDate[0])
            }
        }

        if classInClassroom {
            allNames.append(contentsOf: assignmentsPerCourse.arrayWithoutFirstElement())
            allNewNames.append(contentsOf: newAsignmentsPerCourse.arrayWithoutFirstElement())
        }

        print("TESTING", allNames)
        classNameAndAssignments.updateValue(allNames, forKey: className)
        newClassNameAndAssignments.updateValue(allNewNames, forKey: className)
    }

    func classroomOnlyFetch(assignmentsPerCourse: [String], newAssignmentsPerCourse: [String]) {
        classNameAndAssignments.updateValue(assignmentsPerCourse.arrayWithoutFirstElement(), forKey: assignmentsPerCourse.first ?? "no name")
        newClassNameAndAssignments.updateValue(newAssignmentsPerCourse.arrayWithoutFirstElement(), forKey: newAssignmentsPerCourse.first ?? "no name")
    }

    func showInfo() {
        if assignmentsPerCourse.count != 0 {
            for i in 0 ... assignmentsPerCourse.count - 1 {
                if assignmentsPerCourse[i].first != nil {
                    Database.database().reference().child("users").child((Auth.auth().currentUser?.uid) ?? "").child("Added Assignments").observeSingleEvent(of: .value, with: { [self] snapshot in
                        let encodedClass = "%EF%A3%BF\(self.assignmentsPerCourse[i].first!.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)%EF%A3%BF"
                        // print("ENCODEDEDE", encodedClass)
                        if snapshot.exists() {
                            if snapshot.hasChild(encodedClass) {
                                print("CLASS", encodedClass)
                                self.getClassesFromFirebase(assignmentsAndDueDate: snapshot.childSnapshot(forPath: encodedClass).value as! [String], assignmentsPerCourse: self.assignmentsPerCourse[i], newAsignmentsPerCourse: self.newAssignmentsPerCourse[i], className: self.assignmentsPerCourse[i].first!, classInClassroom: true)

                            } else {
                                for classNum in 0 ... snapshot.children.allObjects.count - 1 {
                                    let className = ("\(snapshot.children.allObjects[classNum])".removingPercentEncoding!.slice(from: "(", to: ")")!)

                                    let classNameWithDivider = "\(className)"

                                    if !self.classes.contains(className) {
                                        if self.classNameAndAssignments[className] == nil {
                                            self.getClassesFromFirebase(assignmentsAndDueDate: snapshot.childSnapshot(forPath: classNameWithDivider.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!).value as! [String], assignmentsPerCourse: self.assignmentsPerCourse[i], newAsignmentsPerCourse: self.newAssignmentsPerCourse[i], className: className, classInClassroom: false)
                                        }
                                    }
                                }

                                if self.classNameAndAssignments[self.assignmentsPerCourse[i].first!] == nil {
                                    self.classroomOnlyFetch(assignmentsPerCourse: self.assignmentsPerCourse[i], newAssignmentsPerCourse: self.newAssignmentsPerCourse[i])
                                }
                            }

                            if i >= self.assignmentsPerCourse.count - 1 {
                                self.finishedGettingInfo()
                            }

                        } else {
                            self.classroomOnlyFetch(assignmentsPerCourse: self.assignmentsPerCourse[i], newAssignmentsPerCourse: self.newAssignmentsPerCourse[i])

                            if i >= self.assignmentsPerCourse.count - 1 {
                                self.finishedGettingInfo()
                            }
                        }
                    })
                }
            }

        } else {
            let alert = UIAlertController(title: "Unable to Show Info", message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            present(alert, animated: true)
        }
    }
}
