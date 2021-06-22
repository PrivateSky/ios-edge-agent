//
//  ScanditScannerViewController.swift
//  PSKNodeServer
//
//  Created by Zrust, Vladimir on 16.06.2021.
//

import UIKit
import ScanditBarcodeCapture

class ScanditScannerViewController: UIViewController {
    @IBOutlet weak var apiKeyLabel: UILabel!
    private let scanditApiKey: String
    private let symbologies: [Symbology]
    private let dataCaptureContext: DataCaptureContext
    private var barcodeCapture: BarcodeCapture
    
    override func viewDidLoad() {
        super.viewDidLoad()
        apiKeyLabel.text = scanditApiKey
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(with scanditApiKey: String, andWith symbologies: [Symbology]){
        self.scanditApiKey = scanditApiKey
        self.symbologies = symbologies
        self.dataCaptureContext = DataCaptureContext(licenseKey: scanditApiKey)
        
        let barcodeCaptureSettings = ScanditScannerViewController.createBarcodeCaptureSettings(with: symbologies)
        self.barcodeCapture = BarcodeCapture(context: dataCaptureContext, settings: barcodeCaptureSettings)
        
        super.init(nibName: "ScanditScannerViewController", bundle: nil)
    }
    
    private static func createBarcodeCaptureSettings(with symbologies: [Symbology]) -> BarcodeCaptureSettings {
        let barcodeCaptureSettings = BarcodeCaptureSettings()
        
        if symbologies.count > 0 {
            for symbology in symbologies {
                barcodeCaptureSettings.set(symbology: symbology, enabled: true)
            }
        }
        
        return barcodeCaptureSettings
    }
}
