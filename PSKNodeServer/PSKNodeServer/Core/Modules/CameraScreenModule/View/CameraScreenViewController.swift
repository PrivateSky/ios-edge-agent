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
    func playCaptureAnimation(withSound: Bool)
    func playFocusAnimation(withinViewBoundsRect rect: CGRect,
                            withSound: Bool,
                            completion: VoidBlock?)
}

final class CameraScreenViewController: BaseModuleViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onUserCancelAction: VoidBlock?
    
    @IBOutlet private var scannerAnimationView: ScannerAnimationView?
    @IBOutlet private var previewHostView: UIView?
    @IBOutlet private var cancelButton: UIButton?
    
    private var previewLayer: AVCaptureVideoPreviewLayer?
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
    func playCaptureAnimation(withSound: Bool) {
        
    }
    
    func playFocusAnimation(withinViewBoundsRect rect: CGRect, withSound: Bool, completion: VoidBlock?) {
        scannerAnimationView?.focusOn(rect: rect, completion: { [weak self] in
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            if withSound {
                self?.soundFile.play()
            }
            completion?()
        })
    }
        
    func integratePreviewLayer(_ layer: CALayer) {
        layer.frame = view.layer.bounds
        previewHostView?.layer.addSublayer(layer)
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
