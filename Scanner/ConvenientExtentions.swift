//
//  ConvenientExtentions.swift
//  Scanner
//
//  Created by Himanshu Tantia on 2/11/17.
//  Copyright © 2017 Kreativ Apps, LLC. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func presentInfoAlert(withTitle title: String, andMessage message: String, completion: (() -> Swift.Void)? = nil) {
        let action = UIAlertAction(title: "Ok", style: .cancel)
        presentAlert(withTitle: title, message: message, andAction: action, completion: completion)
    }
    
    func presentAlert(withTitle title: String, message: String, andAction action: UIAlertAction, completion: (() -> Swift.Void)? = nil) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(action)
        self.present(ac, animated: true, completion: completion)
    }
}
