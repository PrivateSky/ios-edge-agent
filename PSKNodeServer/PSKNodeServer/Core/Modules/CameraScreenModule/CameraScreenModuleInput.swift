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

protocol CameraScreenModuleInput: AnyObject, VideoCaptureSessionModuleInput {
    var onUserCancelAction: VoidBlock? { get set }
    func convertObjectCoordinatesIntoOwnBounds<T: AVMetadataObject>(object: T) -> T?
    func integrateOverlayView(_ view: UIView)
}

