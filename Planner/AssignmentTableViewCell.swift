//
//  AssignmentTableViewCell.swift
//  Planner
//
//  Created by Harrison Resnick on 6/14/20.
//  Copyright © 2020 Harrison Resnick. All rights reserved.
//

import UIKit

class AssignmentTableViewCell: UITableViewCell {
    
    @IBOutlet weak var classAssignments: UITextView!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
//        classAssignments.numberOfLines = 10
       

      //  updateLabelFrame()

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
