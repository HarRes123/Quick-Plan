//
//  ManualEntryViewController.swift
//  Planner
//
//  Created by Harrison Resnick on 7/12/20.
//  Copyright © 2020 Harrison Resnick. All rights reserved.
//

import UIKit

class ManualEntryViewController: UIViewController {
    @IBOutlet weak var baseView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!

    override func viewDidLoad() {
        super.viewDidLoad()
        


    @IBAction func dismissButton(_ sender: Any) {
        
        self.dismiss(animated: true, completion: nil)

    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
