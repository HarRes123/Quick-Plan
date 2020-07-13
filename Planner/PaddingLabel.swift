//
//  PaddingLabel.swift
//  Planner
//
//  Created by Harrison Resnick on 7/12/20.
//  Copyright © 2020 Harrison Resnick. All rights reserved.
//

class PaddingLabel: UILabel {

    var topInset: CGFloat = 0
    var bottomInset: CGFloat = 0
    var width: CGFloat = 0


    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: topInset, left: 0, bottom: bottomInset, right: 0)
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: width,
                      height: size.height + topInset + bottomInset)
    }
}
