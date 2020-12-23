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
