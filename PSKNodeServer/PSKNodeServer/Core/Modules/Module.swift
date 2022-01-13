//
//  ModuleInitializer.swift
//  PSKNodeServer
//
//  Created by Costin Andronache on 11.01.2022.
//

import UIKit

enum ModuleInitialization<ModuleInputType, ErrorType: Error> {
    typealias ControllerHierarchyInsertion = (UIViewController, _ completion: VoidBlock?) -> Void
    typealias Completion = (Result<ModuleInputType, ErrorType>) -> Void
}

protocol ModuleInitializer {
    associatedtype ModuleInputType
    associatedtype ErrorType: Error
    func initializeModuleWith(controllerInHierarchyInsertion: @escaping ModuleInitialization.ControllerHierarchyInsertion,
                              completion: @escaping ModuleInitialization<ModuleInputType, ErrorType>.Completion)
}

struct AnyModuleInitializer<ModuleInputType, ErrorType: Error>: ModuleInitializer {
    private let initializeFn: (@escaping (UIViewController, VoidBlock?) -> Void,
                               @escaping ModuleInitialization<ModuleInputType, ErrorType>.Completion) -> Void
    
    init<T: ModuleInitializer>(aggregating instance: T) where T.ModuleInputType == ModuleInputType, T.ErrorType == ErrorType {
        initializeFn = instance.initializeModuleWith(controllerInHierarchyInsertion:completion:)
    }
    
    func initializeModuleWith(controllerInHierarchyInsertion: @escaping (UIViewController, VoidBlock?) -> Void, completion: @escaping ModuleInitialization<ModuleInputType, ErrorType>.Completion) {
        initializeFn(controllerInHierarchyInsertion, completion)
    }
}
