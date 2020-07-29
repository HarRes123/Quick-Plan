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
    
    var differentDay = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = .current
        dateFormatter.dateFormat = "MM/dd/yyyy"
        
        let formattedString = dateFormatter.string(from: date)
        let formattedDate = dateFormatter.date(from: formattedString)!
        
        let currentDate = Date()
        globalVariables.daysFromToday = Int(Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: currentDate), to: Calendar.current.startOfDay(for: formattedDate)).day!)
        
        print("DATE:", dateFormatter.string(from: date), "Difference:", globalVariables.daysFromToday)
        
        if globalVariables.daysFromToday != 0 {
            differentDay = true
            
        } else {
            differentDay = false
        }
    }
    
    override func viewDidDisappear(_: Bool) {
        if isBeingDismissed {
          //  if differentDay {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "calendarDismissed"), object: nil)
            //}
        }
    }
    //daysFromToday

}
