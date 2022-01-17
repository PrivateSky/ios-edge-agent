//
//  VideoCaptureSessionModule.swift
//  PSKNodeServer
//
//  Created by Costin Andronache on 17.01.2022.
//

import AVFoundation

protocol VideoCaptureSessionModuleInput {
    func stopCapture()
    func addOutput(_ output: AVCaptureOutput) -> Result<Void, VideoCaptureSession.AddOutputFailReason>
    func removeOutput(_ output: AVCaptureOutput)
    func createVideoPreviewLayer() -> AVCaptureVideoPreviewLayer
}

protocol VideoCaptureSessionModuleBuildable {
    func build(completion: @escaping (AnyViewlessModuleInitializer<VideoCaptureSessionModuleInput,
                                      VideoCaptureSession.InitializationError>) -> Void)
}

final class VideoCaptureSessionModule {
    private let captureSession: AVCaptureSession = .init()
}

extension VideoCaptureSessionModule: VideoCaptureSessionModuleInput {
    func addOutput(_ output: AVCaptureOutput) -> Result<Void, CameraScreen.AddOutputFailReason> {
        guard captureSession.canAddOutput(output) else {
            return (.failure(.featureNotAvailable))
        }
        captureSession.addOutput(output)
        return .success(())
    }
    
    func removeOutput(_ output: AVCaptureOutput) {
        captureSession.removeOutput(output)
    }
    
    func stopCapture() {
        captureSession.stopRunning()
    }
    
    func createVideoPreviewLayer() -> AVCaptureVideoPreviewLayer {
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        return previewLayer
    }
}

extension VideoCaptureSessionModule: ViewlessModuleInitializer {
    typealias ModuleInputType = VideoCaptureSessionModuleInput
    typealias ErrorType = VideoCaptureSession.InitializationError
    
    func initializeModuleWith(completion: @escaping ViewlessModuleInitialization<VideoCaptureSessionModuleInput, VideoCaptureSession.InitializationError>.Completion) {
        if AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized {
            beginVideoCapture(completion: completion)
        } else {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { [weak self] (granted: Bool) in
                DispatchQueue.main.async {
                    if granted {
                        self?.beginVideoCapture(completion: completion)
                    } else {
                        completion(.failure(.cameraNotAvailable))
                    }
                }
            })
        }
    }
    
    private func beginVideoCapture(completion: @escaping ViewlessModuleInitialization<VideoCaptureSessionModuleInput, VideoCaptureSession.InitializationError>.Completion) {
    
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            completion(.failure(.cameraNotAvailable))
            return
        }
        
        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            } else {
                completion(.failure(.cameraNotAvailable))
                return
            }
        } catch {
            completion(.failure(.cameraNotAvailable))
            return
        }

        captureSession.startRunning()
        completion(.success(self))
    }
}

extension VideoCaptureSessionModule: VideoCaptureSessionModuleBuildable {
    func build(completion: @escaping (AnyViewlessModuleInitializer<VideoCaptureSessionModuleInput, VideoCaptureSession.InitializationError>) -> Void) {
        completion(.init(aggregating: self))
    }
}
