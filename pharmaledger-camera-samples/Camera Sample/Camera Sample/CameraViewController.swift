// 
//  CameraViewController.swift
//  Camera Sample
//
//  Created by Ville Raitio on 23.6.2021.
//  
//
	

import UIKit
import PharmaLedger_Camera
import AVFoundation

class CameraViewController: UIViewController, CameraEventListener, SettingsViewDelegate {
    func onHighResolutionEnabled(high_resolution: Bool) {
        cameraConfig?.highResolutionCaptureEnabled = high_resolution
    }
    
    func onDeviceTypeChanged(device_type: String) {
        cameraConfig?.setDeviceTypes(deviceTypes: [device_type])
        cameraConfig?.applyConfiguration()
    }
    
    func onCameraPositionChanged(camera_position: String) {
        cameraConfig?.setCameraPosition(position: camera_position)
        cameraConfig?.applyConfiguration()
    }
    
    func onContinuousFocusChanged(continuous_focus: Bool) {
        cameraConfig?.continuousFocus = continuous_focus
        cameraConfig?.applyConfiguration()
    }
    
    func onSessionPresetChanged(session_preset: String) {
        cameraConfig?.setSessionPreset(preset: session_preset)
        cameraConfig?.applyConfiguration()
        readjustAspectRatio()
        setViewConstraints(orientation: UIDevice.current.orientation)
    }
    
    //MARK: SettingsViewDelegate
    func onTorchLevelChanged(level: Float) {
        cameraConfig?.setTorchLevel(level: level)
        cameraConfig?.applyConfiguration()
    }
    
    func onColorSpaceChanged(color_space: String) {
        cameraConfig?.setPreferredColorSpace(color_space: color_space)
        cameraConfig?.applyConfiguration()
    }
    
    func onFlashModeChanged(flash_mode: String) {
        cameraConfig?.setFlashConfiguration(flash_mode: flash_mode)
        setFlashButtonImage(flash_mode: cameraConfig?.getFlashConfiguration() ?? "auto")
        cameraConfig?.applyConfiguration()
    }
    
    func onSaveModeChanged(save_mode: String) {
        self.saveMode = save_mode
        print("save mode changed to \(save_mode)!")
    }
    
    
    //MARK: CameraEventListener
    func onCapture(imageData: Data) {
        print("captureCallback")
        if let image = UIImage.init(data: imageData){
            print("sessionPresets","capture size for preset \(cameraConfig?.getSessionPresetString() ?? "photo"): \(image.size)")
        }
        if(saveMode == "files"){
            guard (imageData.savePhotoToFiles(fileName: "test") != nil) else {
                //Something went wrong when saving the file
                return
            }
        }else{
            imageData.savePhotoToLibrary()
        }
        cameraImagePreview?.showToast(message: "file saved", font: .systemFont(ofSize: 14.0))
    }
    
    func onPreviewFrame(sampleBuffer: CMSampleBuffer) {
        guard let image:UIImage = sampleBuffer.bufferToUIImage(ciContext: ciContext) else {
            return
        }
        if(lastPreviewSize != image.size){
            lastPreviewSize = image.size
            print("sessionPresets","Image size for preset \(cameraConfig?.getSessionPresetString() ?? "photo"): \(image.size), scale: \(image.scale)")
        }
        DispatchQueue.main.async {
            self.cameraImagePreview?.image = image
        }
    }

    func onCameraInitialized() {
        print("camConfig","Current colorspace: \(cameraSession?.getCurrentColorSpaceString() ?? "nil")")
        let deviceInfo = UIDevice.getDeviceInfo()
        print("deviceInfo","\(deviceInfo)")
    }
    
    func onCameraPermissionDenied() {
        print("camera permission was denied!")
    }
    
    private let useImage:Bool = false
    private var cameraImagePreview:UIImageView?
    private var cameraSession:CameraSession?
    private var cameraConfig:CameraConfiguration?
    private let ciContext = CIContext()
    
    private let controlsContainer:UIStackView = UIStackView.init()
    private let captureButton:UIButton = UIButton.init()
    private let flashModeButton:UIButton = UIButton.init()
    private let cameraToggleButton:UIButton = UIButton.init()
    private let infoButton:UIButton = UIButton.init()
    private let settingsButton:UIButton = UIButton.init()
    private let closeButton:UIButton = UIButton.init()
    private let settingsView:SettingsView = SettingsView.init()
    
    private var cameraAspectRatio:CGFloat = 4.0/3.0
    private var cameraViewHeight:CGFloat?
    private var cameraViewWidth:CGFloat?
    private var controlsHeight:CGFloat?
    public var saveMode:String = "files"
    private var lastPreviewSize:CGSize?
    
    private let infoview:UILabel = UILabel.init()
    
    var camerapreview_widthconstraint:NSLayoutConstraint?
    var camerapreview_heightconstraint:NSLayoutConstraint?
    var camerapreview_topconstraint:NSLayoutConstraint?
    var camerapreview_leftconstraint:NSLayoutConstraint?
    
    var controlscontainer_widthconstraint:NSLayoutConstraint?
    var controlscontainer_heightconstraint:NSLayoutConstraint?
    var controlscontainer_bottomconstraint:NSLayoutConstraint?
    var controlscontainer_leftconstraint:NSLayoutConstraint?
    var controlscontainer_rightconstraint:NSLayoutConstraint?
    
    init(cameraConfig:CameraConfiguration){
        self.cameraConfig = cameraConfig
        self.settingsView.setConfig(config: cameraConfig)
        super.init(nibName: nil, bundle: nil)
        print("camera view initialized")
    }
    
    public func setSaveMode(save_mode:String){
        self.saveMode = save_mode
        self.settingsView.setSaveMode(save_mode: self.saveMode)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Setup the UI
        
        self.view.backgroundColor = UIColor.systemBackground
        startCameraSession()
        
        readjustAspectRatio()
        controlsContainer.alignment = .center
        controlsContainer.distribution = .fillEqually
        controlsContainer.translatesAutoresizingMaskIntoConstraints = false
        controlsContainer.backgroundColor = UIColor.systemBackground
        
        view.addSubview(controlsContainer)
        
        captureButton.setImage(UIImage.init(named: "photo_camera"), for: .normal)
        captureButton.addTarget(self, action: #selector(captureButtonClick), for: .touchUpInside)
        
        cameraToggleButton.setImage(UIImage.init(named: "pause"), for: .normal)
        cameraToggleButton.addTarget(self, action: #selector(toggleCamera), for: .touchUpInside)
        
        setFlashButtonImage(flash_mode: cameraConfig?.getFlashConfiguration() ?? "auto")
        flashModeButton.addTarget(self, action: #selector(toggleFlash), for: .touchUpInside)
        
        cameraToggleButton.translatesAutoresizingMaskIntoConstraints = false
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        flashModeButton.translatesAutoresizingMaskIntoConstraints = false
        
        infoButton.setImage(UIImage.init(named: "info"), for: .normal)
        infoButton.translatesAutoresizingMaskIntoConstraints = false
        infoButton.addTarget(self, action: #selector(toggleInfoView), for: .touchUpInside)
        
        settingsButton.setImage(UIImage.init(named: "settings"), for: .normal)
        settingsButton.addTarget(self, action: #selector(toggleSettingsView), for: .touchUpInside)
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        
        closeButton.setImage(UIImage.init(named: "close"), for: .normal)
        closeButton.addTarget(self, action: #selector(closeViewController), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        settingsView.settingsViewDelegate = self
        settingsView.translatesAutoresizingMaskIntoConstraints = false
        settingsView.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.5)
        settingsView.isHidden = true
        
        infoview.translatesAutoresizingMaskIntoConstraints = false
        infoview.isHidden = true
        infoview.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.5)
        infoview.textColor = UIColor.white
        infoview.textAlignment = .center
        infoview.numberOfLines = 0
        
        cameraImagePreview?.backgroundColor = .gray
        cameraImagePreview?.addSubview(infoButton)
        cameraImagePreview?.addSubview(settingsButton)
        cameraImagePreview?.addSubview(closeButton)
        cameraImagePreview?.addSubview(infoview)
        cameraImagePreview?.addSubview(settingsView)
        cameraImagePreview?.isUserInteractionEnabled = true
        
        let cameraTapGesture = UITapGestureRecognizer(target: self, action: #selector(requestFocusWithPOI))
        cameraImagePreview?.addGestureRecognizer(cameraTapGesture)
        
        let ui_spacing:CGFloat = 5
        let button_width:CGFloat = 50
        
        NSLayoutConstraint.activate([
            infoButton.leadingAnchor.constraint(equalTo: cameraImagePreview!.layoutMarginsGuide.leadingAnchor, constant: 0),
            infoButton.topAnchor.constraint(equalTo: cameraImagePreview!.layoutMarginsGuide.topAnchor),
            infoButton.widthAnchor.constraint(equalToConstant: button_width),
            infoButton.heightAnchor.constraint(equalToConstant: button_width),
            infoview.leadingAnchor.constraint(equalTo: cameraImagePreview!.leadingAnchor, constant: 40),
            infoview.trailingAnchor.constraint(equalTo: cameraImagePreview!.trailingAnchor, constant: -40),
            infoview.topAnchor.constraint(equalTo: cameraImagePreview!.topAnchor, constant: 40),
            infoview.bottomAnchor.constraint(equalTo: cameraImagePreview!.bottomAnchor, constant: -40),
            settingsButton.leadingAnchor.constraint(equalTo: cameraImagePreview!.layoutMarginsGuide.leadingAnchor, constant: 0),
            settingsButton.topAnchor.constraint(equalTo: cameraImagePreview!.layoutMarginsGuide.topAnchor, constant: ui_spacing+button_width),
            settingsButton.widthAnchor.constraint(equalToConstant: button_width),
            settingsButton.heightAnchor.constraint(equalToConstant: button_width),
            settingsView.leadingAnchor.constraint(equalTo: cameraImagePreview!.leadingAnchor, constant: 40),
            settingsView.trailingAnchor.constraint(equalTo: cameraImagePreview!.trailingAnchor, constant: -40),
            settingsView.topAnchor.constraint(equalTo: cameraImagePreview!.topAnchor, constant: 40),
            settingsView.bottomAnchor.constraint(equalTo: cameraImagePreview!.bottomAnchor, constant: -40),
            closeButton.trailingAnchor.constraint(equalTo: cameraImagePreview!.layoutMarginsGuide.trailingAnchor, constant: -0),
            closeButton.topAnchor.constraint(equalTo: cameraImagePreview!.layoutMarginsGuide.topAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: button_width),
            closeButton.heightAnchor.constraint(equalToConstant: button_width),
        ])
        
        controlsContainer.addArrangedSubview(flashModeButton)
        controlsContainer.addArrangedSubview(captureButton)
        controlsContainer.addArrangedSubview(cameraToggleButton)
        
        
        setViewConstraints(orientation: UIDevice.current.orientation)
        print("camera view loaded")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("cameraView","viewWillAppear")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("cameraView","viewDidAppear")
    }
    
    private func startCameraSession(){
        cameraImagePreview = UIImageView.init()
        cameraImagePreview?.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cameraImagePreview!)
        if(cameraConfig == nil){
            cameraSession = CameraSession.init(cameraEventListener: self)
            cameraConfig = cameraSession?.getConfig()
        }else{
            cameraSession = CameraSession.init(cameraEventListener: self,cameraConfiguration: cameraConfig!)
        }
        
        
    }
    
    func readjustAspectRatio(){
        if(camerapreview_widthconstraint != nil){
            NSLayoutConstraint.deactivate([
                camerapreview_widthconstraint!,
                camerapreview_heightconstraint!,
                camerapreview_leftconstraint!,
                camerapreview_topconstraint!,
                controlscontainer_widthconstraint!,
                controlscontainer_heightconstraint!,
                controlscontainer_leftconstraint!,
                controlscontainer_rightconstraint!,
                controlscontainer_bottomconstraint!]
            )
        }
        cameraAspectRatio = cameraConfig?.getAspectRatio() ?? 4.0/3.0
        if(view.frame.width<view.frame.height){
            cameraViewHeight = (view.frame.width)*cameraAspectRatio
            cameraViewWidth = (view.frame.width)
            controlsHeight = (view.frame.height)-cameraViewHeight!
            controlsContainer.axis = .horizontal
        }else{
            cameraViewHeight = (view.frame.height)*cameraAspectRatio
            cameraViewWidth = (view.frame.height)
            controlsHeight = (view.frame.width)-cameraViewHeight!
            controlsContainer.axis = .vertical
        }
        
        camerapreview_widthconstraint = NSLayoutConstraint(item: cameraImagePreview!, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 1, constant: 0)
        camerapreview_heightconstraint = NSLayoutConstraint(item: cameraImagePreview!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: cameraViewHeight!)
        camerapreview_topconstraint = NSLayoutConstraint(item: cameraImagePreview!, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0)
        camerapreview_leftconstraint = NSLayoutConstraint(item: cameraImagePreview!, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1, constant: 0)
        
        controlscontainer_widthconstraint = NSLayoutConstraint(item: controlsContainer, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 1, constant: 0)
        controlscontainer_heightconstraint = NSLayoutConstraint(item: controlsContainer, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: controlsHeight!)
        controlscontainer_bottomconstraint = NSLayoutConstraint(item: controlsContainer, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
        controlscontainer_leftconstraint = NSLayoutConstraint(item: controlsContainer, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1, constant: 0)
        controlscontainer_rightconstraint = NSLayoutConstraint(item: controlsContainer, attribute: .right, relatedBy: .greaterThanOrEqual, toItem: view, attribute: .right, multiplier: 1, constant: 0)
    }
    
    @objc func captureButtonClick(){
        print("capture button clicked!")
        cameraSession?.takePicture()
    }
    
    @objc func toggleCamera(){
        
        
        guard let capturesession = cameraSession?.captureSession else {
            return
        }
        if(capturesession.isRunning){
            cameraToggleButton.setImage(UIImage.init(named: "play"), for: .normal)
            cameraSession?.stopCamera()
        }else{
            cameraToggleButton.setImage(UIImage.init(named: "pause"), for: .normal)
            cameraSession?.startCamera()
        }
        
        
    }
    
    @objc func requestFocusWithPOI(touch:UITapGestureRecognizer){
        let rawLocation = touch.location(in: self.cameraImagePreview)
        
        var x_corrected:CGFloat = rawLocation.x
        var y_corrected:CGFloat = rawLocation.y
        
        var width_corrected:CGFloat = self.cameraImagePreview!.frame.width
        var height_corrected:CGFloat = self.cameraImagePreview!.frame.height
        
        if(UIDevice.current.orientation == .portrait || UIDevice.current.orientation == .portraitUpsideDown){
            width_corrected = self.cameraImagePreview!.frame.height
            height_corrected = self.cameraImagePreview!.frame.width
            
            x_corrected = rawLocation.y
            y_corrected = height_corrected - rawLocation.x
            
        }
        
        let pointOfInterest:CGPoint = CGPoint.init(x: x_corrected/width_corrected, y: y_corrected/height_corrected)
        
        print("requestFocusWithPOI","touched at \(rawLocation)")
        print("requestFocusWithPOI","requesting focus at point \(pointOfInterest)")
        
        cameraSession?.requestFocusWithCallback(pointOfInterest: pointOfInterest, requestTimeout: 2.0, completion: {locked in
            print("requestFocusWithPOI","focus request has finished as locked:\(locked)")
            self.cameraImagePreview?.showToast(message: "focus locked: \(locked)", font: .systemFont(ofSize: 14.0))
        })
    }
    
    @objc func toggleSettingsView(){
        infoview.isHidden = true
        settingsView.isHidden = !settingsView.isHidden
    }
    
    @objc func toggleInfoView(){
        updateInfoText()
        settingsView.isHidden = true
        infoview.isHidden = !infoview.isHidden
    }
    
    @objc func closeViewController(){
        if(!infoview.isHidden || !settingsView.isHidden){
            infoview.isHidden = true
            settingsView.isHidden = true
            return
        }
        
        dismiss(animated: true, completion: {
            self.cameraSession?.stopCamera()
            self.cameraConfig = nil
            self.cameraSession = nil
            print("cleared camera!")
        })
    }
    
    func updateInfoText(){
        //get info
        let sdk_version = Bundle(for: CameraSession.self).infoDictionary?["CFBundleShortVersionString"]
        
        var infotext = ""
        let configDict:[String: AnyObject] = cameraConfig!.toDict()
        
        for key in configDict.keys {
            let stringvalue = String(describing: configDict[key])// as? String ?? ""
            infotext.append("\(key):\(stringvalue)\n")
            print("configDict-\(key)",configDict[key] ?? "not set")
        }
        
        infotext.append("\n\nSDK version: \(sdk_version ?? "")")
        /*var infotext = "Current color space: \(cameraSession?.getCurrentColorSpaceString() ?? "")\n"
        infotext.append("Flash mode: \(cameraConfig?.getFlashConfiguration() ?? "")\n")
        infotext.append("Torch level: \(cameraConfig?.getTorchLevel() ?? 1.0)\n")
        */
        //display info
        infoview.text = infotext
    }
    
    @objc func toggleFlash(){
        switch cameraConfig!.getFlashConfiguration() {
        case "off":
            cameraConfig!.setFlashConfiguration(flash_mode: "auto")
            break
        case "auto":
            cameraConfig!.setFlashConfiguration(flash_mode: "flash")
            break
        case "flash":
            cameraConfig!.setFlashConfiguration(flash_mode: "torch")
            break
        default://torch
            cameraConfig!.setFlashConfiguration(flash_mode: "off")
            break
        }
        setFlashButtonImage(flash_mode: cameraConfig?.getFlashConfiguration() ?? "auto")
        settingsView.setFlashMode(flash_mode: cameraConfig?.getFlashConfiguration() ?? "auto")
        cameraConfig!.applyConfiguration()
        updateInfoText()
    }
    
    private func setFlashButtonImage(flash_mode:String){
        switch flash_mode {
        case "flash":
            flashModeButton.setImage(UIImage.init(named: "flash_on"), for: .normal)
        case "off":
            flashModeButton.setImage(UIImage.init(named: "flash_off"), for: .normal)
        case "torch":
            flashModeButton.setImage(UIImage.init(named: "flash_torch"), for: .normal)
        default:
            flashModeButton.setImage(UIImage.init(named: "flash_auto"), for: .normal)
        }
    }

    //MARK:Device orientation
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        NSLayoutConstraint.deactivate([
            camerapreview_widthconstraint!,
            camerapreview_heightconstraint!,
            camerapreview_leftconstraint!,
            camerapreview_topconstraint!,
            controlscontainer_widthconstraint!,
            controlscontainer_heightconstraint!,
            controlscontainer_leftconstraint!,
            controlscontainer_rightconstraint!,
            controlscontainer_bottomconstraint!]
        )
        
        setViewConstraints(orientation: UIDevice.current.orientation)
        //cameraSession?.updateOrientation()
        
    }
    
    
    /// Configures the layout constraints based on the device orientation
    /// - Parameter orientation: UIDeviceOrientation.
    private func setViewConstraints(orientation:UIDeviceOrientation){
        switch UIDevice.current.orientation{
        case .landscapeLeft, .landscapeRight:
            print("landscape")
            camerapreview_widthconstraint = NSLayoutConstraint(item: cameraImagePreview!, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: cameraViewHeight!)
            camerapreview_heightconstraint = NSLayoutConstraint(item: cameraImagePreview!, attribute: .height, relatedBy: .equal, toItem: view, attribute: .height, multiplier: 1, constant: 0)
            
            controlscontainer_leftconstraint = NSLayoutConstraint(item: controlsContainer, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1, constant: cameraViewHeight!)
            controlscontainer_widthconstraint = NSLayoutConstraint(item: controlsContainer, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: controlsHeight!)
            controlscontainer_heightconstraint = NSLayoutConstraint(item: controlsContainer, attribute: .height, relatedBy: .equal, toItem: view, attribute: .height, multiplier: 1, constant: 0)
            controlsContainer.axis = .vertical
        default:
            print("portrait")
            camerapreview_widthconstraint = NSLayoutConstraint(item: cameraImagePreview!, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 1, constant: 0)
            camerapreview_heightconstraint = NSLayoutConstraint(item: cameraImagePreview!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: cameraViewHeight!)
            
            
            controlscontainer_leftconstraint = NSLayoutConstraint(item: controlsContainer, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0)
            controlscontainer_heightconstraint = NSLayoutConstraint(item: controlsContainer, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: controlsHeight!)
            controlscontainer_widthconstraint = NSLayoutConstraint(item: controlsContainer, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 1, constant: 0)
            controlsContainer.axis = .horizontal
        }
        NSLayoutConstraint.activate([
            camerapreview_widthconstraint!,
            camerapreview_heightconstraint!,
            camerapreview_leftconstraint!,
            camerapreview_topconstraint!,
            controlscontainer_widthconstraint!,
            controlscontainer_heightconstraint!,
            controlscontainer_leftconstraint!,
            controlscontainer_rightconstraint!,
            controlscontainer_bottomconstraint!
        ])
    }
 
    private func orientationString(orientation:UIInterfaceOrientationMask) -> String {
        var orientationText=""
        switch orientation{
        case .portrait:
            orientationText="Portrait"
        case .portraitUpsideDown:
            orientationText="PortraitUpsideDown"
        case .landscapeLeft:
            orientationText="LandscapeLeft"
        case .landscapeRight:
            orientationText="LandscapeRight"
        default:
            orientationText="Another"
        }
        return orientationText
    }
    
}

extension UIView {
    
func showToast(message : String, font: UIFont) {

    let toastLabel = UILabel(frame: self.frame)
    toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
    toastLabel.textColor = UIColor.white
    toastLabel.font = font
    toastLabel.textAlignment = .center;
    toastLabel.text = message
    toastLabel.alpha = 1.0
    toastLabel.layer.cornerRadius = 10;
    toastLabel.clipsToBounds  =  true
    self.addSubview(toastLabel)
    UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
         toastLabel.alpha = 0.0
    }, completion: {(isCompleted) in
        toastLabel.removeFromSuperview()
    })
} }
