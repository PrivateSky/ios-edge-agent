//
//  CameraMetadataScanModuleBuilder.swift
//  PSKNodeServer
//
//  Created by Costin Andronache on 17.01.2022.
//

import AVFoundation
import UIKit

protocol CameraMetadataScanModuleBuildable {
    func build(completion: @escaping (AnyViewlessModuleInitializer<CameraMetadataScanModuleInput, CameraMetadataScan.Error>) -> Void)
}

extension CameraMetadataScan.Error: HasCameraModuleErrors { }

final class CameraMetadataScanModuleBuilder: GenericCameraScreenModuleClientBuilder<CameraMetadataScanModuleInput,CameraMetadataScan.Error>, CameraMetadataScanModuleBuildable {
        
    init(hostController: UIViewController,
         cameraScreenModuleBuilder: CameraScreenModuleBuildable,
         searchedMetadataTypes: [AVMetadataObject.ObjectType]) {
        
        let metadataScanInitialization: ClientModuleSpecificInitialization = {
            let module = CameraMetadataScanModule(cameraScreenModuleInput: $0,
                                     searchedMetadataTypes: searchedMetadataTypes,
                                     exitModuleHandler: $1)
            switch module.finalizeInitialization() {
            case .success:
                $2(.success(module))
            case .failure(let error):
                $2(.failure(error))
            }
        }
        
        super.init(hostController: hostController,
                   cameraScreenModuleBuilder: cameraScreenModuleBuilder,
                   clientModuleInitialization: metadataScanInitialization)
    }
    
    func build(completion: @escaping (AnyViewlessModuleInitializer<CameraMetadataScanModuleInput, CameraMetadataScan.Error>) -> Void) {
        completion(.init(aggregating: self))
    }
}
