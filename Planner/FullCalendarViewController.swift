//
//  FullCalendarViewController.swift
//  Planner
//
//  Created by Harrison Resnick on 7/29/20.
//  Copyright © 2020 Harrison Resnick. All rights reserved.
//

import FSCalendar
import UIKit

class FullCalendarViewController: UIViewController, FSCalendarDataSource, FSCalendarDelegate {
    @IBOutlet var navBar: UINavigationBar!
    @IBOutlet var calendarView: FSCalendar!
    @IBOutlet var dismissButton: UIBarButtonItem!
    var dateSelected = false
    var rootIsMainViewContoller = Bool()
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

        calendarView.appearance.selectionColor = .customOrange
        calendarView.appearance.todayColor = .customBlue

        globalVariables.dueDate = "No Due Date"

        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = .current
        dateFormatter.dateFormat = "MM/dd/yyyy"
        navBar.titleTextAttributes = [NSAttributedString.Key.font: desiredFont(pointSize: 18)]
        UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedString.Key.font: desiredFont(pointSize: 17)], for: .normal)
        navBar.shadowImage = UIImage()
    }

    override func viewDidAppear(_: Bool) {
        let dateToShow = dateFormatter.date(from: getViewedDate())

        if rootIsMainViewContoller {
            // parentVC is someViewController
            calendarView.select(dateToShow)
        } else {
            calendarView.select(Date())
        }

        dateSelected = false
    }

    func dateChanged(date: Date) {
        let formattedString = dateFormatter.string(from: date)
        let formattedDate = dateFormatter.date(from: formattedString)!

        let currentDate = Date()

        // presented by parent view controller 1
        if rootIsMainViewContoller {
            print("YESYSYSYS")
            // parentVC is someViewController
            globalVariables.daysFromToday = Int(Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: currentDate), to: Calendar.current.startOfDay(for: formattedDate)).day!)

            print("DATE:", dateFormatter.string(from: date), "Difference:", globalVariables.daysFromToday)
        } else {
            globalVariables.dueDate = formattedString
        }
        dateSelected = true
    }

    func calendar(_: FSCalendar, didSelect date: Date, at _: FSCalendarMonthPosition) {
        dateChanged(date: date)
    }

    override func traitCollectionDidChange(_: UITraitCollection?) {
        if traitCollection.userInterfaceStyle == .light {
            calendarView.backgroundColor = .customGray
            view.backgroundColor = .customGray
            dismissButton.tintColor = .darkGray
            calendarView.appearance.weekdayTextColor = .black
            calendarView.appearance.headerTitleColor = .black
            calendarView.appearance.titleDefaultColor = .darkGray
            calendarView.appearance.titleTodayColor = .white
            calendarView.appearance.titleSelectionColor = .white
        } else {
            calendarView.backgroundColor = .darkGray
            view.backgroundColor = .darkGray
            dismissButton.tintColor = .customGray
            calendarView.appearance.weekdayTextColor = .white
            calendarView.appearance.headerTitleColor = .white
            calendarView.appearance.titleDefaultColor = .customGray
            calendarView.appearance.titleTodayColor = .black
            calendarView.appearance.titleSelectionColor = .black
        }
    }

    override func willTransition(to _: UITraitCollection, with _: UIViewControllerTransitionCoordinator) {
        calendarView.reloadData()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if size.width != view.frame.size.width {
            DispatchQueue.main.async {
                self.calendarView.reloadData()
            }
        }
    }

    @IBAction func dismissButton(_: Any) {
        dismiss(animated: true, completion: nil)
    }


    @IBAction func todayButton(_: Any) {
        calendarView.select(Date())
        dateChanged(date: Date())
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if isBeingDismissed {
            if !rootIsMainViewContoller {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "calendarFromManualEntryDismissed"), object: nil)
            }
        }
    }

    override func viewDidDisappear(_: Bool) {
        if isBeingDismissed {
            if rootIsMainViewContoller, dateSelected {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "calendarFromMainDismissed"), object: nil)
            }
        }
    }
}
