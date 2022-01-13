//
//  Definitions.swift
//  PSSmartWalletNativeLayer
//
//  Created by Costin Andronache on 10/21/20.
//

import Foundation
import WebKit

/**
 `APIResultValue` enumerates the possible results a native api implementation can return
 to its caller which is located on the web-side.
 
 Currently web-side callers can only process an array of such values, i.e
 the javascript types for `string`, `number` and `Blob`.
 
 The number of elements in the resulting array, the order between them as well as the type for each
 element must be documented by the author of the native api.
 */
public enum APIValue {
    case string(String)
    case number(Double)
    case bytes(Data)
}

public typealias APIResultCompletion = (Result<[APIValue], APIError>) -> Void
/**
 The `ApiImplementation` type defines the signature of the function object that the native api author must
 register into the `APIContainer` along with its designated name.
 */
public protocol APIImplementation {
    func perform(_ inputArguments: [APIValue],
                 _ completion: @escaping APIResultCompletion)
}

public typealias APIClosureImplementation = (_ inputArguments: [APIValue],
                                             _ completion: @escaping APIResultCompletion) -> Void

public protocol StreamAPIImplementation {
    func openStream(input: [APIValue],
                    completion: @escaping (Result<Void, APIError>) -> Void)
    func retrieveNext(input: [APIValue],
                      into: @escaping (Result<[APIValue], APIError>) -> Void)
    func close()
}

/**
 
 */
public enum DataStreamSessionAction {
    case chunk(Data)
    case close
}

public protocol DataStreamSessionDelegate {
    func provideNext(action: @escaping (DataStreamSessionAction) -> Void)
    func handlePeerClose()
}

public typealias DataStreamSessionDelegateCompletion = (Result<DataStreamSessionDelegate, APIError>) -> Void
public typealias DataStreamAPIImplementation = ([Any], @escaping DataStreamSessionDelegateCompletion) -> Void
