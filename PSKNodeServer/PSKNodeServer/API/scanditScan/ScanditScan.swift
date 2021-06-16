//
//  scanditScan.swift
//  PSKNodeServer
//
//  Created by Zrust, Vladimir on 16.06.2021.
//

import UIKit
import PSSmartWalletNativeLayer

struct ScanditScan {
    typealias ViewControllerProvider = () -> UIViewController
    static func implementationIn(controllerProvider: @autoclosure @escaping ViewControllerProvider) -> ApiImplementation {
        return { _, completion in
            print("ScandItScan completion")
            completion(.success([.string("ScanditScan completed")]))
        }
    }
}
