//
//  GenerateRandom.swift
//  PSSmartWalletNativeLayer
//
//  Created by Costin Andronache on 10/21/20.
//

import Foundation
import CryptoKit

@available(iOS 13.0, *)
public struct Curve25519KeyPair {
    public static let implementation: ApiImplementation = { (inputValues, callback) in
        
        let privateKey = Curve25519.Signing.PrivateKey()
        
        callback(.success([.bytes(privateKey.rawRepresentation), .bytes(privateKey.publicKey.rawRepresentation)]))
        
    }
}



public class TestTextStreaming: StreamSessionDelegate {
    
    private var count: Int = 0
    
    public static let implementation: StreamApiImplementation = { _,  completion in
        completion(.success(TestTextStreaming()))
    }
    
    public func provideNext(action: @escaping (StreamSessionAction) -> Void) {
        count += 1
        if count < 10 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                action(.chunk("Test \(self.count)".data(using: .utf8)!))
            }
        } else {
            action(.close)
        }
    }
    
    public func handlePeerClose() {
        
    }
}


