//
//  Camera2DMatrixScanModuleInput.swift
//  PSKNodeServer
//
//  Created by Costin Andronache on 10.01.2022.
//

import AVFoundation
import UIKit

enum Camera2DMatrixScanError: Error {
    case cameraModuleInitializationError(CameraScreenModule.InitializationError)
    case cameraModuleFunctionalityError(CameraScreenModule.AddOutputFailReason)
    case userCancelled
}

typealias Camera2DMatrixScanCompletion = (Result<String, Camera2DMatrixScanError>) -> Void

protocol Camera2DMatrixScanModuleInput {
    func launchSingleScanOn(hostController: UIViewController, completion: Camera2DMatrixScanCompletion?)
}

final class Camera2DMatrixScanModule: NSObject {
    private var cameraScreenModuleInput: CameraScreenModuleInput?
    private var completion: Camera2DMatrixScanCompletion?
    private let cameraScreenModuleBuilder: CameraScreenModuleBuildable
    private let searchedMetadataTypes: [AVMetadataObject.ObjectType] = [.dataMatrix, .qr]
    
    init(cameraScreenModuleBuilder: CameraScreenModuleBuildable) {
        self.cameraScreenModuleBuilder = cameraScreenModuleBuilder
    }
            
    private func beginScanningWith(cameraScreenModuleInput: CameraScreenModuleInput,
                                   completion: Camera2DMatrixScanCompletion?) {
        self.cameraScreenModuleInput = cameraScreenModuleInput
        self.completion = completion
        
        let metadataOutput = AVCaptureMetadataOutput()
        let metadataTypes = searchedMetadataTypes
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        cameraScreenModuleInput.addOutput(metadataOutput, completion: {
            switch $0 {
            case .success:
                guard metadataOutput.availableMetadataObjectTypes.containsAll(metadataTypes) else {
                    completion?(.failure(.cameraModuleFunctionalityError(.featureNotAvailable)))
                    return
                }
                metadataOutput.metadataObjectTypes = metadataTypes
            case .failure(let error):
                completion?(.failure(.cameraModuleFunctionalityError(error)))
            }
        })
    }
    
}

extension Camera2DMatrixScanModule: Camera2DMatrixScanModuleInput {
    func launchSingleScanOn(hostController: UIViewController, completion: Camera2DMatrixScanCompletion?) {
        var moduleController: UIViewController?
        
        cameraScreenModuleBuilder.build(completion: { [weak hostController] initializer in
            initializer.initializeModuleWith(controllerInHierarchyInsertion: {
                moduleController = $0
                $0.modalPresentationStyle = .fullScreen
                hostController?.present($0, animated: true, completion: $1)
            }, completion: { [weak self] in 
                switch $0 {
                case .failure(let initializationError):
                    completion?(.failure(.cameraModuleInitializationError(initializationError)))
                    moduleController?.dismiss(animated: true, completion: nil)
                case .success(let input):
                    input.onUserCancelAction = { [weak moduleController] in
                        completion?(.failure(.userCancelled))
                        moduleController?.dismiss(animated: true, completion: nil)
                    }
                    self?.beginScanningWith(cameraScreenModuleInput: input,
                                            completion: { [weak moduleController] in
                        moduleController?.dismiss(animated: true, completion: nil)
                        completion?($0)
                    })
                }
            })
        })
    }
}

extension Camera2DMatrixScanModule: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject {
            guard let readableObject = cameraScreenModuleInput?.convertObjectCoordinatesIntoOwnBounds(object: metadataObject) else {
                return
            }
            
            guard let stringValue = readableObject.stringValue else { return }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                self.cameraScreenModuleInput?.playFocusAnimation(withinViewBoundsRect: readableObject.bounds,
                                                                  withSound: true,
                                                                  completion: { [weak self] in
                    self?.completion?(.success(stringValue))
                })
            }
            cameraScreenModuleInput?.stopCapture()
            output.setMetadataObjectsDelegate(nil, queue: nil)
        }

    }
}
