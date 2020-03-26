//
//  ViewController.swift
//  Pointer
//
//  Created by Michael Biehl on 5/20/17.
//  Copyright © 2017 Pointer. All rights reserved.
//

import UIKit
import WebKit
import GoogleSignIn
import FBSDKLoginKit
import FBSDKCoreKit
import FBSDKShareKit
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

class ViewController: UIViewController, WKUIDelegate, WKNavigationDelegate, GoogleSignInViewController, UIScrollViewDelegate, GIDSignInDelegate {
    
    @IBOutlet weak var loadingIcon: UIImageView!
    @IBOutlet weak var containerView: UIView!
    
    var webView: WKWebView?
    var userContentController: WKUserContentController = WKUserContentController()
    var notificationTarget: String?
    private let appDelegate = UIApplication.shared.delegate as! AppDelegate
//    private let urlBase = "http://51.15.126.125:3004/#/" // test
    private let urlBase = "https://ranxsport.com/" // base
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
//        let config = WKWebViewConfiguration()
//        config.applicationNameForUserAgent = "PointeriOS"
//        config.userContentController = userContentController
        let source: String = "var meta = document.createElement('meta');" +
            "meta.name = 'viewport';" +
            "meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';" +
            "var head = document.getElementsByTagName('head')[0];" + "head.appendChild(meta);";
        let script: WKUserScript = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        let conf = WKWebViewConfiguration()
        userContentController.addUserScript(script)
        conf.userContentController = userContentController
        conf.applicationNameForUserAgent = "PointeriOS"
//        userContentController.add(self,
//                                  name: "callbackHandler")
        webView = WKWebView(frame: .zero,
                            configuration: conf)
        webView?.alpha = 0
        webView?.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(webView!)
        webView?.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        webView?.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        webView?.widthAnchor.constraint(equalTo: containerView.widthAnchor).isActive = true
        webView?.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        webView?.scrollView.bounces = false
        webView?.allowsLinkPreview = false
        webView?.uiDelegate = self
        webView?.navigationDelegate = self
        webView?.scrollView.delegate = self
        containerView.setNeedsLayout()
        let request = URLRequest(url: URL(string:urlBase)!)
        
        webView?.load(request)

        GIDSignIn.sharedInstance()?.delegate = self
        GIDSignIn.sharedInstance()?.presentingViewController = self
        
        if let accessToket = AccessToken.current {
            print("accessToket:" + "\(accessToket.tokenString)")
        }
        
//        let loginButton = FBLoginButton()
//        loginButton.permissions = ["public_profile", "email"]
//        loginButton.center = view.center
//        view.addSubview(loginButton)
//        GIDSignIn.sharedInstance()?.scopes

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
        
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("DID FINISH NAV")
        if let cookies = HTTPCookieStorage.shared.cookies {
            cookies.forEach { (cookie) in
                if cookie.name == "u_token" {
                    
                    appDelegate.sendFCMToken(to: URL(string: urlBase + "api/fcm-settings"),
                                             pointerToken: cookie.value.replacingOccurrences(of: "%20",
                                                                                             with: " "))
                }
            }
        }
        
        // Go to the notification target after the webview navigates to a post-load, post-login screen
        
        if let path = notificationTarget,
            let fragment = webView.url?.fragment,
            fragment.contains("app") {
            loadNoficationTargetIfPossible(path)
        }
        
        if webView.alpha == 0 {
            UIView.animate(withDuration: 0.5,
                           delay: 0,
                           options: .curveEaseInOut,
                           animations: { [weak loadingIcon] in
                            webView.alpha = 1
                            loadingIcon?.alpha = 0
            })
        }
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        if let _ = webView.url?.host, webView.url!.host!.contains("accounts.google.com") {
            webView.stopLoading()
            googleSignIn()
        } else if let _ = webView.url?.host, webView.url!.host!.contains("") {
            
        }
//        else if let _ = webView.url?.host, webView.url!.host!.contains("appleid") {
//            print(webView.url!.absoluteString)
//            webView.stopLoading()
//            appleSignIn()
//        }
    }
    
    func googleSignIn() {
        
        UIView.animate(withDuration: 0.5) {[weak webView, weak loadingIcon] in
            webView?.alpha = 0
            loadingIcon?.alpha = 1
        }
        if let _ = GIDSignIn.sharedInstance().currentUser?.authentication?.accessToken {
            didSignInToGoogle(with: GIDSignIn.sharedInstance().currentUser)
        }
        else {
            GIDSignIn.sharedInstance().signIn()
        }
    }
    
    func appDelegate( _ appDelegate: AppDelegate, didSignUserIn user: GIDGoogleUser) {
        didSignInToGoogle(with: user)
    }
    
    func appDelegate(_ appDelegate: AppDelegate, didFailToSignin error: Error) {
        didFailToSignIn(with: error)
    }
    
    func didSignInToGoogle(with user: GIDGoogleUser) {
        guard let token = user.authentication.accessToken else { return }
        guard let authUrl = URL(string:"?google_token=\(token)", relativeTo: webView!.url!) else { return }
        let authRequest = URLRequest(url: authUrl)
        print(authUrl.absoluteString)
        webView!.load(authRequest)
    }
    
    func didFailToSignIn(with error: Error) {
        
        UIView.animate(withDuration: 0.5) {[weak webView, weak loadingIcon] in
            webView?.alpha = 1
            loadingIcon?.alpha = 0
        }

    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            if let url = navigationAction.request.url,
                url.absoluteString.contains("dialog/oauth") &&
                    url.absoluteString.contains("facebook") {
                fbSignin()
            } else if let whatsappURL = navigationAction.request.url,whatsappURL.absoluteString.contains("whatsapp") {
                
                // FIX IT WHEN get ituns app url
                let itunesRanxAppUrl = "https://google.com."
                
                let whatsAppScheme = "whatsapp://app"
                let whatsAppItunesUrl = "https://apps.apple.com/ru/app/whatsapp-messenger/id310633997"
               // let procentApp = whatsAppItunesUrl
                let sharedTextFromUrl = whatsappURL.absoluteString.substringWhatsUp(from: "https%") ?? ""
                let outUrlWhatsApp = String(sharedTextFromUrl + itunesRanxAppUrl)
                checkAndOpenApp(reciveUrl: outUrlWhatsApp, sheme: whatsAppScheme, itunesUrl: whatsAppItunesUrl)
                
            } else if let facebookUrl = navigationAction.request.url,facebookUrl.absoluteString.contains("share")
            {
                // FIX IT WHEN get ituns app url add to sharedUrl
                let itunesRanxAppUrl = "https://google.com"
                let sharedTextFromUrl = String(facebookUrl.absoluteString.removingPercentEncoding?.substringFacebook(from: "quote=") ?? "")
                shareTextOnFaceBook(sharedUrl: itunesRanxAppUrl, sharedText: sharedTextFromUrl)
                print(sharedTextFromUrl)
            }
            
            //   let popup = WKWebView(frame: containerView.bounds,
            //                                  configuration: configuration)
            //   popup.uiDelegate = self
            //   containerView.addSubview(popup)
            
            return nil
        }
        return nil
    }
    
     // Share with whatsapp button from url
    
    func checkAndOpenApp(reciveUrl: String, sheme: String, itunesUrl: String) {
        
        let app = UIApplication.shared
        let appScheme = sheme
        if app.canOpenURL(URL(string: appScheme)!) {
            guard let url = URL(string: reciveUrl) else { return }
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(url)
            }
        } else {
            if let url = URL(string: itunesUrl),
                UIApplication.shared.canOpenURL(url)
            {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(url)
                }
            }
        }
    }
    
    // Share with facebook button from url
    
    func shareTextOnFaceBook(sharedUrl: String, sharedText: String) {
        let shareContent = ShareLinkContent()
        guard let url = URL(string: sharedUrl) else { return }
        shareContent.contentURL = url
        shareContent.quote = sharedText
        ShareDialog(fromViewController: self, content: shareContent, delegate: self as? SharingDelegate).show()
    }

    func sharer(_ sharer: Sharing, didCompleteWithResults results: [String : Any]) {
        if sharer.shareContent.pageID != nil {
            print("Share: Success")
        }
    }
    func sharer(_ sharer: Sharing, didFailWithError error: Error) {
        print("Share: Fail")
    }
    func sharerDidCancel(_ sharer: Sharing) {
        print("Share: Cancel")
    }
    
    func appleSignIn() {
        
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
    
    func fbSignin() {
        let login = LoginManager()
        login.logIn(permissions: ["public_profile", "email"],
                    from: self) { [weak self] (result, err) in
                        if let _ = err {
                            print("FB LOGIN ERROR")
                        } else if let _ = result {
                            if result!.isCancelled {
                                print("FB LOGIN CANCELLED")
                            } else if let token = result?.token?.tokenString {
                                self?.didSigninToFacebook(token: token)
                            }
                        }
        }
    }
    
    func didSigninToFacebook(token: String) {
        guard let authUrl = URL(string:"?fb_token=\(token)", relativeTo: webView!.url!) else { return }
        let authRequest = URLRequest(url: authUrl)
        print(authUrl.absoluteString)
        webView!.load(authRequest)
    }
    
    func webViewDidClose(_ webView: WKWebView) {
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       options: .curveEaseInOut,
                       animations: { 
                        webView.alpha = 0
        }) { (finished) in
            webView.removeFromSuperview()
        }
    }
    
    //MARK: Push Notifications
    
    func appDelegate(_ appDelegate: AppDelegate, didReceiveRemoteNotification notification: PointerNotification) {
        print("Received notification with path: \(notification.path ?? "no path")")
        if let path = notification.path {
            loadNoficationTargetIfPossible(path)
        }
    }
    
    // Goes to the target path of the notification if the webview is loaded and the user is logged in. Logged in is determined by whether the fragment (# path) contains "app"
    
    func loadNoficationTargetIfPossible(_ path: String) {
        notificationTarget = nil
        if let currUrl = webView?.url, let fragment = currUrl.fragment, fragment.contains("app") {
            let newUrl = URL(string: "https://" + currUrl.host! + "/#\(path)")
            print(" Test URL = \(newUrl!)")
            let request = URLRequest(url: newUrl!)
            webView!.load(request)
        } else {
            notificationTarget = path
        }
    }

    //MARK: Scroll View Delegate disallow zooms
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return nil
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        if let urlStr = navigationAction.request.url {
            
            if(urlStr.absoluteString.contains("www.facebook.com")) {
                print("Found Facebook information")
                decisionHandler(.cancel)
               self.webView!.stopLoading()
                appleSignIn()
                return
            }
            
           print(urlStr.absoluteString, urlStr.absoluteString.contains("www.facebook.com"))
        }
        

         decisionHandler(.allow)
    }
    
    //MARK: GIDSignInDelegate
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        
        if let newUser = user {
            didSignInToGoogle(with: newUser)
        }
        
    }
    
}

@available(iOS 13.0, *)

extension ViewController : ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
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
//  https://ranxsport.com/?appleID=true&code=c852b655e4ae64452af64654e2cc181b6.0.nrtxz.1Nz3eeZZgOJMuXLEeO-1lQ&fname=anonimus&lname=account
//        https://ranxsport.com/?appleID=true&code=cc2bbeddf82174b8fa227f060de025e50.0.nrtxz.LTWEI0lsMj8AFtBGYafqgg&fname=anonimous&lname=account#/app/home
//        let email = appleIDCredential.email
//        let firstName = appleIDCredential.fullName?.givenName
//        let lastName = appleIDCredential.fullName?.familyName
        
        var appleRegAuthUrl = urlBase + "?appleID=true&code=\(codeStr)"

        appleRegAuthUrl += "&fname=anonimus"
        appleRegAuthUrl += "&lname=account"
        print(appleRegAuthUrl)
        if let url = URL(string: appleRegAuthUrl) {
            let authRequest = URLRequest(url: url)
            print(authRequest)
            webView?.load(authRequest)
        }
       
    }

    public func authorizationController(
      controller: ASAuthorizationController,
      didCompleteWithError error: Error
    ) {
        print(error.localizedDescription)
    }
    
}
