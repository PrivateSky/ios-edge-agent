// 
//  Helpers.swift
//  PharmaLedger Camera
//
//  Created by Ville Raitio on 15.6.2021.
//
	

import Foundation
import AVFoundation
import UIKit
import Photos


//MARK: Data extension
extension Data {
    /**
     Saves the image to photos library. Requires NSPhotoLibraryUsageDescription declaration in Info.plist file.
     */
    public func savePhotoToLibrary(){
        PHPhotoLibrary.requestAuthorization { (status) in
            if status == .authorized{
                PHPhotoLibrary.shared().performChanges({
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    
                    creationRequest.addResource(with: .photo, data: self, options: nil)
                    
                }, completionHandler: { success, error in
                    if !success, let error = error {
                        print("error creating asset: \(error)")
                        
                    }else{
                        print("file saved succesfully!")
                    }
                    
                })
                
            }else{
                
            }
        }
    }

    /**
     Saves the image data to the app file directory. Returns the final absolute path to the file as String
     - Parameter fileName: Name for the saved image (.jpg will be appended to the end)
     - Returns: Absolute String path of the saved file.
     */
    public func savePhotoToFiles(fileName:String) -> String?{
        guard let directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) as NSURL else {
            print("Failed to save photo")
            return nil
        }
        let finalPath = "\(directory.absoluteString!)\(fileName).jpg"
        
        do {

            try self.write(to: URL.init(string: finalPath)!)
            print("Data written to \(finalPath)")
            return finalPath
        }catch{
            print("Data write failed: \(error.localizedDescription)")
            return nil
        }
        
    }
    
    /**
     Converts a Data object to UInt8 byte array
     - Returns: Byte array in UInt8 form
     */
    public func imageDataToBytes() -> [UInt8] {
        return [UInt8](self)
    }
}

//MARK: CMSampleBuffer extension

extension CMSampleBuffer {
    
    /// Converts the samplebuffer to CGImage
    /// - Parameter ciContext: CIContext required for creating the CGImage
    /// - Returns: CGImage
    public func bufferToCGImage(ciContext:CIContext) ->CGImage?{
        guard let imageBuffer = CMSampleBufferGetImageBuffer(self) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return cgImage
    }
    
    /// Converts the samplebuffer to UIImage
    /// - Parameter ciContext: CIContext required for creating the CGImage
    /// - Returns: UIImage
    public func bufferToUIImage(ciContext:CIContext) ->UIImage?{
        guard let cgImage = bufferToCGImage(ciContext: ciContext) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
    
    /// Converts the samplebuffer to a Data object
    /// - Parameters:
    ///   - ciContext: CIContext required for creating the CGImage
    ///   - jpegCompression: JPEG Compression level for the Data. Maximum is 1.0
    /// - Returns: Data
    public func bufferToData(ciContext:CIContext, jpegCompression:CGFloat) -> Data? {
        guard let image:UIImage = bufferToUIImage(ciContext: ciContext) else {
            return nil
        }
        guard let data:Data = image.jpegData(compressionQuality: jpegCompression) else {
            return nil
        }
        return data
    }
}

//MARK: UIDevice extension

public extension UIDevice {

    /** Gets device information as a dictionary.
 - Returns: [String: AnyObject] dictionary. Available dictionary keys are:
     - "modelName" (String)
     - "systemVersion" (String)
     
     # Code:
     ```
     let deviceInfo = UIDevice.getDeviceInfo()
     print("deviceInfo","\(deviceInfo)")
     ```
     */
    static func getDeviceInfo() -> [String: AnyObject] {
        
        var dict = [String: AnyObject]()
        dict["modelIdentifier"] = modelIdentifier as AnyObject
        dict["systemVersion"] = current.systemVersion as AnyObject
        return dict
    }
    
    /// Model identifier
    /// # Example
    /// This parameter will be either "iPhone10,1" or "iPhone10,4" for iPhone 8
    static let modelIdentifier:String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        return identifier
    }()

}

