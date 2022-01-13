//
//  CameraScreenModuleBuilder.swift
//  PSKNodeServer
//
//  Created by Costin Andronache on 10.01.2022.
//

import UIKit

protocol CameraScreenModuleBuildable {
    func build(completion: @escaping (AnyModuleInitializer<CameraScreenModuleInput,
                                      CameraScreenModule.InitializationError>) -> Void)
}

struct CameraScreenModuleBuilder: CameraScreenModuleBuildable {
    func build(completion: @escaping (AnyModuleInitializer<CameraScreenModuleInput, CameraScreenModule.InitializationError>) -> Void) {
        completion(.init(aggregating: self))
    }
}

extension CameraScreenModuleBuilder: ModuleInitializer {
    typealias ErrorType = CameraScreenModule.InitializationError
    typealias ModuleInputType = CameraScreenModuleInput
    
    func initializeModuleWith(controllerInHierarchyInsertion: @escaping (UIViewController, VoidBlock?) -> Void,
                              completion: @escaping ModuleInitialization<CameraScreenModuleInput, CameraScreenModule.InitializationError>.Completion) {
        
        let controller = CameraScreenViewController()
        let presenter = CameraScreenPresenter()
        
        presenter.prepareForInitializationWith(view: controller,
                                               initializationCompletion: {
            switch $0 {
            case .success:
                completion(.success(presenter))
            case .failure(let error):
                completion(.failure(error))
            }
        })
        
        controllerInHierarchyInsertion(controller, nil)
    }
}
