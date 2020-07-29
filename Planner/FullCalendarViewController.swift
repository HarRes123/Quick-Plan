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

    override func viewWillAppear(_: Bool) {
        calendarView.select(dateFormatter.date(from: getViewedDate()))
        dateSelected = false
    }

    func calendar(_: FSCalendar, didSelect date: Date, at _: FSCalendarMonthPosition) {
        let formattedString = dateFormatter.string(from: date)
        let formattedDate = dateFormatter.date(from: formattedString)!

        let currentDate = Date()
        globalVariables.daysFromToday = Int(Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: currentDate), to: Calendar.current.startOfDay(for: formattedDate)).day!)

        print("DATE:", dateFormatter.string(from: date), "Difference:", globalVariables.daysFromToday)
        dateSelected = true
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

    @IBAction func dismissButton(_: Any) {
        dismiss(animated: true, completion: nil)
    }

    override func viewDidDisappear(_: Bool) {
        if isBeingDismissed, dateSelected {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "calendarDismissed"), object: nil)
        }
    }
}
