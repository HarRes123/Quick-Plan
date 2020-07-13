//
//  ManualEntryViewController.swift
//  Planner
//
//  Created by Harrison Resnick on 7/12/20.
//  Copyright © 2020 Harrison Resnick. All rights reserved.
//

import UIKit

class ManualEntryViewController: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var dropDownStackView: UIStackView!
    @IBOutlet weak var selectClass: UIButton!
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var question1Label: PaddingLabel!
    @IBOutlet weak var question2Label: UILabel!
    @IBOutlet weak var question3Label: UILabel!
    var classesCollection = Array<UIButton>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.delegate = self
        
        self.scrollView.addSubview(stackView)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        self.hideKeyboardWhenTappedAround()
        selectClass.titleLabel?.font = UIFont(name: "AvenirNext-Regular", size: (selectClass.titleLabel?.font.pointSize)!)
        UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedString.Key.font : UIFont(name: "AvenirNext-Regular", size: 17)!],for: .normal)
        navBar.titleTextAttributes = [NSAttributedString.Key.font: UIFont(name: "AvenirNext-Regular", size: 20)!]
        selectClass.layer.cornerRadius = 15

        
        if Global.classNames.count != 0 {
            for name in Global.classNames {
                let button = UIButton()
                button.setTitleColor(.black, for: .normal)
                button.backgroundColor = UIColor(hexFromString: "5FD7EC")
                button.setTitle(name, for: .normal)
                button.titleLabel?.font = UIFont(name: "AvenirNext-Regular", size: (selectClass.titleLabel?.font.pointSize)!)
                button.heightAnchor.constraint(equalToConstant: selectClass.frame.height).isActive = true
                button.addTarget(self, action: #selector(classPressed(sender:)), for: .touchUpInside)
                button.layer.cornerRadius = 15
                button.isHidden = true
                button.alpha = 0
                classesCollection.append(button)
                dropDownStackView.addArrangedSubview(button)
                
            }
        } else {
            print("NO CLASSES FOUND")
        }
        
    }
    
    @objc func classPressed(sender: UIButton) {
        if let buttonLabel = sender.titleLabel?.text {
            print(buttonLabel)
        }
    }
    
    @IBAction func selectClassButton(_ sender: Any) {
        classesCollection.forEach { (button) in
            UIView.animate(withDuration: 0.3) {
                button.isHidden  = !button.isHidden
                button.alpha = button.alpha == 0 ? 1 : 0
                button.layoutIfNeeded()
            }
        }
        
    }
    
    override func viewDidLayoutSubviews() {
        
        self.stackView.translatesAutoresizingMaskIntoConstraints = false
        
        self.stackView.leadingAnchor.constraint(equalTo: self.scrollView.leadingAnchor).isActive = true
        self.stackView.trailingAnchor.constraint(equalTo: self.scrollView.trailingAnchor).isActive = true
        self.stackView.topAnchor.constraint(equalTo: self.scrollView.topAnchor).isActive = true
        self.stackView.bottomAnchor.constraint(equalTo: self.scrollView.bottomAnchor).isActive = true
        question1Label.topInset = navBar.frame.height
        question1Label.width = question2Label.frame.width
        question1Label.bottomInset = question2Label.frame.height/2
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
