//
//  CameraScreenPresenter.swift
//  PSKNodeServer
//
//  Created by Costin Andronache on 10.01.2022.
//

import AVFoundation
import UIKit

final class CameraScreenPresenter {
    typealias InitializationCompletion = (Result<Void, CameraScreenModule.InitializationError>) -> Void
    
    var onUserCancelAction: VoidBlock?
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var initializationCompletion: InitializationCompletion = { _ in }
    private weak var view: CameraScreenView?
        
    func prepareForInitializationWith(view: CameraScreenView, initializationCompletion: @escaping InitializationCompletion) {
        self.view = view
        self.initializationCompletion = initializationCompletion
        
        view.onViewDidLoad = { [weak self] in
            self?.begin()
        }
        
        view.onUserCancelAction = { [weak self] in
            self?.stopCapture()
            self?.onUserCancelAction?()
        }
    }
    
    private func begin() {
        if AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized {
           beginVideoCapture()
        } else {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { [weak self] (granted: Bool) in
                DispatchQueue.main.async {
                    if granted {
                        self?.beginVideoCapture()
                    } else {
                        self?.initializationCompletion(.failure(.cameraNotAvailable))
                    }
                }
            })
        }
    }
    
    private func beginVideoCapture() {
        let captureSession = AVCaptureSession()
        self.captureSession = captureSession
                
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            initializationCompletion(.failure(.cameraNotAvailable))
            return
        }
        
        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            } else {
                initializationCompletion(.failure(.cameraNotAvailable))
                return
            }
        } catch {
            initializationCompletion(.failure(.cameraNotAvailable))
            return
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        view?.integratePreviewLayer(previewLayer)
        self.previewLayer = previewLayer
        captureSession.startRunning()
        
        initializationCompletion(.success(()))
    }
}

extension CameraScreenPresenter: CameraScreenModuleInput {
    func addOutput(_ output: AVCaptureOutput, completion: CameraScreenModule.AddOutputCompletion?) {
        guard let captureSession = self.captureSession,
              captureSession.canAddOutput(output) else {
                  completion?(.failure(.featureNotAvailable))
                  return
        }
        captureSession.addOutput(output)
        completion?(.success(()))
    }
    
    func convertObjectCoordinatesIntoOwnBounds<T>(object: T) -> T? where T : AVMetadataObject {
        previewLayer?.transformedMetadataObject(for: object) as? T
    }
    
    func captureCurrentFrame(withAnimation: Bool, withSound: Bool, completion: CameraScreenModule.CaptureFrameCompletion?) {
        
    }
    
    func playCaptureAnimation(withSound: Bool) {
        view?.playCaptureAnimation(withSound: withSound)
    }
    
    func playFocusAnimation(withinViewBoundsRect rect: CGRect,
                            withSound: Bool,
                            completion: VoidBlock?) {
        view?.playFocusAnimation(withinViewBoundsRect: rect,
                                 withSound: withSound,
                                 completion: completion)
    }
    
    func stopCapture() {
        if captureSession?.isRunning == true {
            captureSession?.stopRunning()
        }
    }
}
