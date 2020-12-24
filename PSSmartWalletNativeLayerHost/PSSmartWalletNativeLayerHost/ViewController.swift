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
        apiContainer = setupApiContainer()
        setupNodeServer()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            webView.load(URLRequest(url: URL(string: "http://localhost:8080")!))
        }

    }

    
    private func setupNodeServer() {
        let path: String = Bundle.main.path(forResource: "nodejsProject/MobileServerLauncher.js", ofType: nil) ?? ""

        Thread {
            NodeRunner.startEngine(withArguments: ["node", path])
        }.start()
    }
    
    private func setupApiContainer() -> APIContainer? {
        
        let ac = try? APIContainer(mode: .apiOnly(selectedPort: 7070))
        try? ac?.addAPI(name: "dataMatrixScan", implementation: DataMatrixScan.implementationIn(controllerProvider: self))
        
        return ac
    }
    
    private func setupNewWebView() -> WKWebView {
        let conf = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: conf)
        
        return webView
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

