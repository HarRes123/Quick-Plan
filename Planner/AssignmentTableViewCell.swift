//
//  AssignmentTableViewCell.swift
//  Planner
//
//  Created by Harrison Resnick on 6/14/20.
//  Copyright © 2020 Harrison Resnick. All rights reserved.
//

import UIKit

class AssignmentTableViewCell: UITableViewCell {
    
    @IBOutlet weak var classTitle: UILabel!
    @IBOutlet weak var classAssignments: UILabel!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        classTitle.numberOfLines = 0
        classAssignments.numberOfLines = 0

      //  updateLabelFrame()

    }
    
    func updateLabelFrame() {
        
        let maxSizeTitle = CGSize(width: 154, height: 50)
        let maxSizeAssignment = CGSize(width: 154, height: 500)
        
        let sizeTitle = classTitle.sizeThatFits(maxSizeTitle)
        classTitle.frame = CGRect(origin: CGPoint(x: 10, y: 25), size: sizeTitle)
        
        let sizeAssignment = classAssignments.sizeThatFits(maxSizeAssignment)
        classAssignments.frame = CGRect(origin: CGPoint(x: 10, y: 100), size: sizeAssignment)
        
        classTitle.numberOfLines = 10
        classAssignments.numberOfLines = 500



    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
