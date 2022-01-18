//
//  GenericCameraScreenModuleClientBuilder.swift
//  PSKNodeServer
//
//  Created by Costin Andronache on 18.01.2022.
//

import UIKit

protocol HasCameraModuleErrors: Swift.Error {
    static func cameraModuleInitializationError(_ error: CameraScreen.InitializationError) -> Self
    static var userCancelled: Self { get }
}

class GenericCameraScreenModuleClientBuilder
  <ModuleInputType, ErrorType: HasCameraModuleErrors>:
  ViewlessModuleInitializer {
    
    private let cameraScreenModuleBuilder: CameraScreenModuleBuildable
    private let clientModuleInitialization: ClientModuleSpecificInitialization
    private let hostController: UIViewController
    private var cameraScreenController: UIViewController?
    
    init(hostController: UIViewController,
         cameraScreenModuleBuilder: CameraScreenModuleBuildable,
         clientModuleInitialization: @escaping ClientModuleSpecificInitialization) {
        self.cameraScreenModuleBuilder = cameraScreenModuleBuilder
        self.clientModuleInitialization = clientModuleInitialization
        self.hostController = hostController
    }
    
    func initializeModuleWith(completion: @escaping ViewlessModuleInitialization<ModuleInputType, ErrorType>.Completion) {
        let dismissModuleController: VoidBlock = { [weak self] in
            self?.cameraScreenController?.dismiss(animated: true, completion: nil)
        }
        let clientModuleInitialization = self.clientModuleInitialization
        
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
                    
                    clientModuleInitialization(cameraScreenInput, dismissModuleController, completion)
                }
            })
        })
    }
}

extension GenericCameraScreenModuleClientBuilder {
    typealias ClientModuleSpecificInitialization = (_ cameraModuleInput: CameraScreenModuleInput,
                                                    _ exitModuleHandler: VoidBlock?,
                                                    _ completion: @escaping ViewlessModuleInitialization<ModuleInputType, ErrorType>.Completion) -> Void
}
