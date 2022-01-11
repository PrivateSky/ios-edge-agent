//
//  Errors.swift
//  PSSmartWalletNativeLayer
//
//  Created by Costin Andronache on 10/21/20.
//

import Foundation

public enum Error: Swift.Error {
    case nameAlreadyInUse(apiName: String)
    case noAvailablePort
}

public struct APIError: Swift.Error {
    let code: String
    public init(code: String) {
        self.code = code
    }
}

public extension APIError {
    static let noSuchApiError = APIError(code: "ERR_NO_SUCH_API")
}
