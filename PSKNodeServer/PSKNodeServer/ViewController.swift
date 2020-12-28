//
//  ViewController.swift
//  PSSmartWalletNativeLayerDemo
//
//  Created by Costin Andronache on 10/22/20.
//

import UIKit
import PSSmartWalletNativeLayer
import WebKit


class ViewController: UIViewController {
    
    private var apiContainer: APIContainer?
    private let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        apiContainer = setupApiContainer()
        let indexPage = setupNodeServer(path: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.path)
        view.constrainFull(other: webView)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.loadURL(string: indexPage)
        }
    }

    private func setupNodeServer(path: String) -> String {
        let port = 8080
        
        let sourceInstallationFolder = Bundle.main.path(forResource: "nodejsProject", ofType: nil) ?? ""
        
        let rootInstallationFolder = "\(path)/nodejsProject"
        
        let fm = FileManager.default
        try? fm.removeItem(atPath: rootInstallationFolder)
        
        if !fm.fileExists(atPath: rootInstallationFolder, isDirectory: nil) {
            print("Begin copying into \(rootInstallationFolder)")
            do {
                try fm.copyItem(atPath: sourceInstallationFolder, toPath: rootInstallationFolder)
                print("DONE COPYING");
                
            } catch let error {
                print("COPY ERROR: \(error)")
            }
        }
        
        let serverLauncher: String =  "\(path)/nodejsProject/MobileServerLauncher.js"
        
        let pskServerPath =  "\(path)/nodejsProject/pskWebServer.js"
        
        let apihubRootPath =  "\(path)/nodejsProject/apihub-root"
        
        let env: [String: String] = [
            "PSK_CONFIG_LOCATION": "\(apihubRootPath)/external-volume/config",
            "PSK_ROOT_INSTALATION_FOLDER": rootInstallationFolder,
            "BDNS_ROOT_HOSTS": "http://localhost:\(port)"
        ]
        let envString = String(data: try! JSONEncoder().encode(env), encoding: .ascii)!
        

        Thread {
            NodeRunner.startEngine(withArguments: ["node", serverLauncher, "--bundle=\(pskServerPath)", "--port=8080",
            "--rootFolder=\(apihubRootPath)",
            "--env=\(envString)"])
        }.start()
        
        return "http://localhost:\(port)/app/loader/index.html"
    }
    
    private func setupApiContainer() -> APIContainer? {
        
        let ac = try? APIContainer(mode: .apiOnly(selectedPort: 7070))
        try? ac?.addAPI(name: "dataMatrixScan", implementation: DataMatrixScan.implementationIn(controllerProvider: self))
        
        return ac
    }
        
    func loadURL(string: String) {
        if let url = URL(string: string) {
            webView.load(URLRequest(url: url))
        }
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

