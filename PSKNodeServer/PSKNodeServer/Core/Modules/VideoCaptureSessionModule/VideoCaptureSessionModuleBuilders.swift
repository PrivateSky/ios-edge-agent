//
//  VideoCaptureSessionModuleBuilders.swift
//  PSKNodeServer
//
//  Created by Costin Andronache on 18.01.2022.
//

import Foundation

enum VideoCaptureSessionModuleBuilders {
    
}

extension VideoCaptureSessionModuleBuilders {
    final class VideoPreviewCaptureSessionModuleBuilder: ViewlessModuleInitializer, VideoPreviewCaptureSessionModuleBuildable {
        typealias ModuleInputType = VideoPreviewCaptureSessionModuleInput
        typealias ErrorType = VideoCaptureSession.InitializationError
        
        func initializeModuleWith(completion: @escaping ViewlessModuleInitialization<VideoPreviewCaptureSessionModuleInput, VideoCaptureSession.InitializationError>.Completion) {
            VideoCaptureSessionModuleBuilders.buildAndInitializeVideoCaptureModule(completion: {
                switch $0 {
                case .failure(let error):
                    completion(.failure(error))
                case .success(let session):
                    completion(.success(session))
                }
            })
        }
        
        func build(completion: @escaping (AnyViewlessModuleInitializer<VideoPreviewCaptureSessionModuleInput, VideoCaptureSession.InitializationError>) -> Void) {
            completion(.init(aggregating: self))
        }
    }
    
    final class VideoCaptureSessionModuleBuilder: ViewlessModuleInitializer, VideoCaptureSessionModuleBuildable {
        typealias ModuleInputType = VideoCaptureSessionModuleInput
        typealias ErrorType = VideoCaptureSession.InitializationError
        
        func initializeModuleWith(completion: @escaping ViewlessModuleInitialization<VideoCaptureSessionModuleInput, VideoCaptureSession.InitializationError>.Completion) {
            VideoCaptureSessionModuleBuilders.buildAndInitializeVideoCaptureModule(completion: {
                switch $0 {
                case .failure(let error):
                    completion(.failure(error))
                case .success(let session):
                    completion(.success(session))
                }
            })
        }
        
        func build(completion: @escaping (AnyViewlessModuleInitializer<VideoCaptureSessionModuleInput, VideoCaptureSession.InitializationError>) -> Void) {
            completion(.init(aggregating: self))
        }
    }
    
    private static func buildAndInitializeVideoCaptureModule(completion: @escaping (Result<VideoCaptureSessionModule, VideoCaptureSession.InitializationError>) -> Void) {
        let session = VideoCaptureSessionModule()
        session.finalizeInitialization(completion: completion)
    }
}
