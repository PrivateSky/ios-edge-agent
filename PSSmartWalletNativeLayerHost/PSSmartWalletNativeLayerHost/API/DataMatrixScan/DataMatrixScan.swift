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
                    completion(.failure(.init(localizedDescription: error.description)))
                }
            }
            hostController.present(codeScannerController, animated: true)
        }
    }
}

fileprivate extension CodeScannerViewController.FailReason {
    var description: String {
        switch self {
        case .noCodeFound:
            return "No code found, timeout"
        case .featureNotAvailable:
            return "Code type not available"
        case .cameraUnavailable:
            return "Camera access denied"
        }
    }
}
