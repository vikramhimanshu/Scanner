//
//  ScannerViewWireFrame.swift
//  Scanner
//
//  Created by Himanshu Tantia on 2/11/17.
//  Copyright © 2017 Himanshu Tantia. All rights reserved.
//

import UIKit

protocol WireFrame : class {
    static var storyboard: UIStoryboard { get }
    init<T: UIViewController>(withController controller: T)
    static var initialViewController: UIViewController { get }
}

class ScannerViewWireFrame : WireFrame {
    
    fileprivate weak var controller: ScannerViewController?
    required init<T>(withController controller: T) where T : UIViewController {
        self.controller = controller as? ScannerViewController
    }
    
    static var initialViewController: UIViewController {
        let vc: ScannerViewController = storyboard.instantiateViewController()
        return vc
    }
    
    static var storyboard: UIStoryboard {
        return UIStoryboard(storyboard: .main)
    }
}

extension ScannerViewWireFrame {
    func presentAlert(withTitle title: String, andMessage message: String) {
        DispatchQueue.main.async {
            self.controller?.presentInfoAlert(withTitle: title, andMessage: message)
        }
    }
    
    func dismiss(animated flag: Bool, completion: (() -> Swift.Void)? = nil) {
        DispatchQueue.main.async {
            self.controller?.dismiss(animated: flag, completion: completion)
        }
    }
}
