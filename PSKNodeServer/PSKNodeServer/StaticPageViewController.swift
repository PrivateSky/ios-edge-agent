//
//  StaticPageViewController.swift
//  PSKNodeServer
//
//  Created by Costin Andronache on 13.04.2022.
//

import GCDWebServers
import PSSmartWalletNativeLayer
import Foundation
import WebKit
import UIKit

final class StaticPageViewController: UIViewController {
    private var apiContainer: APIContainer?
    private let webServer = GCDWebServer()
    private let ac = ApplicationCore()
    private let webView = WKWebView(frame: .zero, configuration: .init())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.constrainFull(other: webView)
        let apiCollection = APICollection.setupAPICollection(webServer: webServer,
                                                             viewControllerProvider: self)
        apiContainer = try! ac.setupApiContainer(apiCollection: apiCollection,
                                                 webServer: webServer)
        setupDemoPage(apiPort: apiContainer!.port)
    }
    
    private func setupDemoPage(apiPort: UInt) {
        let webAppDirectory = Bundle.main.path(forResource: "nativePageDemo", ofType: "")!
        webServer.addHandler(forMethod: "GET", path: "/nsp", request: GCDWebServerRequest.classForCoder()) { (request, completion) in
            let data = "\(apiPort)".data(using: .ascii)!
            completion(GCDWebServerDataResponse(data: data, contentType: "application/octet-stream").applyCORSHeaders())
        }
        
        let basePath = "/web-app/"
        webServer.addGETHandler(forBasePath: basePath, directoryPath: webAppDirectory, indexFilename: "native-streaming.html", cacheAge: 3500, allowRangeRequests: true);
        
        webServer.start()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
            self.webView.load(.init(url: .init(string: "http://localhost:\(self.webServer.port)/web-app/")!))
        })
    }
    ///
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
}
