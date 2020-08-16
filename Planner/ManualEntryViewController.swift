//
//  ManualEntryViewController.swift
//  Planner
//
//  Created by Harrison Resnick on 7/12/20.
//  Copyright © 2020 Harrison Resnick. All rights reserved.
//

import Firebase
import UIKit

class ManualEntryViewController: UIViewController, UIScrollViewDelegate, UITextFieldDelegate {
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var stackView: UIStackView!

    @IBOutlet var navBar: UINavigationBar!
    @IBOutlet var question1Label: UILabel!
    @IBOutlet var question2Label: UILabel!
    @IBOutlet var question3Label: UILabel!
    @IBOutlet var assignmentField: UITextField!
    @IBOutlet var saveButton: UIButton!
    @IBOutlet var classPicker: DropDown!
    @IBOutlet var dueDateField: UITextField!
    @IBOutlet var dummyView: UIView!
    @IBOutlet var dismissButton: UIBarButtonItem!
    var savePressed = false

    var refResponse: DatabaseReference!

    var classNames = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()

        scrollView.delegate = self
        assignmentField.delegate = self
        dueDateField.delegate = self
        classPicker.optionArray = classNames + ["Add Class"]
        question1Label.text = "What is the name of the class?"
        question2Label.text = "What is the name of the assignment?"
        question3Label.text = "When is the assignment due?"
        // dueDateField.inputView = assignmentField.inputView
        stackView.setCustomSpacing(35, after: dummyView)
        stackView.setCustomSpacing(12, after: question1Label)
        stackView.setCustomSpacing(64, after: classPicker)
        stackView.setCustomSpacing(12, after: question2Label)
        stackView.setCustomSpacing(64, after: assignmentField)
        stackView.setCustomSpacing(12, after: question3Label)
        stackView.setCustomSpacing(64, after: dueDateField)

        NotificationCenter.default.addObserver(self, selector: #selector(calendarFromManualEntryDismissed), name: Notification.Name("calendarFromManualEntryDismissed"), object: nil)

        refResponse = Database.database().reference().child("users")

        classPicker.didSelect { selectedText, index, _ in
            if selectedText == "Add Class" {
                print("USER WANTS TO ADD A CLASS")
                let alertController = UIAlertController(title: "Add Class", message: "", preferredStyle: UIAlertController.Style.alert)
                alertController.addTextField { (textField: UITextField!) -> Void in
                    textField.placeholder = "Enter class name"
                }
                let saveAction = UIAlertAction(title: "Save", style: UIAlertAction.Style.default, handler: { _ -> Void in

                    let textField = alertController.textFields![0] as UITextField
                    if textField.text != "" {
                        self.classPicker.text = textField.text ?? "Add Class"
                        self.classNames.append(textField.text ?? "Add Class")
                        self.classPicker.optionArray = self.classNames + ["Add Class"]
                    }

                })
                let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default, handler: {
                    (_: UIAlertAction!) -> Void in
                })

                alertController.addAction(cancelAction)
                alertController.addAction(saveAction)

                self.present(alertController, animated: true, completion: nil)
            }
            print("Selected String: \(selectedText) \n index: \(index)")
        }

        scrollView.addSubview(stackView)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        hideKeyboardWhenTappedAround()
        // selectClass.titleLabel?.font = UIFont(name: "AvenirNext-Regular", size: (selectClass.titleLabel?.font.pointSize)!)
        
        navBar.titleTextAttributes = [NSAttributedString.Key.font: UIFont(name: "AvenirNext-Regular", size: 18)!]
        navBar.shadowImage = UIImage()
    }

    func textFieldShouldReturn(_: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }

    @objc func calendarFromManualEntryDismissed() {
        print("CALLED")

        if globalVariables.dueDate.first == "0" {
            globalVariables.dueDate = String(globalVariables.dueDate.dropFirst())
        }

        dueDateField.text = globalVariables.dueDate
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == dueDateField {
            let calVC = FullCalendarViewController(nibName: "FullCalendarViewController", bundle: nil)
            calVC.modalPresentationStyle = .popover
            calVC.rootIsMainViewContoller = false
            let popover: UIPopoverPresentationController = calVC.popoverPresentationController!
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.center.x, y: view.center.y, width: 0, height: 0)
            popover.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)

            present(calVC, animated: true, completion: nil)
            return false
        }
        return true
    }

    override func traitCollectionDidChange(_: UITraitCollection?) {
        setUpButton(button: saveButton, darkTint: UIColor.black.cgColor)
        if traitCollection.userInterfaceStyle == .light {
            view.backgroundColor = .customGray
            dismissButton.tintColor = .darkGray
            classPicker.attributedPlaceholder = NSAttributedString(string: classPicker.placeholder!, attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray])
            assignmentField.attributedPlaceholder = NSAttributedString(string: assignmentField.placeholder!, attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray])
            dueDateField.attributedPlaceholder = NSAttributedString(string: dueDateField.placeholder!, attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray])

        } else {
            view.backgroundColor = .darkGray
            dismissButton.tintColor = .customGray
            classPicker.attributedPlaceholder = NSAttributedString(string: classPicker.placeholder!, attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
            assignmentField.attributedPlaceholder = NSAttributedString(string: assignmentField.placeholder!, attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
            dueDateField.attributedPlaceholder = NSAttributedString(string: dueDateField.placeholder!, attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        }
    }
    
    override func viewDidLayoutSubviews() {
        stackView.translatesAutoresizingMaskIntoConstraints = false

        stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
        stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true
        stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
        stackView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
        
        question1Label.bounds.size.height = 28
        question2Label.bounds.size.height = 28
        question3Label.bounds.size.height = 28
        print(question1Label.frame.height)

        stackView.center.x = scrollView.center.x
        stackView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: stackView.frame.height)
    
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.x != 0 {
            scrollView.contentOffset.x = 0
        }
    }

    @IBAction func dismissButton(_: Any) {
        dismiss(animated: true, completion: nil)
    }

    override func viewDidDisappear(_: Bool) {
        if isBeingDismissed {
            if savePressed {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "manualEntryDismissed"), object: nil)
            }
        }
    }

    func sendAlert(title: String) {
        let alert = UIAlertController(title: title, message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alert, animated: true)
    }

    func saveSuccessful() {
        classPicker.text = ""
        assignmentField.text = ""
        dueDateField.text = ""
    }

    @IBAction func savePressed(_: Any) {
        let selectedClass = "\(classPicker.text ?? "no text")"
        let selectedAssignment = assignmentField.text ?? "no text"
        var selectedDueDate = globalVariables.dueDate
        guard let encodedClass = selectedClass.addingPercentEncoding(withAllowedCharacters: .alphanumerics) else { return }
        guard let decodedClass = selectedClass.removingPercentEncoding else { return }

        if classPicker.text != "", assignmentField.text != "", dueDateField.text != "" {
            if selectedDueDate.first == "0" {
                selectedDueDate = String(selectedDueDate.dropFirst())
            }

            let assignmentAndDueDate = "\(selectedAssignment)\n\nDue: \(selectedDueDate)"

            Database.database().reference().child("users").child((Auth.auth().currentUser?.uid) ?? "").child("Added Assignments").child(encodedClass).observeSingleEvent(of: .value, with: { snapshot in
                if snapshot.exists() {
                    var allData = snapshot.value! as! [String]

                    if !allData.contains(assignmentAndDueDate) {
                        allData.append(assignmentAndDueDate)
                        self.sendAlert(title: "Assignment Saved")
                        self.savePressed = true
                        self.saveSuccessful()
                    } else {
                        self.sendAlert(title: "Assignment Already Exists")
                    }

                    print("SNAP", snapshot.value!)

                    self.refResponse.child((Auth.auth().currentUser?.uid)!).child("Added Assignments").child(encodedClass).setValue(allData)

                } else {
                    self.refResponse.child((Auth.auth().currentUser?.uid)!).child("Added Assignments").child(encodedClass).setValue([assignmentAndDueDate])
                    self.sendAlert(title: "Assignment Saved")
                    self.savePressed = true
                    self.saveSuccessful()
                }
            })

            // self.refResponse.child((Auth.auth().currentUser?.uid)!).child(selectedClass).setValue(assignmentAndDueDate)
        } else {
            sendAlert(title: "Please Answer Each Question")
        }

        print("ACTUAL NAME", decodedClass)
    }

    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if view.frame.origin.y == 0 {
                view.frame.origin.y -= keyboardSize.height * (5 / 8)
            }
        }
    }

    @objc func keyboardWillHide(notification _: NSNotification) {
        if view.frame.origin.y != 0 {
            view.frame.origin.y = 0
        }
    }
}
