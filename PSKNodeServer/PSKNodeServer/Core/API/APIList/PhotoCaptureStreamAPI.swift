//
//  PhotoCaptureStreamAPI.swift
//  PSKNodeServer
//
//  Created by Costin Andronache on 16.01.2022.
//

import PSSmartWalletNativeLayer

final class PhotoCaptureStreamAPI {
    typealias ViewControllerProvider = DataMatrixScanAPI.ViewControllerProvider
    private let frameCaptureModuleBuilder: CameraFrameCaptureModuleBuildable
    private var frameCaptureModuleInput: CameraFrameCaptureModuleInput?
    
    init(frameCaptureModuleBuilder: CameraFrameCaptureModuleBuildable) {
        self.frameCaptureModuleBuilder = frameCaptureModuleBuilder
    }
}

extension PhotoCaptureStreamAPI: StreamAPIImplementation {
    func openStream(input: [APIValue], completion: @escaping (Result<Void, APIError>) -> Void) {
        frameCaptureModuleBuilder.build(completion: { initializer in
            initializer.initializeModuleWith(completion: {
                switch $0 {
                case .failure(let error):
                    completion(.failure(.init(code: error.code)))
                case .success(let input):
                    self.frameCaptureModuleInput = input
                    completion(.success(()))
                }
            })
        })
    }
    
    func retrieveNext(input: [APIValue], into: @escaping (Result<[APIValue], APIError>) -> Void) {
        frameCaptureModuleInput?.captureNextFrame(handler: {
            switch $0 {
            case .failure(let error):
                into(.failure(.init(code: error.code)))
            case .success(let image):
                guard let jpegData = image.jpegData(compressionQuality: 1.0) else {
                    into(.failure(.init(code: CameraFrameCapture.PhotoCaptureError.photoCaptureFailure(nil).code)))
                    return
                }
                into(.success([.string("data:image/jpeg;base64," + jpegData.base64EncodedString())]))
            }
        })
    }
    
    func close() {
        frameCaptureModuleInput?.cancelFrameCapture()
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
