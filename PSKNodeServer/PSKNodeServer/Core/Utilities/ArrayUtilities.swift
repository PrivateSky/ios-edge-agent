//
//  NSArratUtilities.swift
//  PSKNodeServer
//
//  Created by Costin Andronache on 15.01.2022.
//

import Foundation

extension Array where Element: Equatable {
    func containsAll(_ other: [Element]) -> Bool {
        return other.allSatisfy(self.contains(_:))
    }
}
