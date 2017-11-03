//
//  ViewController.swift
//  Scanner
//
//  Created by Himanshu Tantia on 2/11/17.
//  Copyright © 2017 Himanshu Tantia. All rights reserved.
//

import UIKit
import AVFoundation
import UIKit

struct ScanMessage {
    var value: String?
}
protocol ScannerViewControllerDelegate : class {
    func scannerOutput(scannedString: String?)
    func scanner(session: ScannerViewController, didDetectObject messages: [ScanMessage])
    func scanner(session: ScannerViewController, didInvalidateWithError error: Error)
}
protocol ScannerViewControllerDataSource : class {
    var titleForView: String? { get }
    var textForScanInfoView: String? { get }
}

enum ScannerError : Error {
    case featureNotSupported
    case userCanclled
    case error(NSError)
}

class ScannerViewController: UIViewController {

    @IBOutlet fileprivate weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var cameraView: UIView!
    @IBOutlet fileprivate weak var scanInfo: UITextView!

    public weak var delegate: ScannerViewControllerDelegate?
    public weak var dataSource: ScannerViewControllerDataSource?
    public var allowMultipleScans: Bool = false
    
    fileprivate let metadataObjectsSemaphore = DispatchSemaphore(value: 1)
    fileprivate let metadataObjectsQueue = DispatchQueue(label: "com.kreativapps.app.Scanner.ScannerViewController-Queue", attributes: [], target: nil)
    fileprivate let captureSession: AVCaptureSession = AVCaptureSession()
    fileprivate let metadataOutput = AVCaptureMetadataOutput()
    fileprivate var previewLayer: AVCaptureVideoPreviewLayer?
    
    fileprivate var presenter: ScannerViewPresenter?
    fileprivate var wireframe: ScannerViewWireFrame?
    
    deinit {
        presenter = nil
        delegate = nil
    }
    
    @IBAction func scanComplete(_ sender: UIBarButtonItem) {
        clearSession()
        wireframe?.dismiss(animated: true, completion: {
            self.delegate?.scanner(session: self, didInvalidateWithError: ScannerError.userCanclled)
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        wireframe = ScannerViewWireFrame(withController: self)
        presenter = ScannerViewPresenter(withWireframe: wireframe!)
        
        self.modalPresentationStyle = .formSheet
        view.backgroundColor = .darkGray
    }
    
    override func viewDidAppear(_ animated: Bool) {
        do {
            let videoInput = try initializeDeviceCamera()
            try captureSession.add(captureInput: videoInput)
            try captureSession.add(metadataOutput: metadataOutput, withDelegate: self, andQueue: metadataObjectsQueue)
            metadataOutput.setMetadataObjectsDelegate(self, queue: metadataObjectsQueue)
            try metadataOutput.addObject(ofType: .qr)
            setupScanPreview()
            startSession()
        } catch let error {
            self.delegate?.scanner(session: self, didInvalidateWithError: error)
        }
        print(metadataOutput.metadataObjectsCallbackQueue ?? "nil")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
}

 extension ScannerViewController {
     func initializeDeviceCamera() throws -> AVCaptureDeviceInput {
        guard let videoCaptureDevice = AVCaptureDevice.default(for: AVMediaType.video) else {
            throw ScannerError.featureNotSupported
        }
        do {
            let input = try AVCaptureDeviceInput(device: videoCaptureDevice)
            return input
        } catch let outError as NSError {
            throw ScannerError.error(outError)
        }
    }
    
     func setupScanPreview() {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.frame = cameraView.layer.bounds
        previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        cameraView.layer.addSublayer(previewLayer!)
    }
    
     func stopSession() {
        if (captureSession.isRunning == true) {
            captureSession.stopRunning()
        }
    }
    
     func startSession() {
        if (captureSession.isRunning == false) {
            captureSession.startRunning()
        }
    }
    
    func clearSession() {
        stopSession()
        previewLayer?.removeFromSuperlayer()
    }
}

extension ScannerViewController : AVCaptureMetadataOutputObjectsDelegate {
    fileprivate func read(_ metadataObject: AVMetadataObject, _ scanMessage: inout [ScanMessage]) {
        if let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject {
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            scanMessage.append(ScanMessage(value: readableObject.stringValue))
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        metadataOutput(output as! AVCaptureMetadataOutput, didOutput: metadataObjects as! [AVMetadataObject], from: connection)
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if metadataObjectsSemaphore.wait(timeout: .now()) == .success {
            var scanMessage = [ScanMessage]()
            if !allowMultipleScans {
                stopSession()
                if let metadataObject = metadataObjects.first {
                    read(metadataObject, &scanMessage)
                }
                wireframe?.dismiss(animated: true, completion: {
                    self.metadataObjectsSemaphore.signal()
                    self.delegate?.scanner(session: self, didDetectObject: scanMessage)
                })
            } else {
                metadataObjectsQueue.async {
                    for metadataObject in metadataObjects {
                        self.read(metadataObject, &scanMessage)
                    }
                    self.delegate?.scanner(session: self, didDetectObject: scanMessage)
                    self.metadataObjectsSemaphore.signal()
                }
            }
        }
    }
}

extension AVCaptureSession {
    
    func add(captureInput videoInput: AVCaptureDeviceInput) throws {
        guard self.canAddInput(videoInput) else {
            throw ScannerError.featureNotSupported
        }
        self.addInput(videoInput)
    }
    
    func addMetadataOutput(withDelegate delegate: AVCaptureMetadataOutputObjectsDelegate, andQueue queue: DispatchQueue) throws {
        let metadataOutput = AVCaptureMetadataOutput()
        try add(metadataOutput: metadataOutput, withDelegate: delegate, andQueue: queue)
    }

    func add(metadataOutput: AVCaptureMetadataOutput, withDelegate delegate: AVCaptureMetadataOutputObjectsDelegate, andQueue queue: DispatchQueue) throws {
        guard self.canAddOutput(metadataOutput) else {
            throw ScannerError.featureNotSupported
        }
        self.addOutput(metadataOutput)
    }
}

/*
typealias Swift3Code_AVCaptureMetadataOutput = AVCaptureMetadataOutput
extension Swift3Code_AVCaptureMetadataOutput {
    
    func addMetadataObject(ofType type: String) throws {
        guard canAddMetadataObject(ofType: type) else {
            throw ScannerError.featureNotSupported
        }
        guard var metadataObjectTypes = self.metadataObjectTypes else {
            self.metadataObjectTypes = [type]
            return
        }
        metadataObjectTypes.append(type)
        self.metadataObjectTypes = metadataObjectTypes
     }
     
    func canAddMetadataObject(ofType type: String) -> Bool {
        if let types = self.availableMetadataObjectTypes {
            let validType = types.contains { element in
                guard let e = element as? String else {
                    return false
                }
                return e == type
            }
            return validType
        }
        return false
    }
}
*/

typealias Swift4Code_AVCaptureMetadataOutput = AVCaptureMetadataOutput

extension Swift4Code_AVCaptureMetadataOutput {
    
    func addObject(ofType type: AVMetadataObject.ObjectType) throws {
        guard canAddObject(ofType: type) else {
            throw ScannerError.featureNotSupported
        }
        guard var metadataObjectTypes = self.metadataObjectTypes else {
            self.metadataObjectTypes = [type]
            return
        }
        metadataObjectTypes.append(type)
        self.metadataObjectTypes = metadataObjectTypes
    }
    
    func canAddObject(ofType type: AVMetadataObject.ObjectType) -> Bool {
        let types: [AVMetadataObject.ObjectType] = self.availableMetadataObjectTypes 
        return types.contains(type)
    }
}

