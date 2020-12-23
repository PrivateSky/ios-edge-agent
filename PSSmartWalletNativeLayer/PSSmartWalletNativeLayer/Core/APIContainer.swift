//
//  WebviewContainer.swift
//  PSSmartWalletNativeLayer
//
//  Created by Costin Andronache on 10/21/20.
//

import Foundation
import WebKit
import GCDWebServers

private let maxPortSearched = 9999
public class APIContainer {
    
    public enum Mode {
        case withWebApp(WebAppConfiguration)
        case apiOnly(selectedPort: UInt?)
    }
    
    public struct WebAppConfiguration {
        public let webAppDirectory: String
        public let indexFilename: String
        public init(webAppDirectory: String,
                    indexFilename: String) {
            self.webAppDirectory = webAppDirectory
            self.indexFilename = indexFilename
        }
    }
    
    private let implementationContainer = ImplementationContainer()
    private let webserver = GCDWebServer()
    public let port: UInt
    public var serverOrigin: String {
        "http://localhost:\(port)"
    }
    public var webAppOrigin: String {
        serverOrigin + "/web-app/"
    }
    
    public init(mode: Mode) throws {
        
        implementationContainer.setupEndpointIn(server: webserver)
        webserver.addDefaultHandler(forMethod: "OPTIONS", request: GCDWebServerRequest.classForCoder()) { (req) -> GCDWebServerResponse? in
            return GCDWebServerResponse().applyCORSHeaders()
        }
        
        
        let startFromPort: (UInt?, GCDWebServer) throws -> UInt = {
            var port: UInt = $0 ?? 8600
            while !$1.start(withPort: port, bonjourName: nil) && port < maxPortSearched {
                port += 1
            }
            
            if port == maxPortSearched {
                throw Error.noAvailablePort
            }
            
            return port
        }
        
        switch mode {
        case .withWebApp(let configuration):
            let basePath = "/web-app/"
            webserver.addGETHandler(forBasePath: basePath, directoryPath: configuration.webAppDirectory, indexFilename: configuration.indexFilename, cacheAge: 3500, allowRangeRequests: true);
            port = try startFromPort(nil, self.webserver)
        case .apiOnly(let selectedPort):
            port = try startFromPort(selectedPort, self.webserver)
        }
        
        GCDWebServer.setLogLevel(0)
    }
        
    public func addAPI(name: String, implementation: @escaping ApiImplementation) throws {
        try implementationContainer.addApi(name: name, implementation: implementation)
    }
    
    public func addStreamApi(name: String, implementation: @escaping StreamApiImplementation) throws {
        try implementationContainer.addStreamApi(name: name, implementation: implementation)
    }
    
}

extension GCDWebServerResponse {
    func applyCORSHeaders() -> Self {
        let resp = self
        resp.setValue("*", forAdditionalHeader: "Access-Control-Allow-Origin")
        resp.setValue("*", forAdditionalHeader: "Access-Control-Allow-Methods")
        resp.setValue("*", forAdditionalHeader: "Access-Control-Allow-Headers")
        resp.setValue("true", forAdditionalHeader: "Access-Control-Allow-Credentials")
        return self
    }
    
    func applyStreamHeader() -> Self {
        let resp = self;
        resp.setValue("*", forAdditionalHeader: "X-Stream-Header")
        return self;
    }
}

