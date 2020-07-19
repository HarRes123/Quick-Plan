//
//  AssignmentTableViewCell.swift
//  Planner
//
//  Created by Harrison Resnick on 6/14/20.
//  Copyright © 2020 Harrison Resnick. All rights reserved.
//

import UIKit

class AssignmentTableViewCell: UITableViewCell {
    @IBOutlet var classAssignments: UITextView!

    var textString: String {
        get {
            return classAssignments.text
        }
        set {
            classAssignments.text = newValue

            textViewDidChange(classAssignments)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        classAssignments.isScrollEnabled = false
        classAssignments.delegate = self
        frame = CGRect(x: 0, y: 0, width: 119, height: frame.height)

        //        classAssignments.numberOfLines = 10

        //  updateLabelFrame()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            classAssignments.becomeFirstResponder()
        } else {
            classAssignments.resignFirstResponder()
        }
        // Configure the view for the selected state
    }
}
