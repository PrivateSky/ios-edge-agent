//
//  ScanditScan.swift
//  PSKNodeServer
//
//  Created by Zrust, Vladimir on 16.06.2021.
//

import UIKit
import PSSmartWalletNativeLayer
import ScanditBarcodeCapture


struct ScanditScan {
    private static let supportedSymbologies: [Symbology] = [.gs1DatabarLimited, .microPDF417, .dataMatrix, .code128, .ean13UPCA]

    typealias ViewControllerProvider = () -> UIViewController
    static func implementationIn(controllerProvider: @autoclosure @escaping ViewControllerProvider) -> ApiImplementation {
        return { args, completion in
            guard let scanditApiKeyArray: [String] = args.first as? [String], let scanditApiKey = scanditApiKeyArray.first  else {
                completion(.failure(.init(code: "Scandit API key not passed to Scandit swift API")))
                return
            }
            
            let hostController = controllerProvider()
            let codeScannerViewController = ScanditScannerViewController(with: scanditApiKey, andWith: supportedSymbologies) { [weak hostController] result in
                switch result {
                case .success(let barcode):
                    let barcodeDataOutput = createBarcodeDataOutput(barcode: barcode)
                    DispatchQueue.main.async {
                        hostController?.dismiss(animated: true, completion: nil)
                    }
                    completion(.success(barcodeDataOutput))
                case .failure(let error):
                    DispatchQueue.main.async {
                        hostController?.dismiss(animated: true, completion: nil)
                    }
                    completion(.failure(.init(code: error.description)))
                }
            }
            codeScannerViewController.modalPresentationStyle = .fullScreen
            hostController.present(codeScannerViewController, animated: true)
        }
    }
    
    static func createBarcodeDataOutput(barcode: Barcode) -> [Value] {
        var barcodeOutput: [Value] = []
        
        if let barcodeData = barcode.data {
            barcodeOutput.append(.string(barcode.symbology.updatedDescription))
            barcodeOutput.append(.string(barcodeData))
        }
        
        if let compositeData = barcode.compositeData {
            // in composite codes, the composite part is always microPDF417 symbology
            barcodeOutput.append(.string(Symbology.microPDF417.updatedDescription))
            barcodeOutput.append(.string(compositeData))
        }
        
        return barcodeOutput
    }
}
