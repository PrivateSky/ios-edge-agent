//
//  BaseModuleView.swift
//  PSKNodeServer
//
//  Created by Costin Andronache on 10.01.2022.
//

import UIKit

protocol BaseModuleView: AnyObject {
    var onViewDidLoad: VoidBlock? { get set }
    var onViewWillAppear: VoidBlock? { get set }
}

class BaseModuleViewController: UIViewController, BaseModuleView {
    var onViewDidLoad: VoidBlock?
    var onViewWillAppear: VoidBlock?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        onViewDidLoad?()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        onViewWillAppear?()
    }
}
