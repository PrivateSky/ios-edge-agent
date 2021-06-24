//
//  ScanditScannerViewController.swift
//  PSKNodeServer
//
//  Created by Zrust, Vladimir on 16.06.2021.
//

import UIKit
import ScanditBarcodeCapture

class ScanditScannerViewController: UIViewController {
    private let symbologies: [Symbology]
    private let dataCaptureContext: DataCaptureContext
    private var barcodeCapture: BarcodeCapture
    private var completionHandler: (Result<Barcode, ScanditError>) -> Void
    private let compositeCodeRepeatedScanLimit = 100
    private var compositeCodeRepeatedScanCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        barcodeCapture.addListener(self)
        
        let cameraSettings = BarcodeCapture.recommendedCameraSettings
        Camera.default?.apply(cameraSettings)
        dataCaptureContext.setFrameSource(Camera.default)
        Camera.default?.switch(toDesiredState: .on)
        
        let captureView = DataCaptureView(context: dataCaptureContext, frame: view.bounds)
        captureView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(captureView)
        
        _ = BarcodeCaptureOverlay(barcodeCapture: barcodeCapture, view: captureView)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        barcodeCapture.removeListener(self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(with scanditApiKey: String, andWith symbologies: [Symbology], _ completion: @escaping (Result<Barcode, ScanditError>) -> Void) {
        self.symbologies = symbologies
        self.dataCaptureContext = DataCaptureContext(licenseKey: scanditApiKey)
        self.completionHandler = completion
        
        let barcodeCaptureSettings = ScanditScannerViewController.createBarcodeCaptureSettings(with: symbologies)
        self.barcodeCapture = BarcodeCapture(context: dataCaptureContext, settings: barcodeCaptureSettings)
        
        super.init(nibName: "ScanditScannerViewController", bundle: nil)
    }
    
    private static func createBarcodeCaptureSettings(with symbologies: [Symbology]) -> BarcodeCaptureSettings {
        let barcodeCaptureSettings = BarcodeCaptureSettings()
        
        let compositeTypes: CompositeType = [.a, .b, .c]
        barcodeCaptureSettings.enableSymbologies(forCompositeTypes: compositeTypes)
        barcodeCaptureSettings.enabledCompositeTypes = compositeTypes
        
        for symbology in symbologies {
            barcodeCaptureSettings.set(symbology: symbology, enabled: true)
        }
        
        return barcodeCaptureSettings
    }
}

extension ScanditScannerViewController: BarcodeCaptureListener {
  func barcodeCapture(_ barcodeCapture: BarcodeCapture, didScanIn session: BarcodeCaptureSession, frameData: FrameData) {
    let recognizedBarcodes = session.newlyRecognizedBarcodes

    guard let barcode = recognizedBarcodes.first else {
        return
    }

    // Wait for both parts of composite code - data(GS1DatabarLimited) and compositeData(microPdf417)
    // Currently only composite codes with GS1DataBarLimited are supported, GS1DataBarLimited as standalone is not supported
    if barcode.symbology == .gs1DatabarLimited,
       barcode.compositeData == nil,
       compositeCodeRepeatedScanCount < compositeCodeRepeatedScanLimit {
        compositeCodeRepeatedScanCount += 1
        return
    }
    
    Camera.default?.switch(toDesiredState: .off)
    barcodeCapture.isEnabled = false
    
    guard  compositeCodeRepeatedScanCount < compositeCodeRepeatedScanLimit else {
        compositeCodeRepeatedScanCount = 0
        completionHandler(.failure(ScanditError.unableToRecognizeCompositeCode))
        return
    }
    
    compositeCodeRepeatedScanCount = 0
    completionHandler(.success(barcode))
  }
}

