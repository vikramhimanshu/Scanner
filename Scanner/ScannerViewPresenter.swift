//
//  ScannerViewPresenter.swift
//  Scanner
//
//  Created by Himanshu Tantia on 2/11/17.
//  Copyright © 2017 Himanshu Tantia. All rights reserved.
//

import Foundation

protocol Presenter {
    init<T: WireFrame>(withWireframe wireframe: T)
}

class ScannerViewPresenter : Presenter {
    
    private weak var wireframe: ScannerViewWireFrame?
    
    required init<T>(withWireframe wireframe: T) where T : WireFrame {
        self.wireframe = wireframe as? ScannerViewWireFrame
    }
    
    func dismiss(completion: (() -> Void)? = nil) {
        wireframe?.dismiss(animated: true, completion: completion)
    }
    
    func deviceNotSupportedAlert(withTitle title: String = "Scanning not supported", andMessage message: String = "Your device cannot be used for scanning the code, please use a device with a camera") {
        wireframe?.presentAlert(withTitle: title, andMessage: message)
    }
}
