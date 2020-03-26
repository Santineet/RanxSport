//
//  SignUpController.swift
//  Pointer
//
//  Created by Evgeniy Suprun on 02.03.2020.
//  Copyright © 2020 Pointer. All rights reserved.
//

import UIKit

class SignUpController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var yourNameTextField: UITextField!
    @IBOutlet weak var emailView: UIView!
    @IBOutlet weak var passwordView: UIView!
    @IBOutlet weak var yourNameView: UIView!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var constantKeyboard: CGFloat = 2
    private let urlBase = "https://ranxsport.com/api/signup" // base
    
     override func viewDidLoad() {
         super.viewDidLoad()
         textFieldsAmdButtonSettings()
         hideKeyboardWhenTappedAround()
         registerForKeyboardNotifications()
         emailTextField.delegate = self
         passwordTextField.delegate = self
         yourNameTextField.delegate = self
         emailTextField.addTarget(self, action: #selector(changeEmailTextField), for: .editingChanged)
         passwordTextField.addTarget(self, action: #selector(changePasswordTextField), for: .editingChanged)
         yourNameTextField.addTarget(self, action: #selector(changeNameTextField), for: .editingChanged)
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
        
         yourNameView.layer.cornerRadius = 30
         yourNameView.layer.borderWidth = 0.3
         yourNameView.layer.borderColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
         signUpButton.layer.cornerRadius = 30
         if UIScreen.main.bounds.height > 700 {
           bottomConstraint.constant = 150.00
           constantKeyboard = 3
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
    

    @IBAction func signUpButtonTapped(_ sender: UIButton) {
        checkTextFields()
    }
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func orLoginButtonTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
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
        
        guard let enterPasswortText = passwordTextField.text else { return }
        if enterPasswortText.count < 3 {
            passwordView.layer.borderWidth = 0.3
            passwordView.layer.borderColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
          } else {
            passwordView.layer.borderWidth = 1.0
            passwordView.layer.borderColor = #colorLiteral(red: 0.166582346, green: 0.6739595532, blue: 0.5310490131, alpha: 1)
          }
    }
    
    @objc func changeNameTextField() {
        
        guard let enterNameText = yourNameTextField.text else { return }
        if enterNameText.isEmpty {
            yourNameView.layer.borderWidth = 0.3
            yourNameView.layer.borderColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
          } else {
            yourNameView.layer.borderWidth = 1.0
            yourNameView.layer.borderColor = #colorLiteral(red: 0.166582346, green: 0.6739595532, blue: 0.5310490131, alpha: 1)
          }
    }
    
    func checkTextFields() {
        
        guard let enterMailText = emailTextField.text else { return }
        guard let passwordText = passwordTextField.text else { return}
        guard let yourNameText = yourNameTextField.text else { return }
        
        if !validateEmail(candidate: enterMailText) {
            showAlert(with: "Try again", and: "Please enter valid email!")
        } else if passwordText.count < 3 {
           showAlert(with: "Error!", and: "Your password must contain 3 or more characters!")
        } else if yourNameText.isEmpty {
           showAlert(with: "Error!", and: "Please enter your name!")
        } else {
            signUpRequest()
        }
   
    }
    
    func signUpRequest() {
        
        var request = URLRequest(url: URL(string: urlBase)!)
        request.httpMethod = "POST"
        guard let yourNameText = yourNameTextField.text,
            let emailText = emailTextField.text,
            let passwordtext = passwordTextField.text
            else { return }
        let postString = "name=\(yourNameText)&email=\(emailText)&password=\(passwordtext)"
        request.httpBody = postString.data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("error=\(String(describing: error))")
                return
            }
            
            let httpStatus = response as? HTTPURLResponse
            print("statusCode should be 200, but is \(httpStatus!.statusCode)")
            print("response = \(String(describing: response))")
            print(postString)
            if let httpStatusCode = httpStatus?.statusCode {
                DispatchQueue.main.async {
                    
                    switch(httpStatusCode) {
                    case 200...300:
                        self.showAlert(with: "Welldone", and: "You successfully registered!")
                    case 400:
                        self.showAlert(with: "Error", and: "Sorry this email is already registered!")
                    case 403:
                        self.showAlert(with: "Error", and: "Sorry some problem with your password")
                        
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

extension SignUpController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SignUpController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
