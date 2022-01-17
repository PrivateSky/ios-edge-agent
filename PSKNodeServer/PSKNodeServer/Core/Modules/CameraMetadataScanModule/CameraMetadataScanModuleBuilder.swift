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

class CameraMetadataScanModuleBuilder: ViewlessModuleInitializer, CameraMetadataScanModuleBuildable {
    typealias ModuleInputType = CameraMetadataScanModuleInput
    typealias ErrorType = CameraMetadataScan.Error
    
    private let cameraScreenModuleBuilder: CameraScreenModuleBuildable
    private let searchedMetadataTypes: [AVMetadataObject.ObjectType]
    private let hostController: UIViewController
    
    private var cameraScreenController: UIViewController?
    
    init(hostController: UIViewController,
         cameraScreenModuleBuilder: CameraScreenModuleBuildable,
         searchedMetadataTypes: [AVMetadataObject.ObjectType]) {
        self.cameraScreenModuleBuilder = cameraScreenModuleBuilder
        self.searchedMetadataTypes = searchedMetadataTypes
        self.hostController = hostController
    }
    
    func initializeModuleWith(completion: @escaping ViewlessModuleInitialization<CameraMetadataScanModuleInput, CameraMetadataScan.Error>.Completion) {
        let dismissModuleController: VoidBlock = { [weak self] in
            self?.cameraScreenController?.dismiss(animated: true, completion: nil)
        }
        let searchedMetadataTypes = self.searchedMetadataTypes
        
        cameraScreenModuleBuilder.build(completion: { [weak hostController, weak self] initializer in
            initializer.initializeModuleWith(controllerInHierarchyInsertion: { controller in
                self?.cameraScreenController = controller
                controller.modalPresentationStyle = .fullScreen
                hostController?.present(controller, animated: true, completion: nil)
            }, completion: {
                switch $0 {
                case .failure(let initializationError):
                    completion(.failure(.cameraModuleInitializationError(initializationError)))
                    dismissModuleController()
                case .success(let cameraScreenInput):
                    cameraScreenInput.onUserCancelAction = {
                        completion(.failure(.userCancelled))
                        dismissModuleController()
                    }
                    let metadataScanModule = CameraMetadataScanModule(cameraScreenModuleInput: cameraScreenInput,
                                                                      searchedMetadataTypes: searchedMetadataTypes, exitModuleHandler: dismissModuleController)
                    completion(.success(metadataScanModule))
                }
            })
        })
    }
    
    func build(completion: @escaping (AnyViewlessModuleInitializer<CameraMetadataScanModuleInput, CameraMetadataScan.Error>) -> Void) {
        completion(.init(aggregating: self))
    }
}
