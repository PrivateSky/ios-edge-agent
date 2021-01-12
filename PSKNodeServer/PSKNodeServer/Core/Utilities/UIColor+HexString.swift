//
//  UIColor+HexString.swift
//  PSKNodeServer
//
//  Created by Costin Andronache on 1/11/21.
//

import UIKit

extension UIColor {
    public convenience init?(hex: String) {

        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])

            if hexColor.count >= 6 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0

                if scanner.scanHexInt64(&hexNumber) {
                    let red = CGFloat((hexNumber & 0xff0000) >> 16) / 255.0
                        let green = CGFloat((hexNumber & 0xff00) >> 8) / 255.0
                        let blue = CGFloat((hexNumber & 0xff) >> 0) / 255.0

                    self.init(red: red, green: green, blue: blue, alpha: 1.0)
                    return
                }
            }
        }

        return nil
    }
}
