//
//  ApiImplementationContainer.swift
//  PSSmartWalletNativeLayer
//
//  Created by Costin Andronache on 10/28/20.
//

import Foundation
import GCDWebServers

extension APIContainer {
    
    class ImplementationContainer {
        
        private var implementationMap: [String: ApiImplementation] = [:]
        private var streamImplementationMap: [String: StreamApiImplementation] = [:]
        private let dataStorage = DataStorage()
        
        private let internalResultProcessingQueue = DispatchQueue(label: "PSSmartWalletNativeLayer.internalResultProcessingQueue",
            qos: .default, attributes: [], autoreleaseFrequency: .workItem, target: nil)

        func addApi(name: String, implementation: @escaping ApiImplementation) throws {
            guard implementationMap[name] == nil else {
                throw Error.nameAlreadyInUse(apiName: name)
            }
            
            implementationMap[name] = implementation
        }
        
        func addStreamApi(name: String, implementation: @escaping StreamApiImplementation) throws {
            guard streamImplementationMap[name] == nil else {
                throw Error.nameAlreadyInUse(apiName: name)
            }
            
            streamImplementationMap[name] = implementation
        }
         
        func setupEndpointIn(server: GCDWebServer) {
            
            server.addHandler(forMethod: "GET", path: "/retrieve-resource", request: GCDWebServerRequest.classForCoder()) { (request, completion) in
                guard let id = request.query?["id"], let data = self.dataStorage.removeFrom(id: id)  else {
                    completion(nil)
                    return
                }
                completion(GCDWebServerDataResponse(data: data, contentType: "application/octet-stream").applyCORSHeaders())
            }
            
            server.addDefaultHandler(forMethod: "POST", request: GCDWebServerMultiPartFormRequest.classForCoder()) { (request, completion) in
                guard let multiPartRequest = request as? GCDWebServerMultiPartFormRequest else {
                    completion(nil)
                    return
                }
                
                var args: [Any] = []
                multiPartRequest.arguments.forEach {
                    if let string = $0.string {
                        if let data = string.data(using: .utf8),
                           let jsonArray = try? JSONSerialization.jsonObject(with: data, options: []) as? [Any] {
                            args.append(jsonArray);
                            return
                        }
                        args.append(Double(string) ?? string)
                    } else {
                        args.append($0.data)
                    }
                }
                
                let path: String = {
                    if let first = request.path.first,
                       first == "/" {
                        var result = request.path
                        result.remove(at: result.startIndex)
                        return result
                    }
                    return request.path
                }()
                
                self.dispatchCall(name: path, arguments: args, completion: completion)
            }
            
        }
        
        private func dispatchCall(name: String, arguments: [Any], completion: @escaping GCDWebServerCompletionBlock) {
            
            if let api = implementationMap[name] {
                handleApiCall(api: api, arguments: arguments, completion: completion)
                return
            }
            
            if let streamApi = streamImplementationMap[name] {
                handleStreamCall(api: streamApi, arguments: arguments, completion: completion)
                return
            }
            
            handleResult(error: .noSuchApiError, completion: completion)
        }
        
        private func handleApiCall(api: @escaping ApiImplementation, arguments: [Any], completion: @escaping GCDWebServerCompletionBlock) {
            
            DispatchQueue.main.async {
                api(arguments) {
                    switch $0 {
                    case .success(let values):
                        self.handleResult(values: values, completion: completion)
                    case .failure(let error):
                        self.handleResult(error: error, completion: completion)
                    }
                }
            }
        }
        
        private func handleStreamCall(api: @escaping StreamApiImplementation, arguments: [Any], completion: @escaping GCDWebServerCompletionBlock) {
            
            DispatchQueue.main.async {
                api(arguments) { result in
                    
                    switch result {
                    case .success(let sessionDelegate):
                        completion(GCDWebServerStreamedResponse.init(contentType: "application/octet-stream", asyncStreamBlock: { (bodyBlock) in
                            sessionDelegate.provideNext { (action) in
                                switch action {
                                case .chunk(let data):
                                    bodyBlock(data, nil)
                                case .close:
                                    bodyBlock(Data(), nil)
                                }
                            }
                        }).applyCORSHeaders().applyStreamHeader())
                    case .failure(let error):
                        self.handleResult(error: error, completion: completion)
                    }
                    
                }
            }
        }
        
        
        private func handleResult(error: ApiError, completion: @escaping GCDWebServerCompletionBlock) {
            completion(GCDWebServerDataResponse(jsonObject: ["error": error.localizedDescription])?.applyCORSHeaders())
        }
        
        private func handleResult(values: [Value], completion: @escaping GCDWebServerCompletionBlock) {
            let jsonArray = values.map({ (value) -> [String: Any] in
                value.jsonWithMetadata(bytesIdGenerator: { self.dataStorage.insert(data: $0)
                })
            })
            completion(GCDWebServerDataResponse(jsonObject: ["result": jsonArray])?.applyCORSHeaders())
        }
    }
    
    class DataStorage {
        private let queue = DispatchQueue(label: "PSSmartWalletNativeLayer.dataStorageQueue",
                                          qos: .default, attributes: [], autoreleaseFrequency: .workItem, target: nil)
        private var dataPerId: [String: Data] = [:]
        private var currentKey: Int = 0
        
        func insert(data: Data) -> String {
            var id: Int = 0;
            queue.sync {
                id = self.currentKey
                self.currentKey &+= 1
                dataPerId["\(id)"] = data
            }
            return "\(id)"
        }
        
        @discardableResult
        func removeFrom(id: String) -> Data? {
            var data: Data?
            queue.sync {
                data = self.dataPerId[id]
                self.dataPerId[id] = nil
            }
            return data
        }
    }
    
}

private extension Value {
    func jsonWithMetadata(bytesIdGenerator: @escaping (Data) -> String) -> [String: Any] {
        switch self {
        case .string(let string): return ["type": "string", "value": string]
        case .number(let double): return ["type": "number", "value": double]
        case .bytes(let data): return ["type": "bytes",
                                       "path": "/retrieve-resource?id=\(bytesIdGenerator(data))"]
        }
    }
}
