//
//  CameraScreenModuleInput.swift
//  PSKNodeServer
//
//  Created by Costin Andronache on 10.01.2022.
//

import Foundation
import AVFoundation
import UIKit

enum CameraScreenModule {
    typealias Initializer = AnyModuleInitializer<CameraScreenModuleInput, InitializationError>
    enum AddOutputFailReason: Error {
        case featureNotAvailable
    }
    
    enum InitializationError: Error {
        case cameraNotAvailable
    }
    
    typealias AddOutputCompletion = (Result<Void, AddOutputFailReason>) -> Void
    typealias CaptureFrameCompletion = (UIImage) -> Void
}

protocol CameraScreenModuleInput: AnyObject {
    var onUserCancelAction: VoidBlock? { get set }
    func stopCapture()
    func addOutput(_ output: AVCaptureOutput, completion: CameraScreenModule.AddOutputCompletion?)
    func convertObjectCoordinatesIntoOwnBounds<T: AVMetadataObject>(object: T) -> T?
    func integrateOverlayView(_ view: UIView)
}

