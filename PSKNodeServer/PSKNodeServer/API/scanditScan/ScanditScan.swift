//
//  ScanditScan.swift
//  PSKNodeServer
//
//  Created by Zrust, Vladimir on 16.06.2021.
//

import UIKit
import PSSmartWalletNativeLayer
import ScanditBarcodeCapture

let SUPPORTED_SYMBOLOGIES: [Symbology] = [.gs1DatabarLimited, .microPDF417]

struct ScanditScan {
    typealias ViewControllerProvider = () -> UIViewController
    static func implementationIn(controllerProvider: @autoclosure @escaping ViewControllerProvider) -> ApiImplementation {
        return { args, completion in
            // TODO: remove debug prints
            print("ScandItScan completion")
            
            // TODO: create decoder for ApiKey args object with proper error handling
            guard let scanditApiKeyArray: [String] = args.first as? [String], let scanditApiKey = scanditApiKeyArray.first  else {
                completion(.failure(.init(code: "Scandit API key not passed to Scandit swift API")))
                print("Scandit API key not passed to Scandit swift API")
                return
            }
            
            let hostController = controllerProvider()
            let codeScannerViewController = ScanditScannerViewController(with: scanditApiKey, andWith: SUPPORTED_SYMBOLOGIES)
            codeScannerViewController.modalPresentationStyle = .fullScreen
            hostController.present(codeScannerViewController, animated: true)
                        
            completion(.success([.string("ScanditScan completed")])) 
        }
    }
}
