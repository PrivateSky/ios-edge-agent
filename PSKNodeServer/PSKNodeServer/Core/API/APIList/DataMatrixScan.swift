//
//  DataMatrixScan.swift
//  PSSmartWalletNativeLayerDemo
//
//  Created by Costin Andronache on 12/23/20.
//

import UIKit
import PSSmartWalletNativeLayer

struct DataMatrixScanAPI: APIImplementation {
    typealias ViewControllerProvider = () -> UIViewController

    private let hostControllerProvider: ViewControllerProvider
    private let camera2DMatrixScanModule: CameraMetadataScanModuleInput
    
    init(hostControllerProvider: @autoclosure @escaping ViewControllerProvider,
         camera2DMatrixScanModule: CameraMetadataScanModuleInput) {
        self.hostControllerProvider = hostControllerProvider
        self.camera2DMatrixScanModule = camera2DMatrixScanModule
    }
    
    func perform(_ inputArguments: [APIValue], _ completion: @escaping APIResultCompletion) {
        performNew(inputArguments, completion)
    }
    
    func performOld(_ inputArguments: [APIValue], _ completion: @escaping APIResultCompletion) {
        let controller = CodeScannerViewController()
        controller.searchedMetadata = [.dataMatrix]
        
        controller.completion = { [weak controller] in
            switch $0 {
            case .failure(let reason):
                completion(.failure(.init(code: "ERR_USER_CANCEL")))
            case .success(let code):
                completion(.success([.string(code)]))
            }
            
            controller?.dismiss(animated: true, completion: nil)
        }
        
        hostControllerProvider().present(controller, animated: true, completion: nil)
    }
    
    func performNew(_ inputArguments: [APIValue], _ completion: @escaping APIResultCompletion) {
        let hostController = hostControllerProvider()
        camera2DMatrixScanModule.launchSingleScanOn(hostController: hostController,
                                                     completion: {
            switch $0 {
            case .failure(let error):
                completion(.failure(.init(code: error.code)))
            case .success(let code):
                completion(.success([.string(code)]))
            }
        })
    }
}

extension CameraMetadataScan.Error {
    var code: String {
        switch self {
        case .cameraModuleInitializationError(let initError):
            switch initError {
            case .cameraNotAvailable:
                return "ERR_CAM_UNAVAILABLE"
            }
        case .cameraModuleFunctionalityError(let featureError):
            switch featureError {
            case .featureNotAvailable:
                return "ERR_SCAN_NOT_SUPPORTED"
            }
        case .userCancelled:
            return "ERR_USER_CANCELLED"
        }
    }
}
