//
//  LaunchScreenView.swift
//  Pointer
//
//  Created by Evgeniy Suprun on 29.02.2020.
//  Copyright © 2020 Pointer. All rights reserved.
//

import UIKit
import FBSDKShareKit
import FBSDKLoginKit
import GoogleSignIn

class LaunchScreenView: UIViewController, GIDSignInDelegate {
  
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        
    }
    
    
    @IBOutlet weak var loadingIcon: UIImageView!
    @IBOutlet weak var containerView: UIView!

    let appDelegate = UIApplication.shared.delegate as! AppDelegate

    override func viewDidLoad() {
        super.viewDidLoad()
        GIDSignIn.sharedInstance().delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let animation = CABasicAnimation()
        animation.toValue = CATransform3DMakeRotation(.pi, 0.0, 1.0, 0.0)
        animation.autoreverses = true
        animation.repeatCount = HUGE
        animation.keyPath = "transform"
        animation.duration = 1.0
        loadingIcon.layer.add(animation,
                              forKey: "rotation")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
            if let _ = AccessToken.current {
                self.showWebViewVC()
            } else if let _ = UserDefaults.standard.string(forKey: Constants.GOOGLE_TOKEN) {
                self.showWebViewVC()
            } else if let _ = UserDefaults.standard.string(forKey: Constants.APPLE_TOKEN) {
                self.showWebViewVC()
            } else if let _ = UserDefaults.standard.string(forKey: Constants.Email_TOKEN) {
                self.showWebViewVC()
            } else {
                self.performSegue(withIdentifier: "showAutorization", sender: self)
            }
         })
    }
    
    func showWebViewVC() {
        let webViewVC = WKWebViewController()
        self.appDelegate.window?.rootViewController = UINavigationController(rootViewController: webViewVC)
        self.appDelegate.window?.makeKeyAndVisible()
    }

}
