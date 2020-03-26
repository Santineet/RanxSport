//
//  ForgotPassword.swift
//  Pointer
//
//  Created by Evgeniy Suprun on 02.03.2020.
//  Copyright © 2020 Pointer. All rights reserved.
//

import UIKit

class ForgotPassword: UIViewController {
    
    @IBOutlet weak var enterMailTextfield: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var enterMailView: UIView!
    @IBOutlet weak var forgotPasswordView: UIView!
    @IBOutlet weak var forgotPasswordButton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
   
    var constantKeyboard: CGFloat = 7
    private let urlBase = "https://ranxsport.com/api/find-email" // find email in base
    private let urlBaseRetrived = "https://ranxsport.com/api/change-password" // retrived password
    
      override func viewDidLoad() {
          super.viewDidLoad()
          textFieldsAmdButtonSettings()
          hideKeyboardWhenTappedAround()
          registerForKeyboardNotifications()
          enterMailTextfield.delegate = self
          passwordTextField.delegate = self
          enterMailTextfield.addTarget(self, action: #selector(changeEmailTextField), for: .editingChanged)
          passwordTextField.addTarget(self, action: #selector(changePasswordTextField), for: .editingChanged)
      }
    
    override func viewWillAppear(_ animated: Bool) {
        passwordTextField.isHidden = true
        forgotPasswordView.isHidden = true
    }
          
      
      deinit {
          removeKeyboardNotification()
      }
      
      func textFieldsAmdButtonSettings() {
          enterMailView.layer.cornerRadius = 30
          enterMailView.layer.borderWidth = 0.3
          enterMailView.layer.borderColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        
          forgotPasswordView.layer.cornerRadius = 30
          forgotPasswordView.layer.borderWidth = 0.3
          forgotPasswordView.layer.borderColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
         
          forgotPasswordButton.layer.cornerRadius = 30
          if UIScreen.main.bounds.height > 700 {
            bottomConstraint.constant = 150.00
            constantKeyboard = 7
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
        self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func forgotButtonTapped(_ sender: UIButton) {
           checkCorrectTextField()
        }
    
    @objc func changeEmailTextField() {
        
        guard let enterMailText = enterMailTextfield.text else { return }
        if validateEmail(candidate: enterMailText) {
            enterMailView.layer.borderWidth = 1.0
            enterMailView.layer.borderColor = #colorLiteral(red: 0.166582346, green: 0.6739595532, blue: 0.5310490131, alpha: 1)
        } else {
            enterMailView.layer.borderWidth = 0.3
            enterMailView.layer.borderColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        }
    }
    
    @objc func changePasswordTextField() {
        
        guard let enterMailText = passwordTextField.text else { return }
        if enterMailText.count < 3 {
            forgotPasswordView.layer.borderWidth = 0.3
            forgotPasswordView.layer.borderColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
          } else {
            forgotPasswordView.layer.borderWidth = 1.0
            forgotPasswordView.layer.borderColor = #colorLiteral(red: 0.166582346, green: 0.6739595532, blue: 0.5310490131, alpha: 1)
          }
    }

    func checkCorrectTextField() {
        
        guard let enterMailText = enterMailTextfield.text else { return }
        // guard let passwordText = passwordTextField.text else { return}
        
        if !validateEmail(candidate: enterMailText) {
            showAlert(with: "Try again", and: "Please enter valid email!")
//        } else if passwordText.count < 3 {
//           showAlert(with: "Error!", and: "Your password must contain 3 or more characters!")
        } else {
            checkHidenPassword()
        }
    }
    
    func checkHidenPassword() {
        if passwordTextField.isHidden == true {
            checkEmailInBase()
        } else {
            retrivedPassword()
        }
    }
    
    func checkEmailInBase() {
        guard let enterMailText = enterMailTextfield.text else { return }
        self.forgotPasswordButton.isEnabled = false
        var request = URLRequest(url: URL(string: urlBase)!)
        request.httpMethod = "POST"
        let postString = "email=\(enterMailText)"
        request.httpBody = postString.data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
            self.showAlert(with: "Error!", and: "An error has occurred")
                self.forgotPasswordButton.isEnabled = true
                print("error=\(String(describing: error))")
                return
            }
            
            let httpStatus = response as? HTTPURLResponse
            print("statusCode should be 200, but is \(httpStatus!.statusCode)")
            print("response = \(String(describing: response))")
            print(postString)
            if let httpStatusCode = httpStatus?.statusCode {
                DispatchQueue.main.async {
                    self.forgotPasswordButton.isEnabled = true
                    switch(httpStatusCode) {
                    case 200...300:
                        self.passwordTextField.isHidden = false
                        self.forgotPasswordView.isHidden = false
                        self.forgotPasswordButton.titleLabel?.text = "New password"
                    case 404:
                        self.showAlert(with: "Error!", and: "Sorry this email is not registered!")
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
    
    func retrivedPassword() {
        
        guard let enterMailText = enterMailTextfield.text else { return }
        guard let passwordText = passwordTextField.text, passwordText.count > 3  else { return }
        
        var request = URLRequest(url: URL(string: urlBaseRetrived)!)
        request.httpMethod = "POST"
        let postString = "email=\(enterMailText)&password=\(passwordText)"
        print(postString)
        self.forgotPasswordButton.isEnabled = false
        request.httpBody = postString.data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                self.showAlert(with: "Error!", and: "An error has occurred")
                self.forgotPasswordButton.isEnabled = true
                print("error=\(String(describing: error))")
                return
            }
            
            let httpStatus = response as? HTTPURLResponse
            print("statusCode should be 200, but is \(httpStatus!.statusCode)")
            print("response = \(String(describing: response))")
            print(postString)
            if let httpStatusCode = httpStatus?.statusCode {
                DispatchQueue.main.async {
                    self.forgotPasswordButton.isEnabled = true
                    switch(httpStatusCode) {
                    case 200...300:
                        self.showAlert(with: "Welldone", and: "Your password was changed!")
                    case 400:
                        self.showAlert(with: "Error!", and: "Sorry this email is not registered!")
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
        
    
    @IBAction func orLogInButtonTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
}
// MARK: Hide KeyBoard

extension ForgotPassword: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ForgotPassword.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
