//
//  CameraMetadataScanModuleInput.swift
//  PSKNodeServer
//
//  Created by Costin Andronache on 17.01.2022.
//

import Foundation

enum CameraMetadataScan {
    enum Error: Swift.Error {
        case cameraModuleInitializationError(CameraScreen.InitializationError)
        case cameraModuleFunctionalityError(CameraScreen.AddOutputFailReason)
        case userCancelled
    }
    typealias Result = Swift.Result<String, Error>
    
    typealias Completion = (Result) -> Void
}


protocol CameraMetadataScanModuleInput {
    func launchSingleScanOn(completion: CameraMetadataScan.Completion?)
}
