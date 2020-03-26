//
//  HelperExtensions.swift
//  Pointer
//
//  Created by Evgeniy Suprun on 24.01.2020.
//  Copyright © 2020 Pointer. All rights reserved.
//

import Foundation
import UIKit

extension StringProtocol  {
    
    func substringFacebook(from start: Self) -> SubSequence? {
        guard let lower = range(of: start)?.upperBound else { return nil }
        return self[lower...]
    }
    
    func substringWhatsUp(from start: Self) -> SubSequence? {
        guard let end = range(of: start)?.lowerBound else { return nil }
        return self[..<end]
    }
}

extension UIViewController {
    
    func showAlert(with title: String, and message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func validateEmail(candidate: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: candidate)
    }
}
