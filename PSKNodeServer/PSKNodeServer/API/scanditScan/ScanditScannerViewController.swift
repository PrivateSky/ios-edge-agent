//
//  ScanditScannerViewController.swift
//  PSKNodeServer
//
//  Created by Zrust, Vladimir on 16.06.2021.
//

import UIKit

class ScanditScannerViewController: UIViewController {
    @IBOutlet weak var apiKeyLabel: UILabel!
    private let scanditApiKey: String
    
    override func viewDidLoad() {
        super.viewDidLoad()
        apiKeyLabel.text = scanditApiKey
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(with scanditApiKey: String){
        self.scanditApiKey = scanditApiKey
        super.init(nibName: "ScanditScannerViewController", bundle: nil)
    }
}
