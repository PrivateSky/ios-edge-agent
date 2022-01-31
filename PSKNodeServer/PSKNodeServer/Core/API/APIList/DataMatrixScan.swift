//
//  DataMatrixScan.swift
//  PSSmartWalletNativeLayerDemo
//
//  Created by Costin Andronache on 12/23/20.
//

import UIKit
import PSSmartWalletNativeLayer

class DataMatrixScanAPI: APIImplementation {
    typealias ViewControllerProvider = () -> UIViewController
    private let camera2DMatrixScanModuleBuilder: CameraMetadataScanModuleBuildable
    
    private var cameraMetadaScanModuleInput: CameraMetadataScanModuleInput?
    
    init(camera2DMatrixScanModuleBuilder: CameraMetadataScanModuleBuildable) {
        self.camera2DMatrixScanModuleBuilder = camera2DMatrixScanModuleBuilder
    }
    
    func perform(_ inputArguments: [APIValue], _ completion: @escaping APIResultCompletion) {
        camera2DMatrixScanModuleBuilder.build(completion: { initializer in
            initializer.initializeModuleWith(completion: { [weak self] in
                switch $0 {
                case .failure(let error):
                    completion(.failure(.init(code: error.code)))
                case .success(let metadaScanInput):
                    self?.launchMetadataScanWith(input: metadaScanInput,
                                                completion: completion)
                }
            })
        })
    }
    
    private func launchMetadataScanWith(input: CameraMetadataScanModuleInput,
                                        completion: @escaping APIResultCompletion) {
        self.cameraMetadaScanModuleInput = input
        input.launchSingleScanOn(completion: {
            switch $0 {
            case .failure(let error):
                completion(.failure(.init(code: error.code)))
            case .success(let code):
                completion(.success([.string(code)]))
            }
        })
    }
}

extension VideoCaptureSession.InitializationError {
    var code: String {
        switch self {
        case .cameraNotAvailable:
            return "ERR_CAM_UNAVAILABLE"
        }
    }
}

extension VideoCaptureSession.AddOutputFailReason {
    var code: String {
        switch self {
        case .featureNotAvailable:
            return "ERR_SCAN_NOT_SUPPORTED"
        }
    }
}

extension CameraMetadataScan.Error {
    var code: String {
        switch self {
        case .cameraModuleInitializationError(let initError):
            return initError.code
        case .cameraModuleFunctionalityError(let featureError):
            return featureError.code
        case .userCancelled:
            return "ERR_USER_CANCELLED"
        }
    }
}
