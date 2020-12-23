//
//  NativeChoice.swift
//  PSSmartWalletNativeLayer
//
//  Created by Costin Andronache on 10/21/20.
//

import Foundation
import UIKit

public struct NativeChoiceExtension {
    
    public static func buildImplementationFor(hostController: UIViewController) -> ApiImplementation {
        
        return { (inputValues, callback) in
            guard let options = inputValues.first as? [String] else {
                callback(.failure(.init(localizedDescription: "Malformed input values: \(inputValues)")))
                return
            }
            
            let alert = UIAlertController(title: "", message: "Native choice", preferredStyle: .alert)
            options.enumerated().forEach { value in
                alert.addAction(UIAlertAction(title: value.element, style: .default, handler: { _ in callback(.success([.number(Double(value.offset))])) }))
            }
            
            hostController.present(alert, animated: true, completion: nil)
        }
    }
}
