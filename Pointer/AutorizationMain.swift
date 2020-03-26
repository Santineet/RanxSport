//
//  AutorizationMain.swift
//  Pointer
//
//  Created by Evgeniy Suprun on 29.02.2020.
//  Copyright © 2020 Pointer. All rights reserved.
//

import UIKit
import GoogleSignIn
import FBSDKLoginKit
import FBSDKCoreKit
import AuthenticationServices

protocol GoogleSignInViewController {
    func appDelegate(_ appDelegate: AppDelegate, didSignUserIn user: GIDGoogleUser)
    func appDelegate(_ appDelegate: AppDelegate, didFailToSignin error: Error)
}

class PointerNotification {
    var path: String?
    
    init(path: String?) {
        self.path = path
    }
}

class AutorizationMain: UIViewController {

    @IBOutlet weak var logEmailButton: UIButton!
    @IBOutlet weak var logFaceBookButton: UIButton!
    @IBOutlet weak var logGoogleButton: UIButton!
    @IBOutlet weak var logAppleButton: UIButton!
    @IBOutlet weak var bottomStackConstrain: NSLayoutConstraint!
   
    let appDelegate = UIApplication.shared.delegate as! AppDelegate


    override func viewDidLoad() {
        super.viewDidLoad()
        
        GIDSignIn.sharedInstance()?.delegate = self
        GIDSignIn.sharedInstance()?.presentingViewController = self
        
        buttonSettings()
        setupTargets()
    
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    
        navigationController?.navigationBar.isHidden = true
    }
    
    func buttonSettings() {
        logEmailButton.layer.cornerRadius = 30
        logFaceBookButton.layer.cornerRadius = 30
        logGoogleButton.layer.cornerRadius = 30
        logAppleButton.layer.cornerRadius = 30
        logAppleButton.layer.borderWidth = 1
        logAppleButton.layer.borderColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        
        if UIScreen.main.bounds.height < 700 {
            bottomStackConstrain.constant = 80.0
        } else {
            bottomStackConstrain.constant = 150.00
        }
    }
    
    private func setupTargets() {
        logFaceBookButton.addTarget(self, action: #selector(facebookButtonTapped), for: .touchUpInside)
        logAppleButton.addTarget(self, action: #selector(appleButtonTapped), for: .touchUpInside)
        logGoogleButton.addTarget(self, action: #selector(googleButtonTapped), for: .touchUpInside)
    }
    
    @objc func appleButtonTapped() {
        appleSignIn()
    }
    
    @objc func facebookButtonTapped() {
        fbSignin()
    }
    
    @objc func googleButtonTapped() {
        googleSignIn()
    }
    
    private func googleSignIn() {
        if let _ = GIDSignIn.sharedInstance().currentUser?.authentication?.accessToken {
            didSignInToGoogle(with: GIDSignIn.sharedInstance().currentUser)
        } else {
            GIDSignIn.sharedInstance().signIn()
        }
    }
    
    func didSignInToGoogle(with user: GIDGoogleUser) {
        guard let token = user.authentication.accessToken else { return }
        UserDefaults.standard.set(token, forKey: Constants.GOOGLE_TOKEN)
        let webViewVC = WKWebViewController()
        appDelegate.window?.rootViewController = UINavigationController(rootViewController: webViewVC)
        appDelegate.window?.makeKeyAndVisible()
    }
    
    private func appleSignIn() {
        if #available(iOS 13.0, *) {
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            authorizationController.performRequests()
        }
    }
    
    private func fbSignin() {
        let login = LoginManager()
        login.logIn(permissions: ["public_profile", "email"],
                    from: self) { [weak self] (result, err) in
                        if let _ = err {
                            print("FB LOGIN ERROR")
                        } else if let _ = result {
                            if result!.isCancelled {
                                print("FB LOGIN CANCELLED")
                            } else if let _ = result?.token?.tokenString {
                                self?.didSigninToFacebook()
                            }
                        }
        }
    }
    
    private func didSigninToFacebook() {
        let webViewVC = WKWebViewController()
        appDelegate.window?.rootViewController = UINavigationController(rootViewController: webViewVC)
        appDelegate.window?.makeKeyAndVisible()
    }
}

@available(iOS 13.0, *)

extension AutorizationMain : ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    @available(iOS 13.0, *)
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
    
    public func authorizationController( controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        
        var tokenStr = ""
        
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let code = appleIDCredential.authorizationCode,
            let codeStr = String(data: code, encoding: .utf8) else { return }
        print("code auth \(codeStr)")
        
        if let token = appleIDCredential.identityToken {
            tokenStr = String(decoding: token, as: UTF8.self)
            print("token auth \(tokenStr)")
        }
        
        UserDefaults.standard.set(tokenStr, forKey: Constants.APPLE_TOKEN)
        
        let webViewVC = WKWebViewController()
        appDelegate.window?.rootViewController = UINavigationController(rootViewController: webViewVC)
        appDelegate.window?.makeKeyAndVisible()
    }
    
    public func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        print(error.localizedDescription)
    }
}

extension AutorizationMain: GoogleSignInViewController, GIDSignInDelegate {
   
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let newUser = user {
            didSignInToGoogle(with: newUser)
        }
    }
    
    func appDelegate( _ appDelegate: AppDelegate, didSignUserIn user: GIDGoogleUser) {
        didSignInToGoogle(with: user)
    }
    
    func appDelegate(_ appDelegate: AppDelegate, didFailToSignin error: Error) {
        print("Google SignIn Error")
//        didFailToSignIn(with: error)
    }
}
