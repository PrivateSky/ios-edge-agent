//
//  CameraScreenModuleBuilder.swift
//  PSKNodeServer
//
//  Created by Costin Andronache on 10.01.2022.
//

import Foundation


protocol CameraScreenModuleBuildable {
    func build(completion: @escaping (Result<CameraScreenModule.Initializer, CameraScreenModule.InitializationError>) -> Void)
}

struct CameraScreenModuleBuilder: CameraScreenModuleBuildable {
    func build(completion: @escaping (Result<CameraScreenModule, CameraScreenModule.InitializationError>) -> Void) {
        let controller = CameraScreenViewController()
        let presenter = CameraScreenPresenter()
        
        presenter.initalizeWith(view: controller,
                                initializationCompletion: {
            switch $0 {
            case .success:
                completion(.success(.init(viewController: controller,
                                          input: presenter)))
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }
}
