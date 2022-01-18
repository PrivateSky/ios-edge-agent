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
    
    private let output = AVCapturePhotoOutput()
    private var photoCaptureCompletion: ((Result<AVCapturePhoto, Error>) -> Void)?
    
    
    init(videoCaptureInput: VideoCaptureSessionModuleInput, exitHandler: VoidBlock?) {
        self.videoCaptureInput = videoCaptureInput
        self.exitHandler = exitHandler
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
        photoCaptureCompletion = {
            switch $0 {
            case .failure(let error):
                handler(.failure(.photoCaptureFailure(error)))
            case .success(let photo):
                guard let data = photo.fileDataRepresentation(),
                      let image = UIImage(data: data) else {
                          handler(.failure(.photoCaptureFailure(nil)))
                          return
                      }
                handler(.success(image))
            }
        }
        
        output.capturePhoto(with: .init(format: nil),
                            delegate: self)
    }
}


extension CameraFrameCaptureModule: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let error = error else {
            photoCaptureCompletion?(.success(photo))
            return
        }
        
        photoCaptureCompletion?(.failure(error))
    }
}
