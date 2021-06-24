//
//  ScanditError.swift
//  PSKNodeServer
//
//  Created by Zrust, Vladimir on 24.06.2021.
//

import Foundation

enum ScanditError: Error {
    case unableToRecognizeCompositeCode
    case scanCancelled
    
    var description: String {
        switch self {
        case .unableToRecognizeCompositeCode:
            return "Reached limit for repeating scan of composite codes"
        case .scanCancelled:
            return "User cancelled the scan"
        }
    }
}
