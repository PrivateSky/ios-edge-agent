//
//  UIAlertController+Extensions.swift
//  PSKNodeServer
//
//  Created by Costin Andronache on 1/12/21.
//

import UIKit


extension UIAlertController {
    static func okMessage(in host: UIViewController?, message: String, completion: (() -> Void)?) {
        
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: "Ok"), style: .default, handler: { (_) in
            completion?()
        }))
        
        host?.present(alert, animated: true, completion: nil)
    }
}
