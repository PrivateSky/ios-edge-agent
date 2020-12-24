//
//  ViewController.swift
//  PSSmartWalletNativeLayerDemo
//
//  Created by Costin Andronache on 10/22/20.
//

import UIKit
import PSSmartWalletNativeLayer
import SafariServices


class ViewController: UIViewController {
    
    private var apiContainer: APIContainer?
        
    override func viewDidLoad() {
        super.viewDidLoad()
        apiContainer = setupApiContainer()
        let indexPage = setupNodeServer()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.loadURL(string: indexPage)
        }
    }

    private func setupNodeServer() -> String {
        let port = 8080
        
        let rootInstallationFolder = Bundle.main.path(forResource: "nodejsProject", ofType: nil) ?? ""
        
        let path: String = Bundle.main.path(forResource: "nodejsProject/MobileServerLauncher.js", ofType: nil) ?? ""
        
        let pskServerPath = Bundle.main.path(forResource: "nodejsProject/pskWebServer.js", ofType: nil) ?? ""
        
        let apihubRootPath = Bundle.main.path(forResource: "nodejsProject/apihub-root", ofType: nil) ?? ""
        
        let env: [String: String] = [
            "PSK_CONFIG_LOCATION": "\(apihubRootPath)/external-volume/config",
            "PSK_ROOT_INSTALATION_FOLDER": rootInstallationFolder,
            "BDNS_ROOT_HOSTS": "http://localhost:\(port)"
        ]
        let envString = String(data: try! JSONEncoder().encode(env), encoding: .ascii)!
        

        Thread {
            NodeRunner.startEngine(withArguments: ["node", path, "--bundle=\(pskServerPath)", "--port=8080",
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
            let config = SFSafariViewController.Configuration()
            config.entersReaderIfAvailable = true

            let vc = SFSafariViewController(url: url, configuration: config)
            present(vc, animated: true)
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

