// 
//  CameraConfiguration.swift
//  PharmaLedger Camera
//
//  Created by Ville Raitio on 21.6.2021.
//  
//
	

import Foundation
import AVFoundation

protocol CameraConfigurationChangeListener {
    func onConfigurationsChanged()
}

/// CameraConfiguration class that contains all the necessary configurations for the camera
public class CameraConfiguration {
    
    //MARK: Constants and variables
    
    private var flash_configuration:String = "auto"
    private var torchmode:AVCaptureDevice.TorchMode = .auto
    private var flashmode:AVCaptureDevice.FlashMode = .auto
    private var torchlevel:Float = 1.0
    private var sessionPreset:AVCaptureSession.Preset = .photo
    private var aspectRatio:CGFloat = 4.0/3.0
    
    private let deviceTypeDefaults:[AVCaptureDevice.DeviceType] =  [.builtInWideAngleCamera]
    private var deviceTypes:[AVCaptureDevice.DeviceType] = [.builtInTripleCamera,
                                                            .builtInDualCamera,
                                                            .builtInDualWideCamera,
                                                            .builtInTrueDepthCamera,
                                                            .builtInWideAngleCamera,
                                                            .builtInTelephotoCamera
    ]
    private var cameraPosition:AVCaptureDevice.Position = .back
    
    private var colorSpace:AVCaptureColorSpace?
    
    /// Predefines the orientation when initializing the camera (available values are "landscapeRight", "landscapeLeft" and "portrait").
    public var initOrientation:String?
    
    /// List of supported aspect ratios. 16/9 || 4/3 || 11/9
    public let supportedAspectRatios:[CGFloat] = [16.0/9.0, 4.0/3.0, 11.0/9.0]
    
    var delegate:CameraConfigurationChangeListener?
    
    /** If true, the CameraSession will monitor device orientation changes and automatically swap the camera preview and photo capture orientation between "portrait", "landscapeLeft" and "landscapeRight"
     
     Default: true
     
     This variable should be defined
     before the camera is initialized.
     */
    public var autoOrientationEnabled:Bool = true
    
    /** Defines the preferred [AVCaptureDevice.FocusMode](https://developer.apple.com/documentation/avfoundation/avcapturedevice/focusmode).
     If true, preferred focusmode will be set to **continuousAutoFocus**, otherwise the mode will switch between **autoFocus** and **locked**.
     
     Default: true
     
     */
    public var continuousFocus:Bool = true
    
    ///If high resolution is enabled, the photo capture will be taken with the highest possible resolution available. Default: **true**
    public var highResolutionCaptureEnabled = true
    
    //MARK: Initialization
    
    /// Initializes the camera confifugration with default values. To further customize the configuration, call any
    public init() {
        self.setFlashConfiguration(flash_mode: "auto")
        self.torchlevel = 1.0
        self.autoOrientationEnabled = true
        self.deviceTypes = deviceTypeDefaults
    }
    
    /// Initialize the camera session with customizable configurations. Parameters that don't need to be configured can be left as nil.
    /// - Parameter flash_mode: Available modes are "torch", "flash", "off" and "auto"
    /// - Parameter color_space: Possible values are "sRGB", "P3_D65" or "HLG_BT2020".
    /// - Parameter session_preset: Session preset in String format. See **setSessionPreset** for more information.
    /// - Parameter device_types: Additional criteria for selecting the camera. Supported values are **tripleCamera**, **dualCamera**, **dualWideCamera**, **wideAngleCamera**, **ultraWideAngleCamera**, **telephotoCamera** and **trueDepthCamera**. Device discovery session will prioritize device types in the array based on their array index. Defaults to ["wideAngleCamera"] if undefined or empty.
    /// - Parameter camera_position: "back" or "front". If not defined, this setting will default to "back"
    /// - Parameter continuous_focus: Defines the preferred [AVCaptureDevice.FocusMode](https://developer.apple.com/documentation/avfoundation/avcapturedevice/focusmode). If true, preferred focusmode will be set to **continuousAutoFocus**, otherwise the mode will switch between **autoFocus** and **locked**.
    /// - Parameter highResolutionCaptureEnabled: If high resolution is enabled, the photo capture will be taken with the highest possible resolution available.
    /// - Parameter auto_orientation_enabled: If set to true, camera session will attempt to automatically adjust the preview and capture orientation based on the device orientation
    /// - Parameter init_orientation: Predefines the orientation when initializing the camera (available values are "landscapeRight", "landscapeLeft" and "portrait").
    public init(flash_mode: String?, color_space:String?, session_preset:String?, device_types:[String]?, camera_position:String?, continuous_focus:Bool, highResolutionCaptureEnabled:Bool, auto_orientation_enabled:Bool, init_orientation:String? = nil) {
        self.setFlashConfiguration(flash_mode: flash_mode ?? self.flash_configuration)
        self.setPreferredColorSpace(color_space: color_space ?? "")
        self.autoOrientationEnabled = auto_orientation_enabled
        self.setSessionPreset(preset: session_preset)
        self.continuousFocus = continuous_focus
        self.setDeviceTypes(deviceTypes: device_types)
        self.setCameraPosition(position: camera_position)
        self.highResolutionCaptureEnabled = highResolutionCaptureEnabled
        self.initOrientation = init_orientation
    }
    
    //MARK: Public functions
    
    /// Applies the configurations to the current AVCaptureSession. This should be executed each time the configurations are changed during session runtime.
    public func applyConfiguration(){
        self.delegate?.onConfigurationsChanged()
    }
    
    /** Conversion to dictionary
 - Returns: [String: AnyObject] dictionary. Available dictionary keys are:
     - "preferredColorSpace" (String)
     - "sessionPreset" (String)
     - "flashConfiguration" (String)
     - "torchLevel" (Float)
     - "aspectRatio" (CGFloat)
     - "autoOrientationEnabled" (Bool)
     - "deviceTypes" (String array)
     - "cameraPosition" (String)
     - "continuousFocus" (Bool)
     - "highResolutionCaptureEnabled" (Bool)
     - "initOrientation" (String)
 */
    public func toDict() -> [String: AnyObject] {
        var dict = [String: AnyObject]()
        dict["preferredColorSpace"] = self.getPreferredColorSpaceString() as AnyObject
        dict["sessionPreset"] = self.getSessionPresetString() as AnyObject
        dict["flashConfiguration"] = self.getFlashConfiguration() as AnyObject
        dict["torchLevel"] = self.getTorchLevel() as AnyObject
        dict["aspectRatio"] = self.getAspectRatio() as AnyObject
        dict["autoOrientationEnabled"] = self.autoOrientationEnabled as AnyObject
        dict["deviceTypes"] = self.getDeviceTypeStrings() as AnyObject
        dict["cameraPosition"] = self.getCameraPositionString() as AnyObject
        dict["continuousFocus"] = self.continuousFocus as AnyObject
        dict["highResolutionCaptureEnabled"] = self.highResolutionCaptureEnabled as AnyObject
        dict["initOrientation"] = self.initOrientation as AnyObject
        return dict
    }
    
    /** Creates configuration instance from a dictionary
- Parameter configDict: Dictionary array. Use the following keys for configurations:
     - "preferredColorSpace" (String)
     - "sessionPreset" (String)
     - "flashConfiguration" (String)
     - "torchLevel" (Float)
     - "aspectRatio" (CGFloat)
     - "autoOrientationEnabled" (Bool)
     - "deviceTypes" (String array)
     - "cameraPosition" (String)
     - "continuousFocus" (Bool)
     - "highResolutionCaptureEnabled" (Bool)
     - "initOrientation" (String)
- Returns: CameraConfiguration
 */
    public class func createFromConfig(configDict: [String: AnyObject]) -> CameraConfiguration {
        let colorspace = configDict["preferredColorSpace"] as? String
        let session_preset = configDict["sessionPreset"] as? String
        let flash_config = configDict["flashConfiguration"] as? String
        var auto_orientation_enabled = false
        if let auto_orientation = configDict["autoOrientationEnabled"] as? Bool {
            auto_orientation_enabled = auto_orientation
        }
        
        let device_types = configDict["deviceTypes"] as? [String]
        let camera_position = configDict["cameraPosition"] as? String
        var continuous_focus_enabled = true
        if let continuous_focus = configDict["continuousFocus"] as? Bool {
            continuous_focus_enabled = continuous_focus
        }
        var high_resolution_capture_enabled = true
        if let high_res_enabled = configDict["highResolutionCaptureEnabled"] as? Bool {
            high_resolution_capture_enabled = high_res_enabled
        }
        let instance = CameraConfiguration.init(flash_mode: flash_config, color_space: colorspace, session_preset: session_preset, device_types: device_types, camera_position: camera_position, continuous_focus: continuous_focus_enabled, highResolutionCaptureEnabled: high_resolution_capture_enabled, auto_orientation_enabled: auto_orientation_enabled, init_orientation: (configDict["initOrientation"] as? String) ?? nil)
        if let torch_level = configDict["torchLevel"] as? NSNumber {
            instance.torchlevel = torch_level.floatValue
        }
        return instance
    }
    
    //MARK: Flash and torch mode
    
    /// Returns the current torch mode in AVCaptureDevice.TorchMode format
    /// - Returns: TorchMode (.on, .auto or .off)
    public func getTorchMode()->AVCaptureDevice.TorchMode {
        return self.torchmode
    }
    
    /// Returns the current flash and torch mode in String format
    /// - Returns: "torch", "flash", "off" or "auto"
    public func getFlashConfiguration()->String?{
        return flash_configuration
    }
    
    /// Returns the current torch mode in AVCaptureDevice.FlashMode format to be used with the photo capture
    /// - Returns: FlashMode (.on, .auto or .off)
    public func getFlashMode()->AVCaptureDevice.FlashMode{
        return flashmode
    }
    
    /// Get the current torch level
    /// - Returns: Torch level from 0-1.0. Default is 1.0
    public func getTorchLevel()->Float {
        return torchlevel
    }
    
    
    /// Sets the camera torch and flash mode
    /// - Parameter flash_mode: Available modes are "torch", "flash", "off" and "auto"
    public func setFlashConfiguration(flash_mode:String){
        self.flash_configuration = flash_mode
        switch flash_mode {
        case "torch":
            self.torchmode = .on
            self.flashmode = .auto
            break
        case "off":
            self.torchmode = .off
            self.flashmode = .off
            break
        case "flash":
            self.torchmode = .off
            self.flashmode = .on
            break
        default:
            self.torchmode = .off
            self.flashmode = .auto
            break
        }
    }
    
    /// Sets the torch level
    /// - Parameter level: Float in the range of 0 to 1.0
    public func setTorchLevel(level:Float){
        self.torchlevel = level
    }
    
    //MARK: Color space
    
    /// Gets the current preference for color space as AVCaptureColorSpace enum value.
    /// - Returns: Returns .sRGB, .P3_D65 or .HLG_BT2020. Returns nil if the color space configuration was undefined
    public func getPreferredColorSpace() -> AVCaptureColorSpace?  {
        return self.colorSpace
    }
    
    /// Gets the current preference for color space as String.
    /// - Returns: Returns "sRGB", "P3_D65" or "HLG_BT2020" or "undefined"
    public func getPreferredColorSpaceString() -> String{
        switch self.colorSpace {
        case .HLG_BT2020: return "HLG_BT2020"
        case .sRGB: return "sRGB"
        case .P3_D65: return "P3_D65"
        default: return "undefined"
        }
    }
    
    /** Sets the preferred color space.
     
     Depending on the device some color spaces might not be supported.
     sRGB is supported on all devices.
     HLG_BT2020 available from iOS v14.1
     
- Parameter color_space: Possible values are "sRGB", "P3_D65" or "HLG_BT2020".
     */
    public func setPreferredColorSpace(color_space:String){
        switch color_space {
        case "sRGB":
            self.colorSpace = .sRGB
            break
        case "HLG_BT2020":
            if #available(iOS 14.1, *) {
                self.colorSpace = .HLG_BT2020
            } else {
                // Fallback on earlier versions
                self.colorSpace = .P3_D65
            }
            break
        case "P3_D65":
            self.colorSpace = .P3_D65
            break
        default:
            self.colorSpace = nil
            break
        }
    }
    
    //MARK: Session presets and aspect ratio
    
    /**
     Sets the desired aspect ratio. If an unsupported aspect ratio is given, the closest possible aspect ratio will be selected
     
     Session preset will be assigned as follows:
     - 4/3: .photo
     - 16/9: .high
     - 11/9: .cif352x288
     
     - Parameter aspectRatio: Supported values are 4/3, 16/9 and 11/9
     
     */
    public func setAspectRatio(aspectRatio:CGFloat){
        var closestAspectRatio:CGFloat = 4.0/3.0
        if(!supportedAspectRatios.contains(aspectRatio)){
            //get the closest desired aspect ratio
            var distanceToClosestAspectRatio:CGFloat = abs(aspectRatio - closestAspectRatio)
            for ratio in supportedAspectRatios {
                let distanceToAspectRatio = abs(aspectRatio - ratio)
                if(distanceToAspectRatio < distanceToClosestAspectRatio){
                    distanceToClosestAspectRatio = distanceToAspectRatio
                    closestAspectRatio = ratio
                }
            }
        }else{
            closestAspectRatio = aspectRatio
        }
        self.aspectRatio = closestAspectRatio
        if(self.aspectRatio == 4.0/3.0){
            sessionPreset = .photo
        }else if(self.aspectRatio == 16.0/9.0){
            sessionPreset = .high
        }else{
            sessionPreset = .cif352x288
        }
    }
    
    /// Sets the session preset
    /// - Parameter preset: Session preset in String format.
    ///
    /// 4:3 parameters:
    /// - "photo"
    /// - "low"
    /// - "medium"
    /// - "vga640x480"
    ///
    /// 16:9 parameters:
    /// - "high"
    /// - "inputPriority"
    /// - "hd1280x720"
    /// - "hd1920x1080"
    /// - "hd4K3840x2160"
    /// - "iFrame960x540"
    /// - "iFrame1280x720"
    ///
    ///  11:9 parameters:
    /// - "cif352x288"
    ///
    /// See [AVCaptureSession.Preset documentation by Apple](https://developer.apple.com/documentation/avfoundation/avcapturesession/preset) for more information
    public func setSessionPreset(preset:String?){
        switch preset {
        case "low":
            sessionPreset = .low
            aspectRatio = 4.0/3.0
        case "medium":
            sessionPreset = .medium
            aspectRatio = 4.0/3.0
        case "high":
            sessionPreset = .high
            aspectRatio = 16.0/9.0
        case "inputPriority":
            sessionPreset = .inputPriority
            aspectRatio = 16.0/9.0
        case "hd1280x720":
            sessionPreset = .hd1280x720
            aspectRatio = 16.0/9.0
        case "hd1920x1080":
            sessionPreset = .hd1920x1080
            aspectRatio = 16.0/9.0
        case "hd4K3840x2160":
            sessionPreset = .hd4K3840x2160
            aspectRatio = 16.0/9.0
        case "iFrame960x540":
            sessionPreset = .iFrame960x540
            aspectRatio = 16.0/9.0
        case "iFrame1280x720":
            sessionPreset = .iFrame1280x720
            aspectRatio = 16.0/9.0
        case "vga640x480":
            sessionPreset = .vga640x480
            aspectRatio = 4.0/3.0
        case "cif352x288":
            sessionPreset = .cif352x288
            aspectRatio = 11.0/9.0
        default://photo
            sessionPreset = .photo
            aspectRatio = 4.0/3.0
        }
    }
    
    /// Returns the current session preset
    /// - Returns: Session preset as String
    public func getSessionPresetString() -> String {
        switch sessionPreset {
        case .low: return "low"
        case .high: return "high"
        case .medium: return "medium"
        case .inputPriority: return "inputPriority"
        case .hd1280x720: return "hd1280x720"
        case .hd1920x1080: return "hd1920x1080"
        case .hd4K3840x2160: return "hd4K3840x2160"
        case .iFrame960x540: return "iFrame960x540"
        case .iFrame1280x720: return "iFrame1280x720"
        case .vga640x480: return "vga640x480"
        case .cif352x288: return "cif352x288"
        case .photo: return "photo"
        default: return ""
        }
    }
    
    /// Returns the current session preset
    /// - Returns: Session preset as [AVCaptureSession.Preset](https://developer.apple.com/documentation/avfoundation/avcapturesession/preset) enum
    public func getSessionPreset() -> AVCaptureSession.Preset {
        return sessionPreset
    }
    
    /// Get the current configuration aspect ratio
    /// - Returns: Camera aspect ratio, eg. 4.0/3.0 (longer side divided by shorter side)
    public func getAspectRatio() -> CGFloat{
        return aspectRatio
    }
    
    //MARK: Camera selection
    
    /// Sets the device type criteria for [the device discovery session](https://developer.apple.com/documentation/avfoundation/avcapturedevice/discoverysession)
    /// - Parameter deviceTypes: Supported values are **tripleCamera**, **dualCamera**, **dualWideCamera**, **wideAngleCamera**, **ultraWideAngleCamera**, **telephotoCamera** and **trueDepthCamera**. Device discovery session will prioritize device types in the array based on their array index.
    ///
    /// If an empty array is passed, the configuration will fallback to ["wideAngleCamera"]
    public func setDeviceTypes(deviceTypes:[String]?){
        var devicetypesArray:[AVCaptureDevice.DeviceType] = []
        
        if deviceTypes != nil {
            
            for deviceTypeString in deviceTypes! {
                if let deviceType = stringToDeviceType(deviceType: deviceTypeString){
                    devicetypesArray.append(deviceType)
                }
            }
            if(devicetypesArray.isEmpty){
                devicetypesArray = deviceTypeDefaults
            }
            
        }else{
            devicetypesArray = deviceTypeDefaults
        }
        self.deviceTypes = devicetypesArray
    }
    
    /// Gets the current device type criteria used for [device discovery](https://developer.apple.com/documentation/avfoundation/avcapturedevice/discoverysession)
    /// - Returns: Device type enum array. See [AVCaptureDevice.DeviceType](https://developer.apple.com/documentation/avfoundation/avcapturedevice/devicetype) for more info
    public func getDeviceTypes() -> [AVCaptureDevice.DeviceType]{
        return self.deviceTypes
    }
    
    /// Gets the current device type criteria used for [device discovery](https://developer.apple.com/documentation/avfoundation/avcapturedevice/discoverysession)
    /// - Returns: Device type array in String format
    public func getDeviceTypeStrings() -> [String]{
        var deviceTypeStringsArray:[String] = []
        for deviceType in self.deviceTypes {
            if let deviceTypeString = deviceTypeToString(deviceType: deviceType) {
                deviceTypeStringsArray.append(deviceTypeString)
            }
        }
        return deviceTypeStringsArray
    }
    
    private func stringToDeviceType(deviceType:String) -> AVCaptureDevice.DeviceType?{
        switch deviceType {
        case "tripleCamera":
            return .builtInTripleCamera
        case "dualCamera":
            return .builtInDualCamera
        case "dualWideCamera":
            return .builtInDualWideCamera
        case "ultraWideAngleCamera":
            return .builtInUltraWideCamera
        case "trueDepthCamera":
            return .builtInTrueDepthCamera
        case "wideAngleCamera":
            return .builtInWideAngleCamera
        case "telephotoCamera":
            return .builtInTelephotoCamera
        default:
            return nil
        }
    }
    
    private func deviceTypeToString(deviceType:AVCaptureDevice.DeviceType) -> String?{
        switch deviceType {
        case .builtInTripleCamera:
            return "tripleCamera"
        case .builtInDualCamera:
            return "dualCamera"
        case .builtInDualWideCamera:
            return "dualWideCamera"
        case .builtInTrueDepthCamera:
            return "trueDepthCamera"
        case .builtInWideAngleCamera:
            return "wideAngleCamera"
        case .builtInTelephotoCamera:
            return "telephotoCamera"
        case .builtInUltraWideCamera:
            return "ultraWideAngleCamera"
        default:
            return nil
        }
    }
    
    /// Sets the camera position.
    /// - Parameter position: Position in string format. Available values are "front" and "back"
    public func setCameraPosition(position:String?){
        if(position == "front"){
            self.cameraPosition = .front
        }else{
            self.cameraPosition = .back
        }
    }
    
    /// Gets the current camera position.
    /// - Returns: Returns the current camera position as [AVCaptureDevice.Position](https://developer.apple.com/documentation/avfoundation/avcapturedevice/position) enum.
    public func getCameraPosition() ->AVCaptureDevice.Position {
        return self.cameraPosition
    }
    
    /// Gets the current camera position.
    /// - Returns: Returns the current camera position as String ("back" or "front")
    public func getCameraPositionString() -> String {
        if(self.cameraPosition == .back){
            return "back"
        } else {
            return "front"
        }
    }
}
