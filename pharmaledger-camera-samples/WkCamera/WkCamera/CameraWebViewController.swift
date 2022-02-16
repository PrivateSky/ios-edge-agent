//
//  CameraWebViewController.swift
//  jscamera
//
//  Created by Yves Delacrétaz on 23.06.21.
//

import Foundation
import AVFoundation
import UIKit
import WebKit
import PharmaLedger_Camera

public class CameraWebViewController: UIViewController, WKUIDelegate {
    // MARK: Privates
    private var webview: WKWebView?
    private var messageHandler = PharmaledgerMessageHandler(staticPath: Bundle.main.path(forResource: "www", ofType: nil))
    
    func load() {
        self.webview = messageHandler.getWebview(frame: self.view.frame)
        self.webview?.uiDelegate = self
        if let webview = webview {
//            let fileUrl = URL(fileURLWithPath: Bundle.main.path(forResource: "www/bootstrap.html", ofType: nil)!)
//            webview.loadFileURL(fileUrl, allowingReadAccessTo: fileUrl.deletingLastPathComponent())
            
            let url = URL(string: "http://localhost:\(self.messageHandler.webserverPort)/bootstrap.html")!
            webview.load(URLRequest(url: url))
            
            self.view.addSubview(webview)
        }
    }
    
    public func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: {action in completionHandler() }))
        self.present(alert, animated: true, completion: nil)
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        load()
        super.viewWillAppear(animated)
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        removeWebview()
        super.viewWillDisappear(animated)
    }
    
    
    public func removeWebview() {
        if let webview = webview {
            webview.removeFromSuperview()
        }
    }
}
