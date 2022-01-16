//
//  PhotoCaptureStreamAPI.swift
//  PSKNodeServer
//
//  Created by Costin Andronache on 16.01.2022.
//

import PSSmartWalletNativeLayer

final class PhotoCaptureStreamAPI {
    typealias ViewControllerProvider = DataMatrixScanAPI.ViewControllerProvider
    private let frameCaptureModule: CameraFrameCaptureModuleInput
    let hostController: ViewControllerProvider
    
    init(hostController: @autoclosure @escaping ViewControllerProvider,
         frameCaptureModule: CameraFrameCaptureModuleInput) {
        self.hostController = hostController
        self.frameCaptureModule = frameCaptureModule
    }
}

extension PhotoCaptureStreamAPI: StreamAPIImplementation {
    func openStream(input: [APIValue], completion: @escaping (Result<Void, APIError>) -> Void) {
        frameCaptureModule.launchFrameCaptureOn(hostController: hostController(),
                                                initializationCompletion: {
            switch $0 {
            case .failure(let cameraError):
                completion(.failure(.init(code: cameraError.code)))
            case .success:
                completion(.success(()))
            }
        })
    }
    
    func retrieveNext(input: [APIValue], into: @escaping (Result<[APIValue], APIError>) -> Void) {
        frameCaptureModule.captureNextFrame(handler: {
            switch $0 {
            case .failure(let error):
                into(.failure(.init(code: error.code)))
            case .success(let image):
                guard let pngData = image.pngData() else {
                    into(.failure(.init(code: CameraFrameCapture.PhotoCaptureError.photoCaptureFailure(nil).code)))
                    return
                }
                into(.success([.string(pngData.base64EncodedString())]))
            }
        })
    }
    
    func close() {
        frameCaptureModule.cancelFrameCapture()
    }
}

extension CameraFrameCapture.PhotoCaptureError {
    var code: String {
        switch self {
        case .photoCaptureFailure:
            return "ERR_PHOTO_CAPTURE_FAILURE"
        }
    }
}
