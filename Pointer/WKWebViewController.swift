//
//  WKWebViewController.swift
//  Pointer
//
//  Created by Mairambek on 3/3/20.
//  Copyright © 2020 Pointer. All rights reserved.
//

import UIKit
import WebKit
import FBSDKLoginKit
import FBSDKCoreKit
import FBSDKShareKit
import GoogleSignIn


class WKWebViewController: UIViewController, WKUIDelegate, WKNavigationDelegate, UIScrollViewDelegate {

    var webView: WKWebView?
    var progressView = UIView()
    var progressIndicat = UIActivityIndicatorView()
    var notificationTarget: String?

    let appDelegate = UIApplication.shared.delegate as! AppDelegate

    var userContentController: WKUserContentController = WKUserContentController()
    private let urlBase = "https://ranxsport.com/" // base
      
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        navigationController?.navigationBar.isHidden = true
        
        setupWKVebView()
        if let accessToket = AccessToken.current {
            print("accessToket:" + "\(accessToket.tokenString)")
        }
    }
    
    func setupWKVebView(){
        
        let source: String = "var meta = document.createElement('meta');" +
            "meta.name = 'viewport';" +
            "meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';" +
            "var head = document.getElementsByTagName('head')[0];" + "head.appendChild(meta);";
        let script: WKUserScript = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        let conf = WKWebViewConfiguration()
        userContentController.addUserScript(script)
        conf.userContentController = userContentController
        conf.applicationNameForUserAgent = "PointeriOS"
        webView = WKWebView(frame: .zero,
                            configuration: conf)
        webView?.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView!)
        webView?.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        webView?.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        webView?.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        webView?.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        webView?.scrollView.bounces = false
        webView?.allowsLinkPreview = false
        webView?.uiDelegate = self
        webView?.navigationDelegate = self
        webView?.scrollView.delegate = self
        webView?.backgroundColor = .black
        
        loadFB()
        loadApple()
        loadGoogle()
        loadEmail()
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
    }
    
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
    
    //MARK: Push Notifications
    
    func appDelegate(_ appDelegate: AppDelegate, didReceiveRemoteNotification notification: PointerNotification) {
        print("Received notification with path: \(notification.path ?? "no path")")
        if let path = notification.path {
            loadNoficationTargetIfPossible(path)
        }
    }
    
    //MARK: Scroll View Delegate disallow zooms
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return nil
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
       
        if let urlStr = navigationAction.request.url {
            print("My Sring - \(urlStr.absoluteString)")
            if(urlStr.absoluteString.contains("/#/")) {
                decisionHandler(.allow)
                UserDefaults.standard.removeObject(forKey: Constants.APPLE_TOKEN)
                UserDefaults.standard.removeObject(forKey: Constants.GOOGLE_TOKEN)
                UserDefaults.standard.removeObject(forKey: Constants.Email_TOKEN)
                GIDSignIn.sharedInstance()?.signOut()

                if let _ = AccessToken.current {
                    let loginManager = LoginManager()
                    loginManager.logOut()
                }
                
                let authVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AutorizationMain") as! AutorizationMain
                let window = UIApplication.shared.windows[0] as UIWindow;
                
                UIView.transition(
                    from: ( window.rootViewController!.view)!,
                    to: authVC.view,
                    duration: 0.3,
                    options: .transitionCrossDissolve,
                    completion: {
                        finished in window.rootViewController = authVC
                })
                
//                appDelegate.window?.rootViewController = UINavigationController(rootViewController: authVC)
//                appDelegate.window?.makeKeyAndVisible()
//
                return
            }
        }
        decisionHandler(.allow)
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
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            if let whatsappURL = navigationAction.request.url,whatsappURL.absoluteString.contains("whatsapp") {
                
                // FIX IT WHEN get ituns app url
                let itunesRanxAppUrl = "https://apps.apple.com/us/app/ranx/id1486822124"
                
                let whatsAppScheme = "whatsapp://app"
                let whatsAppItunesUrl = "https://apps.apple.com/ru/app/whatsapp-messenger/id310633997"
                // let procentApp = whatsAppItunesUrl
                let sharedTextFromUrl = whatsappURL.absoluteString.substringWhatsUp(from: "https%") ?? ""
                let outUrlWhatsApp = String(sharedTextFromUrl + itunesRanxAppUrl)
                checkAndOpenApp(reciveUrl: outUrlWhatsApp, sheme: whatsAppScheme, itunesUrl: whatsAppItunesUrl)
                
            } else if let facebookUrl = navigationAction.request.url,facebookUrl.absoluteString.contains("share")
            {
                // FIX IT WHEN get ituns app url add to sharedUrl
                let itunesRanxAppUrl = "https://apps.apple.com/us/app/ranx/id1486822124"
                let sharedTextFromUrl = String(facebookUrl.absoluteString.removingPercentEncoding?.substringFacebook(from: "quote=") ?? "")
                shareTextOnFaceBook(sharedUrl: itunesRanxAppUrl, sharedText: sharedTextFromUrl)
                print(sharedTextFromUrl)
            }
            
            return nil
        }
        return nil
    }
    
}

extension WKWebViewController {
    // Share with facebook button from url
     
    func shareTextOnFaceBook(sharedUrl: String, sharedText: String) {
        let shareContent = ShareLinkContent()
        guard let url = URL(string: sharedUrl) else { return }
        shareContent.contentURL = url
        shareContent.quote = sharedText
        ShareDialog(fromViewController: self, content: shareContent, delegate: self as? SharingDelegate).show()
    }
    
    func loadFB() {
        if let accessToken = AccessToken.current {
            let token = accessToken.tokenString
            guard let authUrl = URL(string:"\(urlBase)?fb_token=\(token)") else { return }
            let authRequest = URLRequest(url: authUrl)
            print(authUrl.absoluteString)
            webView!.load(authRequest)
        }
    }
    
    func loadApple() {
        if let appleToken = UserDefaults.standard.string(forKey: Constants.APPLE_TOKEN) {
            let appleRegAuthUrl = urlBase + "?appleTYPE=ios&token=\(appleToken)"
            guard let authUrl = URL(string: appleRegAuthUrl) else { return }
            let authRequest = URLRequest(url: authUrl)
            print(authUrl.absoluteString)
            self.webView!.load(authRequest)
        }
    }
    
    func loadGoogle() {
        if let googleToken = UserDefaults.standard.string(forKey: Constants.GOOGLE_TOKEN) {
            guard let authUrl = URL(string: self.urlBase + "?google_token=\(googleToken)") else { return }
            let authRequest = URLRequest(url: authUrl)
            print(authUrl.absoluteString)
            self.webView?.load(authRequest)
        }
    }
    
    func loadEmail() {
        if let token = UserDefaults.standard.string(forKey: Constants.Email_TOKEN) {
            print(token)
            guard let authUrl = URL(string: self.urlBase + "?authType=email&token=\(token)") else { return }
            let authRequest = URLRequest(url: authUrl)
            print(authUrl.absoluteString)
            self.webView?.load(authRequest)
    }
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
}
