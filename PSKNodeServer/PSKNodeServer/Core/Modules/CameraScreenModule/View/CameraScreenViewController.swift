//
//  CodeScannerViewController.swift
//
//  Created by Costin Andronache on 9/16/20.
//

import AVFoundation
import UIKit

protocol CameraScreenView: BaseModuleView {
    var onUserCancelAction: VoidBlock? { get set }
    func integratePreviewLayer(_ layer: CALayer)
    func integrateOverlayView(_ view: UIView)
}

final class CameraScreenViewController: BaseModuleViewController {
    var onUserCancelAction: VoidBlock?
    
    @IBOutlet private var previewHostView: UIView?
    @IBOutlet private var cancelButton: UIButton?
    
    private var previewLayer: CALayer?
    private let soundFile = CodeScannerSoundFile()
        
    convenience init() {
        self.init(nibName: "CameraScreenViewController", bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        previewHostView?.backgroundColor = UIColor.black

        cancelButton?.setTitle(NSLocalizedString("cancel", comment: ""), for: .application)
        cancelButton?.layer.borderWidth = 4.0
        cancelButton?.layer.borderColor = UIColor.white.cgColor
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        previewLayer?.frame = view.bounds
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    @IBAction private func didPressCancel() {
        onUserCancelAction?()
    }
}

extension CameraScreenViewController: CameraScreenView {
    func integrateOverlayView(_ view: UIView) {
        self.view.constrainFull(other: view)
        cancelButton.map({
            self.view.bringSubviewToFront($0)
        })
    }
            
    func integratePreviewLayer(_ layer: CALayer) {
        layer.frame = view.layer.bounds
        previewHostView?.layer.addSublayer(layer)
        previewLayer = layer
    }
}

extension CameraScreenViewController {
    enum FailReason: Error {
        case noCodeFound
        case featureNotAvailable
        case cameraUnavailable
        case userCancelled
    }
    typealias Completion = (Result<String, FailReason>) -> Void
}
