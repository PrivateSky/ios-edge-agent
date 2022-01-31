//
//  ViewlessModule.swift
//  PSKNodeServer
//
//  Created by Costin Andronache on 17.01.2022.
//

import Foundation

enum ViewlessModuleInitialization<ModuleInputType, ErrorType: Error> {
    typealias Completion = (Result<ModuleInputType, ErrorType>) -> Void
}

protocol ViewlessModuleInitializer {
    associatedtype ModuleInputType
    associatedtype ErrorType: Error
    func initializeModuleWith(completion: @escaping ViewlessModuleInitialization<ModuleInputType, ErrorType>.Completion)
}

struct AnyViewlessModuleInitializer<ModuleInputType, ErrorType: Error>: ViewlessModuleInitializer {
    private let initializeFn: (@escaping ViewlessModuleInitialization<ModuleInputType, ErrorType>.Completion) -> Void
    
    init<T: ViewlessModuleInitializer>(aggregating instance: T) where T.ModuleInputType == ModuleInputType, T.ErrorType == ErrorType {
        initializeFn = instance.initializeModuleWith(completion:)
    }
    
    func initializeModuleWith(completion: @escaping ViewlessModuleInitialization<ModuleInputType, ErrorType>.Completion) {
        initializeFn(completion)
    }
}
