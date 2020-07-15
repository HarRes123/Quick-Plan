//
//  ManualEntryViewController.swift
//  Planner
//
//  Created by Harrison Resnick on 7/12/20.
//  Copyright © 2020 Harrison Resnick. All rights reserved.
//

import UIKit
import Firebase

class ManualEntryViewController: UIViewController, UIScrollViewDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackView: UIStackView!
    
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var question1Label: UILabel!
    @IBOutlet weak var question2Label: UILabel!
    @IBOutlet weak var question3Label: UILabel!
    @IBOutlet weak var assignmentField: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var classPicker: DropDown!
    @IBOutlet weak var dueDateField: UITextField!
    @IBOutlet weak var dateError: UILabel!
    @IBOutlet weak var dummyView: UIView!
    
    var refResponse: DatabaseReference!
    
    var classNames = Array<String>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.delegate = self
        assignmentField.delegate = self
        dueDateField.delegate = self
        classPicker.optionArray = classNames + ["Add Class"]
        dateError.text = "Please enter a valid date"
        dateError.isHidden = true
                
        question1Label.text = "What is the name of the class?"
        question2Label.text = "What is the name of the assignment?"
        question3Label.text = "When is the assignment due?"
        
        stackView.setCustomSpacing(12, after: question1Label)
        stackView.setCustomSpacing(64, after: classPicker)
        stackView.setCustomSpacing(12, after: question2Label)
        stackView.setCustomSpacing(64, after: assignmentField)
        stackView.setCustomSpacing(12, after: question3Label)
        stackView.setCustomSpacing(64, after: dueDateField)
        stackView.setCustomSpacing(64 - (dateError.frame.height + 5), after: dateError)
        
        refResponse = Database.database().reference().child("users")
        
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            navBar.isUserInteractionEnabled = false
            navBar.isHidden = true
            stackView.setCustomSpacing(0, after: dummyView)
        } else {
            navBar.isUserInteractionEnabled = true
            navBar.isHidden = false
            stackView.setCustomSpacing(28, after: dummyView)
        }
        
        // The the Closure returns Selected Index and String
        classPicker.didSelect{(selectedText , index ,_) in
            if selectedText == "Add Class" {
                print("USER WANTS TO ADD A CLASS")
                let alertController = UIAlertController(title: "Add Class", message: "", preferredStyle: UIAlertController.Style.alert)
                alertController.addTextField { (textField : UITextField!) -> Void in
                    textField.placeholder = "Enter class name"
                }
                let saveAction = UIAlertAction(title: "Save", style: UIAlertAction.Style.default, handler: { alert -> Void in
                    
                    let textField = alertController.textFields![0] as UITextField
                    if textField.text != "" {
                        self.classPicker.text = textField.text ?? "Add Class"
                        self.classNames.append(textField.text ?? "Add Class")
                        self.classPicker.optionArray = self.classNames + ["Add Class"]
                    }
                    
                })
                let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default, handler: {
                                                    (action : UIAlertAction!) -> Void in })
                
                
                alertController.addAction(cancelAction)
                alertController.addAction(saveAction)
                
                
                self.present(alertController, animated: true, completion: nil)
            }
            print("Selected String: \(selectedText) \n index: \(index)")
        }
        
        self.setUpButton(button: saveButton)
        view.backgroundColor = UIColor(hexFromString: "E8E8E8")
        self.scrollView.addSubview(stackView)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        self.hideKeyboardWhenTappedAround()
        // selectClass.titleLabel?.font = UIFont(name: "AvenirNext-Regular", size: (selectClass.titleLabel?.font.pointSize)!)
        UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedString.Key.font : UIFont(name: "AvenirNext-Regular", size: 17)!],for: .normal)
        navBar.titleTextAttributes = [NSAttributedString.Key.font: UIFont(name: "AvenirNext-Regular", size: 20)!]
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    func checkValidDate(date: String) -> Bool {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "mm/dd/yyyy"
        
        let splitDate = date.components(separatedBy: "/")
        if Int(splitDate[0]) ?? 100 <= 12 && Int(splitDate[1]) ?? 100 <= 31 && dateFormatter.date(from: date) != nil {
            return true
        } else {
            return false
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if textField == dueDateField {
            
            let newCharacters = CharacterSet(charactersIn: string)
            
            // check the chars length dd -->2 at the same time dueDateField the dd-MM --> 5
            if (dueDateField?.text?.count == 2) || (dueDateField?.text?.count == 5) {
                //Handle backspace being pressed
                if string != "" && NSCharacterSet.decimalDigits.isSuperset(of: newCharacters) {
                    // append the text
                    dueDateField?.text = (dueDateField?.text)! + "/"
                }
            }
            // check the condition not exceed 9 chars
            print("COUNT:", textField.text!.count)
            if textField.text!.count == 9 {
                if checkValidDate(date: textField.text!) {
                    print("VALID DATE")
                    dateError.isHidden = true
                    stackView.setCustomSpacing(64, after: dueDateField)
                } else {
                    print("NOT VALID DATE")
                    dateError.isHidden = false
                    stackView.setCustomSpacing(5, after: dueDateField)
                }
            }
            
            
            return !(textField.text!.count > 9 && (string.count ) > range.length) && NSCharacterSet.decimalDigits.isSuperset(of: newCharacters)
        }
        else {
            
            return true
            
        }
        
    }
    
    override func viewDidLayoutSubviews() {
        
        self.stackView.translatesAutoresizingMaskIntoConstraints = true
        
        self.stackView.leadingAnchor.constraint(equalTo: self.scrollView.leadingAnchor).isActive = true
        self.stackView.trailingAnchor.constraint(equalTo: self.scrollView.trailingAnchor).isActive = true
        self.stackView.topAnchor.constraint(equalTo: self.scrollView.topAnchor).isActive = true
        self.stackView.bottomAnchor.constraint(equalTo: self.scrollView.bottomAnchor).isActive = true
        
        stackView.center.x = scrollView.center.x
        stackView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: stackView.frame.height)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.x != 0 {
            scrollView.contentOffset.x = 0
        }
    }
    
    @IBAction func dismissButton(_ sender: Any) {
        
        self.dismiss(animated: true, completion: nil)
        
    }
    override func viewDidDisappear(_ animated: Bool) {
        if isBeingDismissed {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "popOverDismissed"), object: nil)
        }
    }
    
    
    func sendAlert(title: String) {
        let alert = UIAlertController(title: title, message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: true)
    }
    
    @IBAction func savePressed(_ sender: Any)  {
        
        let selectedClass = classPicker.text ?? "no text"
        let selectedAssignment = assignmentField.text ?? "no text"
        var selectedDueDate = dueDateField.text ?? "no text"
        guard let encodedClass = selectedClass.addingPercentEncoding(withAllowedCharacters: .alphanumerics) else { return  }
        guard let decodedClass = selectedClass.removingPercentEncoding else { return }
        
        if encodedClass != "no text" && selectedAssignment != "no text" && checkValidDate(date: selectedDueDate) {
            
            if selectedDueDate.first == "0" {
                selectedDueDate = String(selectedDueDate.dropFirst())
            }
            
            let assignmentAndDueDate = "\(selectedAssignment)\n\nDue: \(selectedDueDate)"
            
            Database.database().reference().child("users").child((Auth.auth().currentUser?.uid) ?? "").child("Added Assignments").child(encodedClass).observeSingleEvent(of: .value, with: { snapshot in
                if snapshot.exists() {
                    
                    var allData = snapshot.value! as! Array<String>
                    
                    if !allData.contains(assignmentAndDueDate) {
                        allData.append(assignmentAndDueDate)
                        self.sendAlert(title: "Assignment Saved")
                    } else {
                        self.sendAlert(title: "Assignment Already Exists")
                    }
                    
                    print("SNAP", snapshot.value!)
                    
                    self.refResponse.child((Auth.auth().currentUser?.uid)!).child("Added Assignments").child(encodedClass).setValue(allData)
                    
                } else {
                    
                    self.refResponse.child((Auth.auth().currentUser?.uid)!).child("Added Assignments").child(encodedClass).setValue([assignmentAndDueDate])
                    self.sendAlert(title: "Assignment Saved")
                    
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
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
    
}

