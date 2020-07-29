//
//  FullCalendarViewController.swift
//  Planner
//
//  Created by Harrison Resnick on 7/29/20.
//  Copyright © 2020 Harrison Resnick. All rights reserved.
//

import UIKit
import FSCalendar

class FullCalendarViewController: UIViewController, FSCalendarDataSource, FSCalendarDelegate {
    
    @IBOutlet var navBar: UINavigationBar!
    @IBOutlet weak var calendarView: FSCalendar!
    @IBOutlet var dismissButton: UIBarButtonItem!
    
    let dateFormatter = DateFormatter()
    
    func desiredFont(pointSize: CGFloat) -> UIFont {
    
        return UIFont(name: "AvenirNext-Regular", size: pointSize)!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        calendarView.appearance.titleFont = desiredFont(pointSize: calendarView.appearance.titleFont.pointSize)
        calendarView.appearance.weekdayFont = desiredFont(pointSize: calendarView.appearance.weekdayFont.pointSize)
        calendarView.appearance.subtitleFont = desiredFont(pointSize: calendarView.appearance.subtitleFont.pointSize)
        calendarView.appearance.headerTitleFont = desiredFont(pointSize: calendarView.appearance.headerTitleFont.pointSize)
        
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = .current
        dateFormatter.dateFormat = "MM/dd/yyyy"
        navBar.titleTextAttributes = [NSAttributedString.Key.font: desiredFont(pointSize: 20)]
        UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedString.Key.font: desiredFont(pointSize: 17)], for: .normal)
                        
        if UIDevice.current.userInterfaceIdiom == .pad {
            navBar.isUserInteractionEnabled = false
            navBar.isHidden = true
            calendarView.topAnchor.constraint(equalTo: navBar.bottomAnchor).isActive = false
            calendarView.topAnchor.constraint(equalTo: navBar.bottomAnchor, constant: -navBar.frame.height).isActive = true

        } else {
            navBar.isUserInteractionEnabled = true
            navBar.isHidden = false
            calendarView.topAnchor.constraint(equalTo: navBar.bottomAnchor).isActive = true
            calendarView.topAnchor.constraint(equalTo: navBar.bottomAnchor, constant: -navBar.frame.height).isActive = false
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        calendarView.select(dateFormatter.date(from: getViewedDate()))
    }
    
    
    
    
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        
        
        let formattedString = dateFormatter.string(from: date)
        let formattedDate = dateFormatter.date(from: formattedString)!
        
        let currentDate = Date()
        globalVariables.daysFromToday = Int(Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: currentDate), to: Calendar.current.startOfDay(for: formattedDate)).day!)
        
        print("DATE:", dateFormatter.string(from: date), "Difference:", globalVariables.daysFromToday)
        
    }
    
    override func traitCollectionDidChange(_: UITraitCollection?) {
        if traitCollection.userInterfaceStyle == .light {
            calendarView.backgroundColor = .customGray
            view.backgroundColor = .customGray
            dismissButton.tintColor = .darkGray
            calendarView.appearance.weekdayTextColor = .black
            calendarView.appearance.headerTitleColor = .black
            calendarView.appearance.titleDefaultColor = .darkGray
           

        } else {
            calendarView.backgroundColor = .darkGray
            view.backgroundColor = .darkGray
            dismissButton.tintColor = .customGray
            
            calendarView.appearance.weekdayTextColor = .white
            calendarView.appearance.headerTitleColor = .white
            calendarView.appearance.titleDefaultColor = .customGray
        }
    }
    
    @IBAction func dismissButton(_: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidDisappear(_: Bool) {
        if isBeingDismissed {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "calendarDismissed"), object: nil)
        }
    }

}
