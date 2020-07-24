//
//  FUICustomAuthPickerViewController.swift
//  Planner
//
//  Created by Harrison Resnick on 7/23/20.
//  Copyright © 2020 Harrison Resnick. All rights reserved.
//

import UIKit
import FirebaseUI

class FUIAuthCustomPickerViewController: FUIAuthPickerViewController {
    
    let imageViewBackground = UIImageView()
    let logoImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 250, height: 250))

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?, authUI: FUIAuth?) {
            super.init(nibName: nil, bundle: Bundle.main, authUI: authUI!)
        }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            imageViewBackground.backgroundColor = .systemBackground
        } else {
            imageViewBackground.backgroundColor = .customGray
        }
        let logoImage = UIImage(named: "app_logo.png")
        
        logoImageView.image = logoImage
        
        view.insertSubview(imageViewBackground, at: 0)
        imageViewBackground.insertSubview(logoImageView, at: 0)
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        imageViewBackground.frame = view.frame
        logoImageView.center.x = view.center.x
        logoImageView.center.y =  view.frame.size.height/4
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if size.width != view.frame.size.width {

            DispatchQueue.main.async {
                self.imageViewBackground.frame = self.view.frame
                self.logoImageView.center.x = self.view.center.x
                self.logoImageView.center.y = self.view.frame.size.height/4
            }
        }
    }

        override func viewDidDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            navigationController?.setNavigationBarHidden(false, animated: animated)
        }
    }
