//
//  NumberStreamTestAPI.swift
//  PSKNodeServer
//
//  Created by Costin Andronache on 09.01.2022.
//

import Foundation
import PSSmartWalletNativeLayer

class NumberStreamTestAPI: StreamAPIImplementation {
    private var count = 0
    
    func openStream(input: [APIValue], completion: @escaping (Result<Void, APIError>) -> Void) {
        completion(.success(()))
    }
    
    func retrieveNext(input: [APIValue], into: @escaping (Result<[APIValue], APIError>) -> Void) {
        print("Received: \(input)")
        into(.success([.number(Double(count))]))
        count += 1
    }
    
    func close() {
        print("Closing Number Stream")
    }
    
}
