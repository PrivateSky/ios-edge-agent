//
//  CameraScreenPresenter.swift
//  PSKNodeServer
//
//  Created by Costin Andronache on 10.01.2022.
//

import AVFoundation
import UIKit

final class CameraScreenPresenter {
    typealias InitializationCompletion = (Result<Void, CameraScreen.InitializationError>) -> Void
    
    var onUserCancelAction: VoidBlock?
    
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var initializationCompletion: InitializationCompletion = { _ in }
    private weak var view: CameraScreenView?
    
    private var videoCaptureSession: VideoCaptureSessionModuleInput?
        
    func prepareForInitializationWith(view: CameraScreenView,
                                      videoCaptureSessionBuilder: VideoCaptureSessionModuleBuildable,
                                       initializationCompletion: @escaping InitializationCompletion) {
        self.view = view
        self.initializationCompletion = initializationCompletion
        
        view.onViewDidLoad = { [weak self] in
            self?.beginWith(videoCaptureSessionBuilder: videoCaptureSessionBuilder,
                            initializationCompletion: initializationCompletion)
        }
        
        view.onUserCancelAction = { [weak self] in
            self?.stopCapture()
            self?.onUserCancelAction?()
        }
    }
    
    private func beginWith(videoCaptureSessionBuilder: VideoCaptureSessionModuleBuildable, initializationCompletion: @escaping InitializationCompletion) {
        videoCaptureSessionBuilder.build(completion: { initializer in
            initializer.initializeModuleWith(completion: { [weak self] in
                switch $0 {
                case .failure(let error):
                    initializationCompletion(.failure(error))
                case .success(let videoCaptureModuleInput):
                    self?.videoCaptureSession = videoCaptureModuleInput
                    let layer = videoCaptureModuleInput.createVideoPreviewLayer()
                    self?.previewLayer = layer
                    self?.view?.integratePreviewLayer(layer)
                    initializationCompletion(.success(()))
                }
            })
        })
    }
}

extension CameraScreenPresenter: CameraScreenModuleInput {
    func addOutput(_ output: AVCaptureOutput) -> Result<Void, CameraScreen.AddOutputFailReason> {
        guard let videoCaptureSession = self.videoCaptureSession else {
            return (.failure(.featureNotAvailable))
        }
        
        return videoCaptureSession.addOutput(output)
    }
    
    func removeOutput(_ output: AVCaptureOutput) {
        videoCaptureSession?.removeOutput(output)
    }
    
    func convertObjectCoordinatesIntoOwnBounds<T>(object: T) -> T? where T : AVMetadataObject {
        previewLayer?.transformedMetadataObject(for: object) as? T
    }
    
    func integrateOverlayView(_ view: UIView) {
        self.view?.integrateOverlayView(view)
    }
    
    func stopCapture() {
        videoCaptureSession?.stopCapture()
    }
}
