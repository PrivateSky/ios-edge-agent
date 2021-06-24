//
//  SymbologyExtension.swift
//  PSKNodeServer
//
//  Created by Zrust, Vladimir on 24.06.2021.
//

import ScanditBarcodeCapture

extension Symbology {
    // Some descriptions do not comply with documentation - this extension is to keep consistency for used symbologies
    // https://docs.scandit.com/stable/web/enums/barcode.symbology-1.html#micro_pdf417
    var updatedDescription: String {
        switch self {
        case .gs1DatabarLimited:
            return "databar-limited"
        case .dataMatrix:
            return "data-matrix"
        case .microPDF417:
            return "micropdf417"
        case .ean13UPCA:
            return "ean13"
        default:
            return self.description
        }
    }
}
