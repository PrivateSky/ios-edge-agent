//
//  DataStorage.swift
//  PSSmartWalletNativeLayer
//
//  Created by Costin Andronache on 05.01.2022.
//

import Foundation

class DataStorage {
    private let queue = DispatchQueue(label: "PSSmartWalletNativeLayer.dataStorageQueue",
                                      qos: .default, attributes: [], autoreleaseFrequency: .workItem, target: nil)
    private var dataMap: [String: Data] = [:]
    private var currentKey: Int = 0
    
    func insert(data: Data) -> String {
        var id: Int = 0;
        queue.sync {
            id = self.currentKey
            self.currentKey &+= 1
            dataMap["\(id)"] = data
        }
        return "\(id)"
    }
    
    @discardableResult
    func removeFrom(id: String) -> Data? {
        var data: Data?
        queue.sync {
            data = self.dataMap[id]
            self.dataMap[id] = nil
        }
        return data
    }
}
