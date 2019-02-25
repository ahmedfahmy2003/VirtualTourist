//
//  UIViewExtensions.swift
//  VirtualTourist
//
//  Created by Ahmed Fahmy on 20/02/2019.
//  Copyright © 2019 Mohtaref. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController{
    
    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    func displayError(message: String) {
        let alertController = UIAlertController(title: "API Error", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    func performUIUpdatesOnMain(_ updates: @escaping () -> Void) {
        DispatchQueue.main.async {
            updates()
        }
    }
    
}
