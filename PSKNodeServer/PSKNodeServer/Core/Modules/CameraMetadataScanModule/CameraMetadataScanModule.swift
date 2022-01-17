//
//  CameraMetadataScanModule.swift
//  PSKNodeServer
//
//  Created by Costin Andronache on 10.01.2022.
//

import AVFoundation
import UIKit

final class CameraMetadataScanModule: NSObject {
    private let cameraScreenModuleInput: CameraScreenModuleInput
    private let searchedMetadataTypes: [AVMetadataObject.ObjectType]
    private let exitModuleHandler: VoidBlock?
    
    private let scannerAnimationView: ScannerAnimationView = .init(frame: .zero)
    private let soundFile = CodeScannerSoundFile()
   
    private var completion: CameraMetadataScan.Completion?
    private var currentMetadataOutput: AVCaptureMetadataOutput?
    
    init(cameraScreenModuleInput: CameraScreenModuleInput,
         searchedMetadataTypes: [AVMetadataObject.ObjectType],
         exitModuleHandler: VoidBlock?) {
        self.cameraScreenModuleInput = cameraScreenModuleInput
        self.searchedMetadataTypes = searchedMetadataTypes
        self.exitModuleHandler = exitModuleHandler
        cameraScreenModuleInput.integrateOverlayView(scannerAnimationView)
    }
            
    private func beginScanningWith(completion: CameraMetadataScan.Completion?) {
        currentMetadataOutput.map {
            $0.setMetadataObjectsDelegate(nil, queue: nil)
            cameraScreenModuleInput.removeOutput($0)
        }
        
        self.completion = completion

        let metadataOutput = AVCaptureMetadataOutput()
        self.currentMetadataOutput = metadataOutput
        
        let metadataTypes = searchedMetadataTypes
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        switch cameraScreenModuleInput.addOutput(metadataOutput) {
        case .success:
            guard metadataOutput.availableMetadataObjectTypes.containsAll(metadataTypes) else {
                exitModuleWith(result: .failure(.cameraModuleFunctionalityError(.featureNotAvailable)))
                return
            }
            metadataOutput.metadataObjectTypes = metadataTypes
        case .failure(let error):
            exitModuleWith(result: .failure(.cameraModuleFunctionalityError(error)))
        }
        
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
    
    private func exitModuleWith(result: CameraMetadataScan.Result) {
        exitModuleHandler?()
        completion?(result)
    }
}

extension CameraMetadataScanModule: CameraMetadataScanModuleInput {
    func launchSingleScanOn(completion: CameraMetadataScan.Completion?) {
        beginScanningWith(completion: completion)
    }
}

extension CameraMetadataScanModule: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject {
            guard let readableObject = cameraScreenModuleInput.convertObjectCoordinatesIntoOwnBounds(object: metadataObject) else {
                return
            }
            
            guard let stringValue = readableObject.stringValue else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                self.playFocusAnimation(withinViewBoundsRect: readableObject.bounds,
                                        withSound: true,
                                        completion: { [weak self] in
                    self?.exitModuleWith(result: .success(stringValue))
                })
            }
            
            cameraScreenModuleInput.stopCapture()
            output.setMetadataObjectsDelegate(nil, queue: nil)
        }
    }
}
