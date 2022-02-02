//
//  ScanditScanAPI.swift
//  PSKNodeServer
//
//  Created by Costin Andronache on 02.02.2022.
//

import UIKit
import PSSmartWalletNativeLayer
import ScanditBarcodeCapture

struct ScanditScanAPI: APIImplementation {
    typealias ViewControllerProvider = () -> UIViewController
    
    private static let supportedSymbologies: [Symbology] = [.gs1DatabarLimited, .microPDF417, .dataMatrix, .code128, .ean13UPCA]
    private let viewControllerProvider: ViewControllerProvider
    
    init(viewControllerProvider: @escaping ViewControllerProvider) {
        self.viewControllerProvider = viewControllerProvider
    }
    
    func perform(_ args: [APIValue], _ completion: @escaping APIResultCompletion) {
        guard let firstElement = args.first,
              case let .string(scanditApiKey) = firstElement else {
                  completion(.failure(.init(code: APIError.apiKeyNotFound.rawValue)))
            return
        }
        
        let hostController = viewControllerProvider()
        let codeScannerViewController = ScanditScannerViewController(with: scanditApiKey, andWith: Self.supportedSymbologies) { [weak hostController] result in
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

    func createBarcodeDataOutput(barcode: Barcode) -> [APIValue] {
        var barcodeOutput: [APIValue] = []
        
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

extension ScanditScanAPI {
    enum APIError: String {
        case apiKeyNotFound = "Scandit API key not passed to Scandit swift API"
    }
}
