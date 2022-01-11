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
    
}

final class Camera2DMatrixScanModule: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    
    private var cameraScreenModule: CameraScreenModule?
    private var completion: Camera2DMatrixScanCompletion?
    
    func performScanOn(hostController: UIViewController,
                       cameraScreenModuleBuilder: CameraScreenModuleBuildable,
                       completion: Camera2DMatrixScanCompletion?) {
        
        self.completion = completion
        cameraScreenModuleBuilder.build(completion: { [weak self] cameraModuleResult in
            switch cameraModuleResult {
            case .failure(let cameraInitError):
                completion?(.failure(.cameraModuleInitializationError(cameraInitError)))
            case .success(let module):
                self?.cameraScreenModule = module
                self?.beginScanningWith(cameraScreenModule: module)
            }
        })
    }
        
    private func beginScanningWith(cameraScreenModule: CameraScreenModule) {
        let metadataOutput = AVCaptureMetadataOutput()
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        metadataOutput.metadataObjectTypes = [.dataMatrix]
        cameraScreenModule.input.
    }
    
    
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {

        if let metadataObject = metadataObjects.first {
            guard let readableObject = connection.videoPreviewLayer?.transformedMetadataObject(for: metadataObject) as? AVMetadataMachineReadableCodeObject else {
                return
            }
            
            guard let stringValue = readableObject.stringValue else { return }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                self.cameraScreenModule?.input.playFocusAnimation(withinViewBoundsRect: readableObject.bounds,
                                                                  withSound: true,
                                                                  completion: { [weak self] in
                    self?.
                })
            }
            captureSession?.stopRunning()
            output.setMetadataObjectsDelegate(nil, queue: nil)
        }

    }
}
