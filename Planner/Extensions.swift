//
//  Extensions.swift
//  Planner
//
//  Created by Harrison Resnick on 6/13/20.
//  Copyright © 2020 Harrison Resnick. All rights reserved.
//

import FirebaseUI
import Foundation

extension Array {
    func arrayWithoutFirstElement() -> Array {
        if count != 0 { // Check if Array is empty to prevent crash
            var newArray = Array(self)
            newArray.removeFirst()
            return newArray
        }
        return []
    }
}

extension UITableViewCell: UITextViewDelegate {
    public func textViewDidChange(_ textView: UITextView) {
        let size = textView.bounds.size
        let newSize = textView.sizeThatFits(CGSize(width: size.width, height: CGFloat.greatestFiniteMagnitude))
        
        // Resize the cell only when cell's size is changed
        if size.height != newSize.height {
            UIView.setAnimationsEnabled(false)
            tableView?.beginUpdates()
            tableView?.endUpdates()
            UIView.setAnimationsEnabled(true)
            
            if let thisIndexPath = tableView?.indexPath(for: self) {
                tableView?.scrollToRow(at: thisIndexPath, at: .bottom, animated: false)
            }
        }
    }
}

extension UITableViewCell {
    /// Search up the view hierarchy of the table view cell to find the containing table view
    var tableView: UITableView? {
        var table: UIView? = superview
        while !(table is UITableView), table != nil {
            table = table?.superview
        }
        
        return table as? UITableView
    }
}

extension Date {
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    func getDate(dayDifference: Int) -> Date {
        var components = DateComponents()
        components.day = dayDifference
        return Calendar.current.date(byAdding: components, to: startOfDay)!
    }
}

extension UIColor {
    convenience init(hexFromString: String, alpha: CGFloat = 1.0) {
        var cString: String = hexFromString.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        var rgbValue: UInt32 = 10_066_329 // color #999999 if string has wrong format
        
        if cString.hasPrefix("#") {
            cString.remove(at: cString.startIndex)
        }
        
        if cString.count == 6 {
            Scanner(string: cString).scanHexInt32(&rgbValue)
        }
        
        self.init(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: alpha
        )
    }
}

extension UINavigationBar {
    func transparentNavigationBar() {
        setBackgroundImage(UIImage(), for: .default)
        shadowImage = UIImage()
        isTranslucent = true
    }
}

extension SignInViewController {
    func authUI(_: FUIAuth, didSignInWith _: AuthDataResult?, error: Error?) {
        // Check for error
        guard error == nil else {
            return
        }
        var title = ""
        var messege = ""
        
        // Transition to home
        
        if Auth.auth().currentUser!.isEmailVerified == true {
            print("VERIFIED")
            performSegue(withIdentifier: "goHome", sender: self)
        } else {
            print("NOT VERIFIED")
            title = "Verify Account"
            messege = "Please check you email and verify your account"
            let alert = UIAlertController(title: title, message: messege, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            Auth.auth().currentUser?.sendEmailVerification { _ in
                // ...
            }
            present(alert, animated: true)
        }
    }
}

extension Float {
    var clean: String {
        return truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(self)
    }
}

extension NSMutableAttributedString {
    func setColorForText(textForAttribute: String, withColor color: UIColor) {
        let range: NSRange = mutableString.range(of: textForAttribute, options: .caseInsensitive)
        
        // Swift 4.2 and above
        addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: range)
    }
}

var vSpinner: UIView?
extension UIViewController {
    func showSpinner(onView: UIView) {
        let spinnerView = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        
        let ai = UIActivityIndicatorView(style: .whiteLarge)
        ai.startAnimating()
        ai.center = onView.center
        
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        blurEffectView.alpha = 0.75
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        spinnerView.addSubview(blurEffectView)
        
        DispatchQueue.main.async {
            spinnerView.addSubview(ai)
            onView.addSubview(spinnerView)
        }
        
        vSpinner = spinnerView
    }
    
    func removeSpinner() {
        DispatchQueue.main.async {
            vSpinner?.removeFromSuperview()
            vSpinner = nil
        }
    }
}
