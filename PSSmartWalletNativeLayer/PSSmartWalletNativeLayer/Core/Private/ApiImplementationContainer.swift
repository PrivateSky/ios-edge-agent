//
//  ApiImplementationContainer.swift
//  PSSmartWalletNativeLayer
//
//  Created by Costin Andronache on 10/28/20.
//

import Foundation
import GCDWebServers

class ImplementationContainer {
    private var apiImplementationMap: [String: APIImplementation] = [:]
    private var dataStreamAPIImplementationMap: [String: DataStreamAPIImplementation] = [:]
    private var streamAPIImplementationMap: [String: StreamAPIImplementation] = [:]
    private let dataStorage = DataStorage()
    
    private let internalResultProcessingQueue = DispatchQueue(label: "PSSmartWalletNativeLayer.internalResultProcessingQueue",
                                                              qos: .default,
                                                              attributes: [],
                                                              autoreleaseFrequency: .workItem,
                                                              target: nil)
    
    func addAPI(name: String, implementation: @escaping APIClosureImplementation) throws {
        try addAPI(name: name, implementation: APIClosureImplementationContainer(implementation))
    }
            
    func addAPI(name: String, implementation: APIImplementation) throws {
        guard apiImplementationMap[name] == nil else {
            throw Error.nameAlreadyInUse(apiName: name)
        }
        
        apiImplementationMap[name] = implementation
    }
    
    func addStreamAPI(name: String, implementation: StreamAPIImplementation) throws {
        guard streamAPIImplementationMap[name] == nil else {
            throw Error.nameAlreadyInUse(apiName: name)
        }
        
        streamAPIImplementationMap[name] = implementation
    }
    
    func addDataStreamAPI(name: String, implementation: @escaping DataStreamAPIImplementation) throws {
        guard dataStreamAPIImplementationMap[name] == nil else {
            throw Error.nameAlreadyInUse(apiName: name)
        }
        
        dataStreamAPIImplementationMap[name] = implementation
    }
    
    func setupEndpointIn(server: GCDWebServer) {
        setupBytesDownloadEndpointIn(server: server)
        setupAPICallEndpointIn(server: server)
    }
    
    private func setupBytesDownloadEndpointIn(server: GCDWebServer) {
        server.addHandler(forMethod: "GET", path: "/retrieve-resource", request: GCDWebServerRequest.classForCoder()) { (request, completion) in
            guard let id = request.query?["id"], let data = self.dataStorage.removeFrom(id: id)  else {
                completion(nil)
                return
            }
            completion(GCDWebServerDataResponse(data: data, contentType: "application/octet-stream").applyCORSHeaders())
        }
    }
    
    private func setupAPICallEndpointIn(server: GCDWebServer) {
        server.addDefaultHandler(forMethod: "POST", request: GCDWebServerMultiPartFormRequest.classForCoder()) { [weak self] (request, completion) in
            guard let multiPartRequest = request as? GCDWebServerMultiPartFormRequest,
                  let callType = self?.determineAPITypeCall(from: multiPartRequest.url) else {
                      self?.completeWith(error: .noSuchApiError,
                                         completion: completion)
                      return
                  }
            
            self?.dispatchAPICall(type: callType,
                                 arguments: multiPartRequest.arguments.map(\.asAPIValue),
                                 completion: completion)
        }
    }
    
    private func dispatchAPICall(type: APITypeCall,
                                 arguments: [APIValue],
                                 completion: @escaping GCDWebServerCompletionBlock) {
        switch type {
        case .general(let name):
            if let api = apiImplementationMap[name] {
                handleApiCall(api: api, arguments: arguments, completion: completion)
                return
            } else if let streamApi = dataStreamAPIImplementationMap[name] {
                handleDataStreamCall(api: streamApi, arguments: arguments, completion: completion)
                return
            } else {
                completeWith(error: .noSuchApiError, completion: completion)
            }
            
        case .stream(let name, let action):
            handleStreamAPICall(name: name,
                                arguments: arguments,
                                action: action,
                                completion: completion)
        }
    }
    
    private func handleApiCall(api: APIImplementation,
                               arguments: [APIValue],
                               completion: @escaping GCDWebServerCompletionBlock) {
        DispatchQueue.main.async {
            api.perform(arguments) {
                switch $0 {
                case .success(let values):
                    self.completeWith(values: values, completion: completion)
                case .failure(let error):
                    self.completeWith(error: error, completion: completion)
                }
            }
        }
    }
    
    private func handleDataStreamCall(api: @escaping DataStreamAPIImplementation,
                                      arguments: [APIValue],
                                      completion: @escaping GCDWebServerCompletionBlock) {
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
                    self.completeWith(error: error, completion: completion)
                }
                
            }
        }
    }
    
    private func handleStreamAPICall(name: String,
                                     arguments: [APIValue],
                                     action: StreamAPIAction,
                                     completion: @escaping GCDWebServerCompletionBlock) {
        guard let api = streamAPIImplementationMap[name] else {
            completeWith(error: .noSuchApiError, completion: completion)
            return
        }
        
        switch action {
        case .open:
            api.openStream(input: arguments, completion: { [weak self] in
                switch $0 {
                case .failure(let error):
                    self?.completeWith(error: error, completion: completion)
                case .success:
                    self?.completeWith(values: [], completion: completion)
                }
            })
        case .nextValue:
            api.retrieveNext(input: arguments, into: { [weak self] in
                switch $0 {
                case .failure(let error):
                    self?.completeWith(error: error, completion: completion)
                case .success(let values):
                    self?.completeWith(values: values, completion: completion)
                }
            })
        case .close:
            api.close()
            completeWith(values: [], completion: completion)
        }
    }
    
    private func completeWith(error: APIError, completion: @escaping GCDWebServerCompletionBlock) {
        completion(GCDWebServerDataResponse(jsonObject: ["error": error.code])?.applyCORSHeaders())
    }
    
    private func completeWith(values: [APIValue], completion: @escaping GCDWebServerCompletionBlock) {
        let jsonArray = values.map({ (value) -> [String: Any] in
            value.jsonWithMetadata(bytesIdGenerator: { self.dataStorage.insert(data: $0)
            })
        })
        completion(GCDWebServerDataResponse(jsonObject: ["result": jsonArray])?.applyCORSHeaders())
    }
    
}

private extension ImplementationContainer {
    enum StreamAPIAction: String {
        case open
        case nextValue
        case close
    }

    enum APITypeCall {
        case general(apiName: String)
        case stream(apiName: String, action: StreamAPIAction)
    }
    
    func determineAPITypeCall(from url: URL) -> APITypeCall? {
        // general API call: <server_url>/apiName
        // stream API call: <server_url>/apiName/{action}
        
        print("Determining APIType from: \(url)")
        
        let components = url.pathComponents
        guard let lastComponent = components.last else {
            print("Empty components, no APIType");
            return nil
        }
        
        if let streamAPIAction = StreamAPIAction(rawValue: lastComponent) {
            guard components.count >= 2 else {
                print("No viable component found in \(components)")
                return nil
            }
            return .stream(apiName: components[components.count-2], action: streamAPIAction)
        }
        
        return .general(apiName: lastComponent)
    }
}

private struct APIClosureImplementationContainer: APIImplementation {
    let implementation: APIClosureImplementation
    init(_ implementation: @escaping APIClosureImplementation) {
        self.implementation = implementation
    }
    
    func perform(_ inputArguments: [APIValue], _ completion: @escaping APIResultCompletion) {
        implementation(inputArguments, completion)
    }
}

private extension GCDWebServerMultiPartArgument {
    var asAPIValue: APIValue {
        if let string = string {
            if let number = Double(string) {
                return .number(number)
            } else {
                return .string(string)
            }
        } else {
            return .bytes(data)
        }
    }
}

private extension APIValue {
    func jsonWithMetadata(bytesIdGenerator: @escaping (Data) -> String) -> [String: Any] {
        switch self {
        case .string(let string): return ["type": "string", "value": string]
        case .number(let double): return ["type": "number", "value": double]
        case .bytes(let data): return ["type": "bytes",
                                       "path": "/retrieve-resource?id=\(bytesIdGenerator(data))"]
        }
    }
}
