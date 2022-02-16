//
//  CameraFrameCaptureModuleBuilder.swift
//  PSKNodeServer
//
//  Created by Costin Andronache on 18.01.2022.
//

import UIKit

protocol CameraFrameCaptureModuleBuildable {
    func build(pixelFormat: CameraFrameCapture.PixelFormat,
               completion: @escaping (AnyViewlessModuleInitializer<CameraFrameCaptureModuleInput, CameraFrameCapture.InitializationError>) -> Void)
}

final class CameraFrameCaptureModuleBuilder: CameraFrameCaptureModuleBuildable, ViewlessModuleInitializer {
    typealias ModuleInputType = CameraFrameCaptureModuleInput
    typealias ErrorType = CameraFrameCapture.InitializationError
    
    private let videoCaptureSessionModuleBuilder: VideoCaptureSessionModuleBuildable
    private var pixelFormat = CameraFrameCapture.PixelFormat.defaultDeviceFormat
    
    init(videoCaptureSessionModuleBuilder: VideoCaptureSessionModuleBuildable) {
        self.videoCaptureSessionModuleBuilder = videoCaptureSessionModuleBuilder
    }
    
    func initializeModuleWith(completion: @escaping ViewlessModuleInitialization<CameraFrameCaptureModuleInput, CameraFrameCapture.InitializationError>.Completion) {
        let pixelFormat = self.pixelFormat
        videoCaptureSessionModuleBuilder.build(completion: { initializer in
            initializer.initializeModuleWith(completion: {
                switch $0 {
                case .failure(let error):
                    completion(.failure(.cameraModuleInitializationError(error)))
                case .success(let videoCaptureSessionInput):
                    let module = CameraFrameCaptureModule(pixelFormat: pixelFormat,
                                                          videoCaptureInput: videoCaptureSessionInput, exitHandler: nil)
                    switch module.finalizeInitialization() {
                    case .failure(let error):
                        completion(.failure(error))
                    case .success:
                        completion(.success(module))
                    }
                }
            })
        })
    }
    
    func build(pixelFormat: CameraFrameCapture.PixelFormat,
               completion: @escaping (AnyViewlessModuleInitializer<CameraFrameCaptureModuleInput, CameraFrameCapture.InitializationError>) -> Void) {
        self.pixelFormat = pixelFormat
        completion(.init(aggregating: self))
    }
}
