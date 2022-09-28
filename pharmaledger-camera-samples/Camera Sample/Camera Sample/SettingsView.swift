// 
//  SettingsView.swift
//  Camera Sample
//
//  Created by Ville Raitio on 23.6.2021.
//  
//
	

import UIKit
import PharmaLedger_Camera

/// Delegate for setting changes
protocol SettingsViewDelegate {
    func onTorchLevelChanged(level:Float)
    func onColorSpaceChanged(color_space:String)
    func onFlashModeChanged(flash_mode:String)
    func onSaveModeChanged(save_mode:String)
    func onSessionPresetChanged(session_preset:String)
    func onDeviceTypeChanged(device_type:String)
    func onCameraPositionChanged(camera_position:String)
    func onContinuousFocusChanged(continuous_focus:Bool)
    func onHighResolutionEnabled(high_resolution:Bool)
}

/// Scrollable view containing camera settings
class SettingsView:UIScrollView, UIPickerViewDelegate, UIPickerViewDataSource{
    
    //MARK: UIPickerViewDataSource
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if(pickerView == flashmodePicker){
            return flashModeValues.count
        }else if(pickerView == colorSpacePicker){
            return colorSpaceValues.count
        }else if(pickerView == saveModePicker){
            return saveModeValues.count
        }else if(pickerView == sessionPresetPicker){
            return sessionPresetValues.count
        }else if(pickerView == deviceTypePicker){
            return deviceTypeValues.count
        }else{
            return 1
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if(pickerView == flashmodePicker){
            return flashModeValues[row]
        }else if(pickerView == colorSpacePicker){
            return colorSpaceValues[row]
        }else if(pickerView == saveModePicker){
            return saveModeValues[row]
        }else if(pickerView == sessionPresetPicker){
            return sessionPresetValues[row]
        }else if(pickerView == deviceTypePicker){
            return deviceTypeValues[row]
        }else{
            return ""
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if(pickerView == flashmodePicker){
            self.currentFlashMode = flashModeValues[row]
            self.settingsViewDelegate?.onFlashModeChanged(flash_mode: self.currentFlashMode)
            print("current flash mode: \(self.currentFlashMode)")
        }else if(pickerView == colorSpacePicker){
            self.currentColorSpace = colorSpaceValues[row]
            self.settingsViewDelegate?.onColorSpaceChanged(color_space: self.currentColorSpace)
            print("current color space: \(self.currentColorSpace)")
        }else if(pickerView == saveModePicker){
            self.currentSaveMode = saveModeValues[row]
            self.settingsViewDelegate?.onSaveModeChanged(save_mode: self.currentSaveMode)
            print("current save mode: \(self.currentSaveMode)")
        }else if(pickerView == sessionPresetPicker){
            self.currentSessionPreset = sessionPresetValues[row]
            self.settingsViewDelegate?.onSessionPresetChanged(session_preset: self.currentSessionPreset)
        }else if(pickerView == deviceTypePicker){
            self.currentDeviceType = deviceTypeValues[row]
            self.settingsViewDelegate?.onDeviceTypeChanged(device_type: self.currentDeviceType)
        }else{
            
        }
    }
    
    //MARK: UI Views
    
    private let containerView:UIStackView = UIStackView.init()
    
    private let flashModeLabel:UILabel = UILabel.init()
    private let flashmodePicker:UIPickerView = UIPickerView.init()
    
    private let colorSpaceLabel:UILabel = UILabel.init()
    private let colorSpacePicker:UIPickerView = UIPickerView.init()
    
    private let saveModeLabel:UILabel = UILabel.init()
    private let saveModePicker:UIPickerView = UIPickerView.init()
    
    private let deviceTypeLabel:UILabel = UILabel.init()
    private let deviceTypePicker:UIPickerView = UIPickerView.init()
    
    private let cameraPositionLabel:UILabel = UILabel.init()
    private let cameraPositionSwitch:UISwitch = UISwitch.init()
    
    private let torchLevelLabel:UILabel = UILabel.init()
    private let torchLevelSlider:UISlider = UISlider.init()
    
    private let sessionPresetLabel:UILabel = UILabel.init()
    private let sessionPresetPicker:UIPickerView = UIPickerView.init()
    
    private let focusModeLabel:UILabel = UILabel.init()
    private let focusModeSwitch:UISwitch = UISwitch.init()
    
    private let highResolutionLabel:UILabel = UILabel.init()
    private let highResolutionSwitch:UISwitch = UISwitch.init()
    
    //MARK: Variables and constants
    
    private let colorSpaceValues:[String] = ["default", "sRGB", "P3_D65", "HLG_BT2020"]
    private var currentColorSpace = "default"
    
    private let flashModeValues:[String] = ["auto", "torch", "flash", "off"]
    private var currentFlashMode = "auto"
    
    private let saveModeValues:[String] = ["files", "photos"]
    private var currentSaveMode = "files"
    
    private let sessionPresetValues:[String] = ["photo",
                                                "low",
                                                "medium",
                                                "vga640x480",
                                                "high",
                                                "inputPriority",
                                                "hd1280x720",
                                                "hd1920x1080",
                                                "hd4K3840x2160",
                                                "iFrame960x540",
                                                "iFrame1280x720",
                                                "cif352x288"]
    private var currentSessionPreset = "photo"
    
    private let deviceTypeValues:[String] = ["tripleCamera",
                                             "dualCamera",
                                             "dualWideCamera",
                                             "ultraWideAngleCamera",
                                             "trueDepthCamera",
                                             "wideAngleCamera",
                                             "telephotoCamera"
    ]
    private var currentDeviceType = "dualWideCamera"
    
    public var currentContinuousFocus = true
    
    public var currentHighResolutionCaptureEnabled = true
    
    private var torchLevel:Float = 1.0
    
    var settingsViewDelegate:SettingsViewDelegate?
    
    //MARK: Getters
    
    func getCurrentColorSpace()->String{
        return currentColorSpace
    }
    func getCurrentFlashMode() -> String {
        return currentFlashMode
    }
    func getCurrentSaveMode() -> String {
        return currentSaveMode
    }
    func getCurrentTorchLevel() -> Float {
        return torchLevel
    }
    func getCurrentSessionPreset() -> String {
        return currentSessionPreset
    }
    func getCurrentDeviceType() -> String {
        print("getCurrentDeviceType",currentDeviceType)
        return currentDeviceType
    }
    func getCurrentCameraPosition() -> String {
        if cameraPositionSwitch.isOn{
            print("getCurrentCameraPosition","back")
            return "back"
        }else{
            print("getCurrentCameraPosition","front")
            return "front"
        }
    }

    //MARK: Setters
    
    func setColorSpace(color_space:String){
        self.currentColorSpace = color_space
        colorSpacePicker.selectRow(colorSpaceValues.firstIndex(of: color_space) ?? 0, inComponent: 0, animated: false)
    }
    
    func setFlashMode(flash_mode:String){
        self.currentFlashMode = flash_mode
        flashmodePicker.selectRow(flashModeValues.firstIndex(of: flash_mode) ?? 0, inComponent: 0, animated: false)
    }
    
    func setTorchLevel(torch_level:Float){
        self.torchLevel = torch_level
        self.torchLevelSlider.value = self.torchLevel
    }
    
    func setSessionPreset(session_preset:String){
        self.currentSessionPreset = session_preset
        sessionPresetPicker.selectRow(sessionPresetValues.firstIndex(of: session_preset) ?? 0, inComponent: 0, animated: false)
    }
    
    func setDeviceType(device_type:String){
        self.currentDeviceType = device_type
        deviceTypePicker.selectRow(deviceTypeValues.firstIndex(of: device_type) ?? 0, inComponent: 0, animated: false)
    }
    
    func setFocusMode(continuous_focus:Bool){
        currentContinuousFocus = continuous_focus
        self.focusModeSwitch.isOn = self.currentContinuousFocus
    }
    
    func setHighResolutionEnabled(enabled:Bool){
        currentHighResolutionCaptureEnabled = enabled
        self.highResolutionSwitch.isOn = self.currentHighResolutionCaptureEnabled
    }
    
    func setSaveMode(save_mode:String){
        self.currentSaveMode = save_mode
        saveModePicker.selectRow(saveModeValues.firstIndex(of: save_mode) ?? 0, inComponent: 0, animated: false)
    }
    
    func setDevicePosition(device_position:String){
        if(device_position == "back"){
            cameraPositionSwitch.isOn = true
            cameraPositionLabel.text = "Camera position: \(getCurrentCameraPosition())"
        }else{
            cameraPositionSwitch.isOn = false
            cameraPositionLabel.text = "Camera position: \(getCurrentCameraPosition())"
        }
    }
    
    func setConfig(config:CameraConfiguration){
        print("settingsView","setConfig")
        setFocusMode(continuous_focus: config.continuousFocus)
        setTorchLevel(torch_level: config.getTorchLevel())
        setColorSpace(color_space: config.getPreferredColorSpaceString())
        setFlashMode(flash_mode: config.getFlashConfiguration() ?? "auto")
        setSessionPreset(session_preset: config.getSessionPresetString())
        setDeviceType(device_type: config.getDeviceTypeStrings()[0])
        setDevicePosition(device_position: config.getCameraPositionString())
        setHighResolutionEnabled(enabled: config.highResolutionCaptureEnabled)
    }
    
    //MARK: UI init
    
    override func didMoveToSuperview() {
        print("settingsView","didMoveToSuperview")
        containerView.alignment = .center
        containerView.distribution = .equalSpacing
        containerView.spacing = 10
        containerView.axis = .vertical
        isUserInteractionEnabled = true
        clipsToBounds = true
        
        flashModeLabel.translatesAutoresizingMaskIntoConstraints = false
        flashmodePicker.translatesAutoresizingMaskIntoConstraints = false
        colorSpaceLabel.translatesAutoresizingMaskIntoConstraints = false
        colorSpacePicker.translatesAutoresizingMaskIntoConstraints = false
        torchLevelLabel.translatesAutoresizingMaskIntoConstraints = false
        torchLevelSlider.translatesAutoresizingMaskIntoConstraints = false
        saveModeLabel.translatesAutoresizingMaskIntoConstraints = false
        saveModePicker.translatesAutoresizingMaskIntoConstraints = false
        sessionPresetLabel.translatesAutoresizingMaskIntoConstraints = false
        sessionPresetPicker.translatesAutoresizingMaskIntoConstraints = false
        focusModeLabel.translatesAutoresizingMaskIntoConstraints = false
        focusModeSwitch.translatesAutoresizingMaskIntoConstraints = false
        deviceTypeLabel.translatesAutoresizingMaskIntoConstraints = false
        deviceTypePicker.translatesAutoresizingMaskIntoConstraints = false
        highResolutionLabel.translatesAutoresizingMaskIntoConstraints = false
        highResolutionSwitch.translatesAutoresizingMaskIntoConstraints = false
        
        //labels
        flashModeLabel.text = "Flash mode:"
        colorSpaceLabel.text = "Color space:"
        saveModeLabel.text = "Save mode:"
        sessionPresetLabel.text = "Session preset:"
        torchLevelLabel.text = "Torch level: \(torchLevel)"
        focusModeLabel.text = "Continuous auto focus:"
        deviceTypeLabel.text = "Device type:"
        cameraPositionLabel.text = "Camera position: \(getCurrentCameraPosition())"
        highResolutionLabel.text = "High resolution capture:"
        
        //torch level slider
        torchLevelSlider.minimumValue = 0.1
        torchLevelSlider.maximumValue = 1.0
        torchLevelSlider.value = torchLevel
        torchLevelSlider.isContinuous = false
        torchLevelSlider.addTarget(self, action: #selector(updateTorchLevel), for: .valueChanged)
        
        //focus mode switch
        focusModeSwitch.isOn = currentContinuousFocus
        focusModeSwitch.addTarget(self, action: #selector(switchToggled), for: .valueChanged)
        
        cameraPositionSwitch.isOn = getCurrentCameraPosition() == "back"
        cameraPositionSwitch.addTarget(self, action: #selector(switchToggled), for: .valueChanged)
        
        highResolutionSwitch.isOn = currentHighResolutionCaptureEnabled
        highResolutionSwitch.addTarget(self, action: #selector(switchToggled), for: .valueChanged)
        
        //pickers
        flashmodePicker.dataSource = self
        colorSpacePicker.dataSource = self
        sessionPresetPicker.dataSource = self
        saveModePicker.dataSource = self
        deviceTypePicker.dataSource = self
        
        setColorSpace(color_space: self.currentColorSpace)
        setFlashMode(flash_mode: self.currentFlashMode)
        setSessionPreset(session_preset: self.currentSessionPreset)
        setSaveMode(save_mode: self.currentSaveMode)
        setDeviceType(device_type: self.currentDeviceType)
        
        flashmodePicker.delegate = self
        colorSpacePicker.delegate = self
        saveModePicker.delegate = self
        sessionPresetPicker.delegate = self
        deviceTypePicker.delegate = self
        
        //add views to container
        containerView.addArrangedSubview(flashModeLabel)
        containerView.addArrangedSubview(flashmodePicker)
        containerView.addArrangedSubview(torchLevelLabel)
        containerView.addArrangedSubview(torchLevelSlider)
        containerView.addArrangedSubview(focusModeLabel)
        containerView.addArrangedSubview(focusModeSwitch)
        containerView.addArrangedSubview(colorSpaceLabel)
        containerView.addArrangedSubview(colorSpacePicker)
        containerView.addArrangedSubview(highResolutionLabel)
        containerView.addArrangedSubview(highResolutionSwitch)
        containerView.addArrangedSubview(saveModeLabel)
        containerView.addArrangedSubview(saveModePicker)
        containerView.addArrangedSubview(sessionPresetLabel)
        containerView.addArrangedSubview(sessionPresetPicker)
        containerView.addArrangedSubview(cameraPositionLabel)
        containerView.addArrangedSubview(cameraPositionSwitch)
        containerView.addArrangedSubview(deviceTypeLabel)
        containerView.addArrangedSubview(deviceTypePicker)
        
        addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        let widthmodifier:CGFloat = -80
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),// constant: 20),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),// constant: -20),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            containerView.widthAnchor.constraint(equalTo: widthAnchor),// constant: -40),
            containerView.heightAnchor.constraint(greaterThanOrEqualTo: heightAnchor),
            torchLevelSlider.widthAnchor.constraint(equalTo: containerView.widthAnchor, constant: widthmodifier),
            flashmodePicker.widthAnchor.constraint(equalTo: containerView.widthAnchor, constant: widthmodifier),
            saveModePicker.widthAnchor.constraint(equalTo: containerView.widthAnchor, constant: widthmodifier),
            colorSpacePicker.widthAnchor.constraint(equalTo: containerView.widthAnchor, constant: widthmodifier),
            sessionPresetPicker.widthAnchor.constraint(equalTo: containerView.widthAnchor, constant: widthmodifier),
            deviceTypePicker.widthAnchor.constraint(equalTo: containerView.widthAnchor, constant: widthmodifier),
        ])
    }
    
    //MARK: Functions
    
    @objc func updateTorchLevel(){
        self.torchLevel = torchLevelSlider.value
        self.settingsViewDelegate?.onTorchLevelChanged(level: self.torchLevel)
        self.torchLevelLabel.text = "Torch level: \(self.torchLevel)"
    }
    
    @objc func switchToggled(ui_switch:UISwitch){
        if(ui_switch == focusModeSwitch){
            self.settingsViewDelegate?.onContinuousFocusChanged(continuous_focus: ui_switch.isOn)
        }else if(ui_switch == cameraPositionSwitch){
            self.cameraPositionLabel.text = "Camera position: \(getCurrentCameraPosition())"
            self.settingsViewDelegate?.onCameraPositionChanged(camera_position: getCurrentCameraPosition())
        }else if(ui_switch == highResolutionSwitch){
            self.settingsViewDelegate?.onHighResolutionEnabled(high_resolution: ui_switch.isOn)
        }
    }
}
