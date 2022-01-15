//
//  APICollection.swift
//  PSKNodeServer
//
//  Created by Costin Andronache on 12.01.2022.
//

import PSSmartWalletNativeLayer
import UIKit

struct APICollection {
    typealias APIInstance = (name: String, impl: APIImplementation)
    typealias StreamAPIInstance = (name: String, impl: StreamAPIImplementation)
    
    let apiList: [APIInstance]
    let streamAPIList: [StreamAPIInstance]
}


extension APICollection {
    static func setupAPICollection(viewControllerProvider: @autoclosure @escaping DataMatrixScanAPI.ViewControllerProvider) -> APICollection {
        /* This is the main function where each native API may be constructed/initialized */
        
        let dataMatrixAPI = setupDataMatrixScanModule(viewControllerProvider: viewControllerProvider())
        
        return APICollection(apiList: [("dataMatrixScan", dataMatrixAPI)],
                             streamAPIList: [])
    }
}

private extension APICollection {
    static func setupDataMatrixScanModule(viewControllerProvider: @autoclosure @escaping DataMatrixScanAPI.ViewControllerProvider) -> DataMatrixScanAPI {
        let camera2DMatrixScanModule = CameraMetadataScanModule(cameraScreenModuleBuilder: CameraScreenModuleBuilder(), searchedMetadataTypes: [.dataMatrix])
        return DataMatrixScanAPI(hostControllerProvider: viewControllerProvider(),
                                 camera2DMatrixScanModule: camera2DMatrixScanModule)
    }
}
