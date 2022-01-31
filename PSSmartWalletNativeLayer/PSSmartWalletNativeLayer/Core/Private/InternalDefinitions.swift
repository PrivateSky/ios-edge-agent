//
//  InternalDefinitions.swift
//  PSSmartWalletNativeLayer
//
//  Created by Costin Andronache on 30.12.2021.
//

import Foundation

typealias VoidBlock = () -> Void

enum Either<T, U> {
    case first(T)
    case second(U)
}
