//
//  String+localized.swift
//  PSKNodeServer
//
//  Created by Costin Andronache on 1/15/21.
//

import Foundation

extension String {
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
}
