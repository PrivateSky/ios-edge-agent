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
                
        guard let apiContainer = setupApiContainer() else {
            print("Couldnt set up API Container")
            return
        }
        self.apiContainer = apiContainer
        
        if  let indexPage = setupNodeServer(path: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.path, apiContainerPort: apiContainer.port),
            let url = URL(string: indexPage) {
            Utilities.executeWhenUrlAvilable(url: url) {
                self.view.constrainFull(other: self.webView)
                self.loadURL(string: indexPage)
            }
        }
    }

    private func setupNodeServer(path: String, apiContainerPort: UInt) -> String? {
        guard let port = Utilities.findFreePort() else {
            print("Couldnt find free port for Node")
            return nil
        }
        
        let sourceInstallationFolder = Bundle.main.path(forResource: "nodejsProject", ofType: nil) ?? ""
        
        let rootInstallationFolder = "\(path)/nodejsProject"
        
        let fm = FileManager.default
        
        if !fm.fileExists(atPath: rootInstallationFolder, isDirectory: nil) {
            print("Begin copying into \(rootInstallationFolder)")
            do {
                try fm.copyItem(atPath: sourceInstallationFolder, toPath: rootInstallationFolder)
                print("DONE COPYING");
                
            } catch let error {
                print("COPY ERROR: \(error)")
            }
        }
        
        let nspPath = "\(rootInstallationFolder)/apihub-root/nsp"
        do {
            try "\(apiContainerPort)".data(using: .ascii)?.write(to: .init(fileURLWithPath: nspPath))
        } catch let error {
            print(error)
            return nil
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
            NodeRunner.startEngine(withArguments: ["node", serverLauncher, "--bundle=\(pskServerPath)", "--port=\(port)",
            "--rootFolder=\(apihubRootPath)",
            "--env=\(envString)"])
        }.start()
        
        return "http://localhost:\(port)/app/loader/index.html"
    }
    
    private func setupApiContainer() -> APIContainer? {
        guard let port = Utilities.findFreePort() else {
            print("No free port")
            return nil
        }
        let ac = try? APIContainer(mode: .apiOnly(selectedPort: UInt(port)))
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

