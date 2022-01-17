//
//  CameraFrameCaptureModule.swift
//  PSKNodeServer
//
//  Created by Costin Andronache on 15.01.2022.
//

import Foundation
import AVFoundation
import UIKit

enum CameraFrameCapture {
    typealias Error = CameraMetadataScan.Error
    enum PhotoCaptureError: Swift.Error {
        case photoCaptureFailure(Swift.Error?)
    }
    typealias CapturedFrameHandler = (Result<UIImage, PhotoCaptureError>) -> Void
    typealias InitializationCompletion = (Result<Void, Error>) -> Void
}

protocol CameraFrameCaptureModuleInput {
    var onUserCancelAction: VoidBlock? { get set }
    func launchFrameCaptureOn(hostController: UIViewController, initializationCompletion: CameraFrameCapture.InitializationCompletion?)
    func cancelFrameCapture()
    func captureNextFrame(handler: @escaping CameraFrameCapture.CapturedFrameHandler)
}


final class CameraFrameCaptureModule: NSObject {
    private let cameraScreenModuleBuilder: CameraScreenModuleBuildable
    private var cameraScreenModuleInput: CameraScreenModuleInput?
    private var cameraScreenController: UIViewController?
    
    private let output = AVCapturePhotoOutput()
    private var photoCaptureCompletion: ((Result<AVCapturePhoto, Error>) -> Void)?
    
    var onUserCancelAction: VoidBlock?
    
    init(cameraScreenModuleBuilder: CameraScreenModuleBuildable) {
        self.cameraScreenModuleBuilder = cameraScreenModuleBuilder
    }
    
    private func prepareFrameCaptureWith(cameraScreenModuleInput: CameraScreenModuleInput,
                                         completion: CameraFrameCapture.InitializationCompletion?) {
        self.cameraScreenModuleInput = cameraScreenModuleInput
        switch cameraScreenModuleInput.addOutput(output) {
        case .success:
            completion?(.success(()))
        case .failure(let error):
            completion?(.failure(.cameraModuleFunctionalityError(error)))
        }

    }
    
    private func initializeModuleOn(hostController: UIViewController,
                                    cameraScreenController: UIViewController,
                                    input: CameraScreenModuleInput,
                                    initializationCompletion: CameraFrameCapture.InitializationCompletion?) {
        self.cameraScreenController = cameraScreenController
        self.cameraScreenModuleInput = input
        
        input.onUserCancelAction = { [weak self] in
            self?.cameraScreenController?.dismiss(animated: true, completion: nil)
            self?.onUserCancelAction?()
        }
        
        prepareFrameCaptureWith(cameraScreenModuleInput: input,
                                      completion: { [weak self] in
            switch $0 {
            case .success:
                initializationCompletion?(.success(()))
            case .failure(let error):
                self?.cameraScreenController?.dismiss(animated: true, completion: nil)
                initializationCompletion?(.failure(error))
            }
        })
    }
}

extension CameraFrameCaptureModule: CameraFrameCaptureModuleInput {
    func launchFrameCaptureOn(hostController: UIViewController, initializationCompletion: CameraFrameCapture.InitializationCompletion?) {
        var cameraScreenController: UIViewController?
        
        cameraScreenModuleBuilder.build(completion: { [weak self, weak hostController] initializer in
            initializer.initializeModuleWith(controllerInHierarchyInsertion: {
                cameraScreenController = $0
                $0.modalPresentationStyle = .fullScreen
                hostController?.present($0, animated: true, completion: nil)
            }, completion: { [weak self, weak cameraScreenController, weak hostController] in
                guard let self = self,
                      let cameraScreenController = cameraScreenController,
                      let hostController = hostController else {
                          initializationCompletion?(.failure(.cameraModuleInitializationError(.cameraNotAvailable)))
                          return
                      }
                switch $0 {
                case .failure(let error):
                    initializationCompletion?(.failure(.cameraModuleInitializationError(error)))
                    cameraScreenController.dismiss(animated: true, completion: nil)
                    
                case .success(let input):
                    self.initializeModuleOn(hostController: hostController,
                                            cameraScreenController: cameraScreenController,
                                            input: input,
                                            initializationCompletion: initializationCompletion)
                }
            })
        })
    }
    
    func cancelFrameCapture() {
        cameraScreenModuleInput?.stopCapture()
        cameraScreenController?.dismiss(animated: true, completion: nil)
    }
    
    func captureNextFrame(handler: @escaping (Result<UIImage, CameraFrameCapture.PhotoCaptureError>) -> Void) {
        photoCaptureCompletion = {
            switch $0 {
            case .failure(let error):
                handler(.failure(.photoCaptureFailure(error)))
            case .success(let photo):
                guard let data = photo.fileDataRepresentation(),
                      let image = UIImage(data: data) else {
                          handler(.failure(.photoCaptureFailure(nil)))
                          return
                      }
                handler(.success(image))
            }
        }
        
        output.capturePhoto(with: .init(format: nil),
                            delegate: self)
    }
}


extension CameraFrameCaptureModule: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let error = error else {
            photoCaptureCompletion?(.success(photo))
            return
        }
        
        photoCaptureCompletion?(.failure(error))
    }
}
