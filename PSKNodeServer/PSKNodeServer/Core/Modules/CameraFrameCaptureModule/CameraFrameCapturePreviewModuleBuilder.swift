//
//  CameraFrameCaptureModuleBuilder.swift
//  PSKNodeServer
//
//  Created by Costin Andronache on 18.01.2022.
//

import UIKit

protocol CameraFrameCaptureModuleBuildable {
    func build(completion: @escaping (AnyViewlessModuleInitializer<CameraFrameCaptureModuleInput, CameraFrameCapture.Error>) -> Void)
}

final class CameraFrameCaptureModuleBuilder: CameraFrameCaptureModuleBuildable, ViewlessModuleInitializer {
    typealias ModuleInputType = CameraFrameCaptureModuleInput
    typealias ErrorType = CameraFrameCapture.Error
    
    private let videoCaptureSessionModuleBuilder: VideoCaptureSessionModuleBuildable
    
    init(videoCaptureSessionModuleBuilder: VideoCaptureSessionModuleBuildable) {
        self.videoCaptureSessionModuleBuilder = videoCaptureSessionModuleBuilder
    }
    
    func initializeModuleWith(completion: @escaping ViewlessModuleInitialization<CameraFrameCaptureModuleInput, CameraFrameCapture.Error>.Completion) {
        videoCaptureSessionModuleBuilder.build(completion: { initializer in
            initializer.initializeModuleWith(completion: {
                switch $0 {
                case .failure(let error):
                    completion(.failure(.cameraModuleInitializationError(error)))
                case .success(let videoCaptureSessionInput):
                    let module = CameraFrameCaptureModule(videoCaptureInput: videoCaptureSessionInput, exitHandler: nil)
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
    
    func build(completion: @escaping (AnyViewlessModuleInitializer<CameraFrameCaptureModuleInput, CameraFrameCapture.Error>) -> Void) {
        completion(.init(aggregating: self))
    }
}

final class CameraFrameCapturePreviewModuleBuilder:
    GenericCameraScreenModuleClientBuilder<CameraFrameCaptureModuleInput, CameraFrameCapture.Error>,
    CameraFrameCaptureModuleBuildable {
    init(hostController: UIViewController, cameraScreenModuleBuilder: CameraScreenModuleBuildable) {
        let frameCaptureInitializer: ClientModuleSpecificInitialization = {
            let module = CameraFrameCaptureModule(videoCaptureInput: $0, exitHandler: $1)
            switch module.finalizeInitialization() {
            case .success:
                $2(.success(module))
            case .failure(let error):
                $2(.failure(error))
            }
        }
        super.init(hostController: hostController,
                   cameraScreenModuleBuilder: cameraScreenModuleBuilder,
                   clientModuleInitialization: frameCaptureInitializer)
    }
    
    func build(completion: @escaping (AnyViewlessModuleInitializer<CameraFrameCaptureModuleInput, CameraFrameCapture.Error>) -> Void) {
        completion(.init(aggregating: self))
    }
   
}
