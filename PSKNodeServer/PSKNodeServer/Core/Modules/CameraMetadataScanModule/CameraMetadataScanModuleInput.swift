//
//  CameraMetadataScanModule.swift
//  PSKNodeServer
//
//  Created by Costin Andronache on 10.01.2022.
//

import AVFoundation
import UIKit

enum CameraMetadataScan {
    enum Error: Swift.Error {
        case cameraModuleInitializationError(CameraScreenModule.InitializationError)
        case cameraModuleFunctionalityError(CameraScreenModule.AddOutputFailReason)
        case userCancelled
    }
    
    typealias Completion = (Result<String, Error>) -> Void
}


protocol CameraMetadataScanModuleInput {
    func launchSingleScanOn(hostController: UIViewController, completion: CameraMetadataScan.Completion?)
}

final class CameraMetadataScanModule: NSObject {
    private var cameraScreenModuleInput: CameraScreenModuleInput?
    private var completion: CameraMetadataScan.Completion?
    private let cameraScreenModuleBuilder: CameraScreenModuleBuildable
    private let searchedMetadataTypes: [AVMetadataObject.ObjectType]
    
    private let scannerAnimationView: ScannerAnimationView = .init(frame: .zero)
    private let soundFile = CodeScannerSoundFile()
    
    init(cameraScreenModuleBuilder: CameraScreenModuleBuildable, searchedMetadataTypes: [AVMetadataObject.ObjectType]) {
        self.cameraScreenModuleBuilder = cameraScreenModuleBuilder
        self.searchedMetadataTypes = searchedMetadataTypes
    }
            
    private func beginScanningWith(cameraScreenModuleInput: CameraScreenModuleInput,
                                   completion: CameraMetadataScan.Completion?) {
        self.cameraScreenModuleInput = cameraScreenModuleInput
        self.completion = completion
        
        cameraScreenModuleInput.integrateOverlayView(scannerAnimationView)
        
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
    
    private func playFocusAnimation(withinViewBoundsRect rect: CGRect, withSound: Bool, completion: VoidBlock?) {
        scannerAnimationView.focusOn(rect: rect, completion: { [weak self] in
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            if withSound {
                self?.soundFile.play()
            }
            completion?()
        })
    }
}

extension CameraMetadataScanModule: CameraMetadataScanModuleInput {
    func launchSingleScanOn(hostController: UIViewController, completion: CameraMetadataScan.Completion?) {
        var moduleController: UIViewController?
        
        cameraScreenModuleBuilder.build(completion: { [weak hostController] initializer in
            initializer.initializeModuleWith(controllerInHierarchyInsertion: { controller in
                moduleController = controller
                controller.modalPresentationStyle = .fullScreen
                hostController?.present(controller, animated: true, completion: nil)
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

extension CameraMetadataScanModule: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject {
            guard let readableObject = cameraScreenModuleInput?.convertObjectCoordinatesIntoOwnBounds(object: metadataObject) else {
                return
            }
            
            guard let stringValue = readableObject.stringValue else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                self.playFocusAnimation(withinViewBoundsRect: readableObject.bounds,
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
