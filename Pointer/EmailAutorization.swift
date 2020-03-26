//
//  EmailAutorization.swift
//  Pointer
//
//  Created by Evgeniy Suprun on 29.02.2020.
//  Copyright © 2020 Pointer. All rights reserved.
//

import UIKit


protocol LoadEmailProtocol {
    func loadEmail(token: String)
}

class EmailAutorization: UIViewController {
    
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var logInButton: UIButton!
    @IBOutlet weak var emailView: UIView!
    @IBOutlet weak var passwordView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    var constantKeyboard: CGFloat = 3
    private let urlBase = "https://ranxsport.com/api/login" // base
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var myDelegate: LoadEmailProtocol?
    var userToken: String?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        textFieldsAmdButtonSettings()
        hideKeyboardWhenTappedAround()
        registerForKeyboardNotifications()
        emailTextField.delegate = self
        passwordTextField.delegate = self
        emailTextField.addTarget(self, action: #selector(changeEmailTextField), for: .editingChanged)
        passwordTextField.addTarget(self, action: #selector(changePasswordTextField), for: .editingChanged)
    }
    
    
    deinit {
        removeKeyboardNotification()
    }
    
    func textFieldsAmdButtonSettings() {
        emailView.layer.cornerRadius = 30
        emailView.layer.borderWidth = 0.3
        emailView.layer.borderColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        
        passwordView.layer.cornerRadius = 30
        passwordView.layer.borderWidth = 0.3
        passwordView.layer.borderColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        
        logInButton.layer.cornerRadius = 30
        if UIScreen.main.bounds.height > 700 {
            bottomConstraint.constant = 150.00
            constantKeyboard = 4
        }
    }
    
    func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(kbWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(kbWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func removeKeyboardNotification() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func kbWillShow(_ notification: Notification) {
        let userInfo = notification.userInfo
        let kbFrameSize = (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        scrollView.contentOffset = CGPoint(x: 0, y: kbFrameSize.height / constantKeyboard)
    }
    
    @objc func kbWillHide() {
        scrollView.contentOffset = CGPoint.zero
    }
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func logInButtonTapped(_ sender: UIButton) {
        
        checkTextFields()
    }
    
    @objc func changeEmailTextField() {
        
        guard let enterMailText = emailTextField.text else { return }
        if validateEmail(candidate: enterMailText) {
            emailView.layer.borderWidth = 1.0
            emailView.layer.borderColor = #colorLiteral(red: 0.166582346, green: 0.6739595532, blue: 0.5310490131, alpha: 1)
        } else {
            emailView.layer.borderWidth = 0.3
            emailView.layer.borderColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        }
    }
    
    @objc func changePasswordTextField() {
        
        guard let enterMailText = passwordTextField.text else { return }
        if enterMailText.count < 3 {
            passwordView.layer.borderWidth = 0.3
            passwordView.layer.borderColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
          } else {
            passwordView.layer.borderWidth = 1.0
            passwordView.layer.borderColor = #colorLiteral(red: 0.166582346, green: 0.6739595532, blue: 0.5310490131, alpha: 1)
          }
    }
    
    func checkTextFields() {
        
        guard let enterMailText = emailTextField.text else { return }
        guard let passwordText = passwordTextField.text else { return}
        
        if !validateEmail(candidate: enterMailText) {
            showAlert(with: "Try again", and: "Please enter valid email!")
        } else if passwordText.count < 3 {
            showAlert(with: "Try again", and: "Your password must contain 3 or more characters!")
        } else {
            emailDataRequest()
        }
        
    }

    func emailDataRequest() {
        
        var request = URLRequest(url: URL(string: urlBase)!)
        request.httpMethod = "POST"
        guard let emailText = emailTextField.text,
            let passwordText = passwordTextField.text
            else { return }
        let postString = "email=\(emailText)&password=\(passwordText)"
        request.httpBody = postString.data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else { return }
             
            do {
                  let user = try JSONDecoder().decode(UserData.self, from: data)
                  self.userToken = user.token
                print("My user token = \(String(describing: self.userToken))")
              } catch {
                  print("Parse Error")
              }
            
            let httpStatus = response as? HTTPURLResponse
            print("statusCode should be 200, but is \(httpStatus!.statusCode)")
            print("response = \(String(describing: response))")
            print(postString)
            
            if let httpStatusCode = httpStatus?.statusCode {
                DispatchQueue.main.async {
                    
                    switch(httpStatusCode) {
                    case 200...300:
                        guard let userToken = self.userToken else { return }
//                        self.myDelegate?.loadEmail(token: userToken)
                        let token = userToken.replacingOccurrences(of: " ", with: "%20")
                        UserDefaults.standard.set(token, forKey: Constants.Email_TOKEN)
                        let webViewVC = WKWebViewController()
                        self.appDelegate.window?.rootViewController = UINavigationController(rootViewController: webViewVC)
                        self.appDelegate.window?.makeKeyAndVisible()
                    case 400:
                        self.showAlert(with: "Error!", and: "Sorry this email is not registered!")
                    case 403:
                        self.showAlert(with: "Try Again", and: "Sorry you enter wrong password!")
                    default:
                        self.showAlert(with: "Try Again", and: "Some error with connect!")
                    }
                }
            }
            let responseString = String(data: data, encoding: .utf8)
            print("responseString = \(String(describing: responseString))")
            
        }
        task.resume()
    }
    
}

// MARK: Hide KeyBoard

extension EmailAutorization: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(EmailAutorization.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
