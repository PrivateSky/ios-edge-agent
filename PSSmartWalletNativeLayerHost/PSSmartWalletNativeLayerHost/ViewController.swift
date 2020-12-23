//
//  ViewController.swift
//  PSSmartWalletNativeLayerDemo
//
//  Created by Costin Andronache on 10/22/20.
//

import UIKit
import WebKit
import PSSmartWalletNativeLayer


class ViewController: UIViewController, WKNavigationDelegate {
    
    private var webView: WKWebView?
    private var apiContainer: APIContainer?
    
    @IBOutlet private var webViewHostView: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let webView = setupNewWebView()
        webViewHostView?.constrainFull(other: webView)
        self.webView = webView
        webView.navigationDelegate = self
        let setup = setupApiContainer()
        apiContainer = setup.0
        webView.load(URLRequest(url: URL(string: setup.1)!))

    }
    
    @IBAction
    @objc private func reloadButtonPressed() {
        webView?.load(URLRequest(url: URL(string: apiContainer!.webAppOrigin)!))
    }
    
    private func setupNodeServer() {
        let path: String = Bundle.main.path(forResource: "selected/MobileServerLauncher.js", ofType: nil) ?? ""

        Thread {
            NodeRunner.startEngine(withArguments: ["node", path])
        }.start()
    }
    
    private func setupApiContainer() -> (APIContainer?, String) {
        
        let path = Bundle.main.bundlePath + "/webApp"
        let ac = try? APIContainer(mode: .withWebApp( .init(webAppDirectory: path, indexFilename: "NativeSmartWalletCameraDemo.html")))
        try? ac?.addAPI(name: "dataMatrixScan", implementation: DataMatrixScan.implementationIn(controllerProvider: self))
        
        return (ac, ac?.webAppOrigin ?? "")
    }
    
    private func setupNewWebView() -> WKWebView {
        let conf = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: conf)
        
        return webView
    }
    
    
    private func getWebDemoHTML() -> String {
        let path = Bundle.main.path(forResource: "webApp/NativeSmartWalletWebAppDemo.html", ofType: "")
        return try! String(contentsOfFile: path!)
    }
    
    private func getNativeBridgeJS() -> String {
        let path = Bundle.main.path(forResource: "iOSNativeWalletBridge", ofType: "js")
        return try! String(contentsOfFile: path!)
    }
    
    private func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print(error)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        print(navigationAction.request.url!)
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        print(navigation)
    }
    
    
}



extension UIView {
    func constrainFull(other: UIView) {
        other.translatesAutoresizingMaskIntoConstraints = false;
        addSubview(other)
        NSLayoutConstraint.activate([
            self.widthAnchor.constraint(equalTo: other.widthAnchor),
            self.heightAnchor.constraint(equalTo: other.heightAnchor),
            self.centerXAnchor.constraint(equalTo: other.centerXAnchor),
            self.centerYAnchor.constraint(equalTo: other.centerYAnchor)
        ])
    }
}

