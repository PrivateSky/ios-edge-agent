//
//  CodeScannerViewController.swift
//
//  Created by Costin Andronache on 9/16/20.
//

import AVFoundation
import UIKit

class CodeScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    @IBOutlet private var scannerAnimationView: ScannerAnimationView?
    @IBOutlet private var previewHostView: UIView?
    @IBOutlet private var cancelButton: UIButton?
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let soundFile = CodeScannerSoundFile()
    
    var searchedMetadata: [AVMetadataObject.ObjectType] = []
    var completion: Completion?
    
    convenience init() {
        self.init(nibName: "CodeScannerViewController", bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cancelButton?.setTitle(NSLocalizedString("cancel", comment: ""), for: .application)
        cancelButton?.layer.borderWidth = 4.0
        cancelButton?.layer.borderColor = UIColor.white.cgColor
        
        if AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized {
           beginScanning()
        } else {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { [weak self] (granted: Bool) in
                DispatchQueue.main.async {
                    if granted {
                        self?.beginScanning()
                    } else {
                        
                        self?.completion?(.failure(.cameraUnavailable))
                    }                    
                }
            })
        }
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        previewLayer?.frame = view.bounds
        if captureSession?.isRunning == false {
            captureSession?.startRunning()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if captureSession?.isRunning == true {
            captureSession?.stopRunning()
        }
    }
    
    @IBAction private func didPressCancel() {
        completion?(.failure(.userCancelled))
    }
    
    private func beginScanning() {
        let captureSession = AVCaptureSession()
        self.captureSession = captureSession
        
        previewHostView?.backgroundColor = UIColor.black
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            completion?(.failure(.cameraUnavailable))
            return
        }
        
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            } else {
                completion?(.failure(.cameraUnavailable))
                return
            }
        } catch {
            completion?(.failure(.cameraUnavailable))
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = searchedMetadata
        } else {
            completion?(.failure(.featureNotAvailable))
            return
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        previewHostView?.layer.addSublayer(previewLayer)
        
        self.previewLayer = previewLayer
        captureSession.startRunning()

    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {

        if let metadataObject = metadataObjects.first {
            guard let readableObject = previewLayer?.transformedMetadataObject(for: metadataObject) as? AVMetadataMachineReadableCodeObject else {
                print("COULD NOT TRANSFORM")
                return
            }
            guard let stringValue = readableObject.stringValue else { return }
            
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                
                self.scannerAnimationView?.focusOn(rect: readableObject.bounds, completion: {
                    AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                    self.soundFile.play()
                    self.completion?(.success(stringValue))
                    
                })
            }
            captureSession?.stopRunning()
            output.setMetadataObjectsDelegate(nil, queue: nil)
        }

    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}

extension CodeScannerViewController {
    enum FailReason: Error {
        case noCodeFound
        case featureNotAvailable
        case cameraUnavailable
        case userCancelled
    }
    typealias Completion = (Result<String, FailReason>) -> Void
}
