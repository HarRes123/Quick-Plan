//
//  CalendarTableViewCell.swift
//  Planner
//
//  Created by Harrison Resnick on 6/16/20.
//  Copyright © 2020 Harrison Resnick. All rights reserved.
//

import UIKit

class CalendarTableViewCell: UITableViewCell {

    @IBOutlet weak var calendarEventText: UITextView!
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
        }
           
        required init?(coder aDecoder: NSCoder) {
               super.init(coder: aDecoder)
           }
        
        var textString: String {
            get {
                return calendarEventText.text
            }
            set {
                calendarEventText.text = newValue
                
                textViewDidChange(calendarEventText)
            }
        }
        

        override func awakeFromNib() {
            super.awakeFromNib()
            // Initialization code
            
            calendarEventText.isScrollEnabled = false
            calendarEventText.delegate = self
            calendarEventText.textContainer.lineBreakMode = .byWordWrapping
            
    //        classAssignments.numberOfLines = 10
           

          //  updateLabelFrame()

        }

        override func setSelected(_ selected: Bool, animated: Bool) {
            super.setSelected(selected, animated: animated)
            if selected {
                calendarEventText.becomeFirstResponder()
            } else {
                calendarEventText.resignFirstResponder()
            }
            // Configure the view for the selected state
        }
        
    }
