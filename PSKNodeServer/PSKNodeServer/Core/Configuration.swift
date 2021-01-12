//
//  Configuration.swift
//  PSKNodeServer
//
//  Created by Costin Andronache on 1/11/21.
//

import UIKit

class Configuration {
    static private(set) var defaultInstance: Configuration = {
        let path = Bundle.main.path(forResource: "AppConfig.json", ofType: "") ?? ""
        return Configuration(configFilePath: path)
    }()
    
    private let fields: Fields
    
    var webviewBackgroundColor: UIColor {
        return UIColor(hex: fields.webViewBackgroundHex) ?? .blue
    }
    
    init(configFilePath: String) {
        guard let data = try? String(contentsOfFile: configFilePath).data(using: .ascii),
              let fields =  try? JSONDecoder().decode(Fields.self, from: data) else {
            self.fields = Fields(webViewBackgroundHex: "#000000")
            return
        }
        self.fields = fields
    }
}

extension Configuration {
    struct Fields: Codable {
        let webViewBackgroundHex: String
    }
}
