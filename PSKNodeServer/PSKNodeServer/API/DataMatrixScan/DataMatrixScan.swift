//
//  DataMatrixScan.swift
//  PSSmartWalletNativeLayerDemo
//
//  Created by Costin Andronache on 12/23/20.
//

import UIKit
import PSSmartWalletNativeLayer

struct DataMatrixScan {
    typealias ViewControllerProvider = () -> UIViewController
    static func implementationIn(controllerProvider: @autoclosure @escaping ViewControllerProvider) -> ApiImplementation {
        return { _, completion in
            let hostController = controllerProvider()
            let codeScannerController = CodeScannerViewController()
            codeScannerController.searchedMetadata = [.dataMatrix]
            codeScannerController.completion = { [weak hostController] result in
                hostController?.dismiss(animated: true, completion: nil)
                switch result {
                case .success(let code):
                    completion(.success([.string(code)]))
                case .failure(let error):
                    if error == .cameraUnavailable {
                        UIAlertController.okMessage(in: hostController, message: NSLocalizedString("info_camera_access_denied", comment: "")) {
                        }                        
                    }
                    completion(.failure(.init(code: error.code)))
                }
            }
            codeScannerController.modalPresentationStyle = .fullScreen
            hostController.present(codeScannerController, animated: true)
        }
    }
}

fileprivate extension CodeScannerViewController.FailReason {
    var code: String {
        switch self {
        case .noCodeFound:
            return "ERR_NO_CODE_FOUND"
        case .featureNotAvailable:
            return "ERR_SCAN_NOT_SUPPORTED"
        case .cameraUnavailable:
            return "ERR_CAM_UNAVAILABLE"
        case .userCancelled:
            return "ERR_USER_CANCELLED"
        }
    }
}
