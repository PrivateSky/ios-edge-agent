//
//  CaptureProcessor.swift
//  WkCamera
//
//  Created by Yves Delacrétaz on 27.07.21.
//

import Foundation
import AVFoundation

private var _isCaptured = false
public var isCaptured: Bool {return _isCaptured}

private var _completion: ((Data) -> Void)?
private var imageData: Data? = nil 

public class CaptureProcessor: NSObject, AVCapturePhotoCaptureDelegate {
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation() else {
            return
        }
        if let completion = _completion {
            _isCaptured = true
            completion(imageData)
        }
    }
    
    public init(completion: @escaping (Data) -> Void) {
        _completion = completion
    }
}
