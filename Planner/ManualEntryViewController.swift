//
//  ManualEntryViewController.swift
//  Planner
//
//  Created by Harrison Resnick on 7/12/20.
//  Copyright © 2020 Harrison Resnick. All rights reserved.
//

import UIKit

class ManualEntryViewController: UIViewController, UIScrollViewDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackView: UIStackView!

    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var question1Label: UILabel!
    @IBOutlet weak var question2Label: UILabel!
    @IBOutlet weak var question3Label: UILabel!
    @IBOutlet weak var assignmentName: UITextField!
    @IBOutlet weak var dueDate: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var classPicker: DropDown!
    
    var classNames = Array<String>()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.delegate = self
        assignmentName.delegate = self
        dueDate.delegate = self
        classPicker.optionArray = classNames + ["Add Class"]
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            navBar.isUserInteractionEnabled = false
            navBar.isHidden = true
        } else {
            navBar.isUserInteractionEnabled = true
            navBar.isHidden = false
        }

        // The the Closure returns Selected Index and String
        classPicker.didSelect{(selectedText , index ,_) in
            if selectedText == "Add Class" {
                print("USER WANTS TO ADD A CLASS")
                let alertController = UIAlertController(title: "Add Class", message: "", preferredStyle: UIAlertController.Style.alert)
                alertController.addTextField { (textField : UITextField!) -> Void in
                       textField.placeholder = "Enter Class Name"
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

