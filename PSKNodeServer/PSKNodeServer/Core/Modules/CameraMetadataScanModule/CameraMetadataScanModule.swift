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
    
    init(cameraScreenModuleInput: CameraScreenModuleInput,
         searchedMetadataTypes: [AVMetadataObject.ObjectType],
         exitModuleHandler: VoidBlock?) {
        self.cameraScreenModuleInput = cameraScreenModuleInput
        self.searchedMetadataTypes = searchedMetadataTypes
        self.exitModuleHandler = exitModuleHandler
        cameraScreenModuleInput.integrateOverlayView(scannerAnimationView)
    }
    
    func finalizeInitialization() -> Result<Void, CameraMetadataScan.Error> {
        let metadataOutput = AVCaptureMetadataOutput()
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        switch cameraScreenModuleInput.addOutput(metadataOutput) {
        case .success:
            guard metadataOutput.availableMetadataObjectTypes.containsAll(searchedMetadataTypes) else {
                 return .failure(.cameraModuleFunctionalityError(.featureNotAvailable))
            }
            metadataOutput.metadataObjectTypes = searchedMetadataTypes
        case .failure(let error):
            return  .failure(.cameraModuleFunctionalityError(error))
        }
        
        return .success(())
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
        self.completion = completion
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
