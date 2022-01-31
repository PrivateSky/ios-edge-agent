//
//  CameraFrameCaptureModuleInput.swift
//  PSKNodeServer
//
//  Created by Costin Andronache on 18.01.2022.
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
    func cancelFrameCapture()
    func captureNextFrame(handler: @escaping CameraFrameCapture.CapturedFrameHandler)
}
