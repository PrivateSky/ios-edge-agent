//
//  CameraFrameCaptureModule.swift
//  PSKNodeServer
//
//  Created by Costin Andronache on 15.01.2022.
//

import Foundation
import AVFoundation
import UIKit

final class CameraFrameCaptureModule: NSObject {
    private let videoCaptureInput: VideoCaptureSessionModuleInput
    private let exitHandler: VoidBlock?
    
    private let output = AVCaptureVideoDataOutput()
    private var photoCaptureCompletion: ((Result<UIImage, Error>) -> Void)?
    
    
    init(videoCaptureInput: VideoCaptureSessionModuleInput, exitHandler: VoidBlock?) {
        self.videoCaptureInput = videoCaptureInput
        self.exitHandler = exitHandler
        super.init()
    }
    
    func finalizeInitialization() -> Result<Void, CameraFrameCapture.Error> {
        switch videoCaptureInput.addOutput(output) {
        case .success:
            return .success(())
        case .failure(let error):
            return .failure(.cameraModuleFunctionalityError(error))
        }

    }
}

extension CameraFrameCaptureModule: CameraFrameCaptureModuleInput {
    func cancelFrameCapture() {
        videoCaptureInput.stopCapture()
        exitHandler?()
    }
    
    func captureNextFrame(handler: @escaping (Result<UIImage, CameraFrameCapture.PhotoCaptureError>) -> Void) {
        output.setSampleBufferDelegate(self, queue: .main)
        photoCaptureCompletion = { [weak self] in
            self?.output.setSampleBufferDelegate(nil, queue: nil)
            switch $0 {
            case .failure(let error):
                handler(.failure(.photoCaptureFailure(error)))
            case .success(let image):
                handler(.success(image))
            }
        }
        
        
    }
}


extension CameraFrameCaptureModule: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        let ciimage = CIImage(cvPixelBuffer: imageBuffer)
        let image = self.convert(cmage: ciimage)
        photoCaptureCompletion?(.success(image))
    }
    
    // Convert CIImage to UIImage
    func convert(cmage: CIImage) -> UIImage {
        let context = CIContext(options: nil)
        let cgImage = context.createCGImage(cmage, from: cmage.extent)!
        let image = UIImage(cgImage: cgImage, scale: 1.0, orientation: .right)
        return image
    }
}
