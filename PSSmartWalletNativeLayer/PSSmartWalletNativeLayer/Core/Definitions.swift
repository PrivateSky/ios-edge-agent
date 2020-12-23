//
//  Definitions.swift
//  PSSmartWalletNativeLayer
//
//  Created by Costin Andronache on 10/21/20.
//

import Foundation
import WebKit

//to doc
public struct ApiError: Swift.Error {
    let localizedDescription: String
    public init(localizedDescription: String) {
        self.localizedDescription = localizedDescription
    }
}

public typealias ApiResultCall = (Result<[Value], ApiError>) -> Void
public typealias VoidBlock = () -> Void

public enum StreamSessionAction {
    case chunk(Data)
    case close
}

public protocol StreamSessionDelegate {
    func provideNext(action: @escaping (StreamSessionAction) -> Void)
    func handlePeerClose()
}

public typealias ApiImplementation = ([Any], @escaping ApiResultCall) -> Void
public typealias StreamSessionDelegateCompletion = (Result<StreamSessionDelegate, ApiError>) -> Void
public typealias StreamApiImplementation = ([Any], @escaping StreamSessionDelegateCompletion) -> Void

//to doc
public enum Value {
    case string(String)
    case number(Double)
    case bytes(Data)
}
