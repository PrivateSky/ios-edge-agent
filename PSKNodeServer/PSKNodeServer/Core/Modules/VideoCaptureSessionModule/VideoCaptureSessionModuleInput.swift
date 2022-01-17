//
//  VideoCaptureSessionModuleInput.swift
//  PSKNodeServer
//
//  Created by Costin Andronache on 17.01.2022.
//

import Foundation

enum VideoCaptureSession {
    typealias Initializer = AnyViewlessModuleInitializer<VideoCaptureSessionModuleInput, InitializationError>
    enum AddOutputFailReason: Error {
        case featureNotAvailable
    }
    
    enum InitializationError: Error {
        case cameraNotAvailable
    }
}
