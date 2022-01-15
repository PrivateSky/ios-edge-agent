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
    typealias CapturedFrameHandler = (UIImage) -> Void
    typealias InitializationCompletion = (Result<Void, Error>) -> Void
}

protocol CameraFrameCaptureModuleInput {
    func launchFrameCaptureOn(hostController: UIViewController, initializationCompletion: CameraFrameCapture.InitializationCompletion)
    func cancelFrameCapture()
    func captureNextFrame(handler: CameraFrameCapture.CapturedFrameHandler)
}


final class CameraFrameCaptureModule {
    
}


extension CameraFrameCaptureModule: AVCaptureVideoDataOutputSampleBufferDelegate {
    
}
