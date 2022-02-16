//
//  ViewController.swift
//  Camera Sample
//
//  Created by Ville Raitio on 7.6.2021.
//

import UIKit
import PharmaLedger_Camera
import AVFoundation

class ViewController: UIViewController,SettingsViewDelegate {
    func onHighResolutionEnabled(high_resolution: Bool) {
        cameraConfig.highResolutionCaptureEnabled = high_resolution
    }
    
    func onDeviceTypeChanged(device_type: String) {
        cameraConfig.setDeviceTypes(deviceTypes: [device_type])
    }
    
    func onCameraPositionChanged(camera_position: String) {
        cameraConfig.setCameraPosition(position: camera_position)
    }
    
    func onContinuousFocusChanged(continuous_focus: Bool) {
        cameraConfig.continuousFocus = continuous_focus
    }
    
    func onSessionPresetChanged(session_preset: String) {
        cameraConfig.setSessionPreset(preset: session_preset)
    }
    
    func onTorchLevelChanged(level: Float) {
        cameraConfig.setTorchLevel(level: level)
    }
    
    func onColorSpaceChanged(color_space: String) {
        cameraConfig.setPreferredColorSpace(color_space: color_space)
    }
    
    func onFlashModeChanged(flash_mode: String) {
        cameraConfig.setFlashConfiguration(flash_mode: flash_mode)
    }
    
    func onSaveModeChanged(save_mode: String) {
        self.saveMode = save_mode
    }
    
    //private let uiContainer:UIStackView = UIStackView.init()
    
    private let openCameraViewButton:UIButton = UIButton.init()
    
    private var cameraViewController:CameraViewController?
    private var cameraConfig:CameraConfiguration = CameraConfiguration.init()
    
    private let settingsView:SettingsView = SettingsView.init()
    
    private var saveMode:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        settingsView.settingsViewDelegate = self
    
        settingsView.translatesAutoresizingMaskIntoConstraints = false
        openCameraViewButton.translatesAutoresizingMaskIntoConstraints = false
        
        //open camera button
        openCameraViewButton.setTitle("Open camera", for: .normal)
        openCameraViewButton.addTarget(self, action: #selector(openCamera), for: .touchUpInside)
        openCameraViewButton.setTitleColor(UIColor.systemBlue, for: .normal)
        
        initConfigParameters()
        cameraConfig.setCameraPosition(position: "back")
        settingsView.setDevicePosition(device_position: "back")
        
        view.addSubview(settingsView)
        view.addSubview(openCameraViewButton)
        
        //add constraints
        NSLayoutConstraint.activate([
            openCameraViewButton.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            openCameraViewButton.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            openCameraViewButton.heightAnchor.constraint(equalToConstant: 100),
            openCameraViewButton.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor),
            settingsView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            settingsView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            settingsView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            settingsView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor, constant: -100),
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if(cameraViewController != nil){
            cameraViewController = nil
            cameraConfig = CameraConfiguration.init()
            initConfigParameters()
            print("camera view controller removed")
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @objc func openCamera(){
        print("open camera...")
        
        cameraViewController = CameraViewController.init(cameraConfig: cameraConfig)
        
        cameraViewController?.modalPresentationStyle = .fullScreen
        cameraViewController?.setSaveMode(save_mode: self.saveMode ?? "files")
        //self.navigationController?.pushViewController(cameraViewController!, animated: true)
        
        print("camera should open now")
        show(cameraViewController!, sender: self)
    }
    
    private func initConfigParameters(){
        cameraConfig.setTorchLevel(level: settingsView.getCurrentTorchLevel())
        cameraConfig.setPreferredColorSpace(color_space: settingsView.getCurrentColorSpace())
        cameraConfig.setCameraPosition(position: settingsView.getCurrentCameraPosition())
        cameraConfig.setDeviceTypes(deviceTypes: [settingsView.getCurrentDeviceType()])
        cameraConfig.setFlashConfiguration(flash_mode: settingsView.getCurrentFlashMode())
        cameraConfig.setSessionPreset(preset: settingsView.getCurrentSessionPreset())
        cameraConfig.continuousFocus = settingsView.currentContinuousFocus
        saveMode = settingsView.getCurrentSaveMode()
    }
}
