//
//  CameraScreenModuleInput.swift
//  PSKNodeServer
//
//  Created by Costin Andronache on 10.01.2022.
//

import Foundation
import AVFoundation
import UIKit

enum CameraScreen {
    typealias Initializer = AnyModuleInitializer<CameraScreenModuleInput, InitializationError>
    typealias AddOutputFailReason = VideoCaptureSession.AddOutputFailReason
    typealias InitializationError = VideoCaptureSession.InitializationError
}

protocol CameraScreenModuleInput: AnyObject {
    var onUserCancelAction: VoidBlock? { get set }
    func stopCapture()
    func addOutput(_ output: AVCaptureOutput) -> Result<Void, CameraScreen.AddOutputFailReason>
    func removeOutput(_ output: AVCaptureOutput)
    func convertObjectCoordinatesIntoOwnBounds<T: AVMetadataObject>(object: T) -> T?
    func integrateOverlayView(_ view: UIView)
}

