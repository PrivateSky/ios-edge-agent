# PharmaLedger Camera SDK
## Table of contents
- [PharmaLedger Camera SDK](#pharmaledger-camera-sdk)
  - [Table of contents](#table-of-contents)
  - [Repository contents](#repository-contents)
  - [Documentation](#documentation)
  - [Sample code](#sample-code)
    - [Capturing and saving a photo](#capturing-and-saving-a-photo)
    - [Controlling the CameraSession](#controlling-the-camerasession)
    - [Lens focus control](#lens-focus-control)
    - [Capture session resolution and session presets](#capture-session-resolution-and-session-presets)
    - [Selecting the capture device](#selecting-the-capture-device)
    - [Handling device orientations](#handling-device-orientations)
  - [Development](#development)
    - [Building Documentation](#building-documentation)
    - [Testing](#testing)
    - [Releasing](#releasing)
  - [WkWebView Interaction](#wkwebview-interaction)

## Repository contents

- Camera Sample (Swift project that implements the Camera Framework)
- WkCamera (Swift project demonstrating how to access camera from Vanilla JS)
- :warning: **Not maintained** pharmaledger_flutterdemo (Flutter application that uses the Camera Framework to access the native camera)
- PharmaLedger Camera (native iOS camera Framework)  
### **Run the script ``./carthage.sh`` before using/building the framework**

## Documentation

- The html Swift documentation is hosted live at [truemedinc.com](https://truemedinc.com/pharmaledger-sdk/documentation/)
- Please see our [Setup guide](https://truemedinc.com/pharmaledger-sdk/documentation/guides/Setup.pdf) on how to add the Framework to your project

## Sample code

This example shows how the [CameraSession](https://truemedinc.com/pharmaledger-sdk/documentation/Classes/CameraSession.html) preview feed would be displayed in a iOS native **UIImageView**. For a more complete example, see the **Camera Sample** project.

First implement the [CameraEventListener](https://truemedinc.com/pharmaledger-sdk/documentation/Protocols/CameraEventListener.html) to receive events from the CameraSession, like preview frames and photo capture callbacks.

    import PharmaLedger_Camera
    import AVFoundation
    import UIKit
    
    class ViewController: UIViewController, CameraEventListener {
        func onPreviewFrame(sampleBuffer: CMSampleBuffer) {
        
        }
        
        func onCapture(imageData: Data) {
        
        }
        
        func onCameraInitialized() {
        
        }
        
        func onCameraPermissionDenied(){
        
        }

When the delegate has been defined, the CameraSession instance can be created.

    private var cameraSession:CameraSession?
    private var cameraPreview:UIImageView?

    /// Use this function for example in your viewDidLoad script
    private func startCameraSession(){
        // 1. Init the CameraSession

        cameraSession = CameraSession.init(cameraEventListener: self)

        // 2a. Create a preview view and add it to 
        // the ViewController

        cameraPreview = UIImageView.init()
        view.addSubview(cameraPreview!)

        // 2b. in this example the preview is scaled
        // using constraints.
        // The Height constraint is based on the camera
        // aspect ratio, in this example 4:3.

        cameraPreview?.translatesAutoresizingMaskIntoConstraints = false
        let cameraAspectRatio:CGFloat = 4.0/3.0      
        let heightAnchorConstant = (view.frame.width)*cameraAspectRatio

        NSLayoutConstraint.activate([
            cameraPreview!.widthAnchor.constraint(equalTo: view.widthAnchor),
            cameraPreview!.topAnchor.constraint(equalTo: view.topAnchor),
            cameraPreview!.heightAnchor.constraint(equalToConstant: heightAnchorConstant)
        ])
    }

To display the camera preview frames in the cameraPreview view, edit the onPreviewFrame(sampleBuffer: CMSampleBuffer) method from CameraEventListener

    //define the CIContext as a constant
    let ciContext:CIContext = CIContext()

    func onPreviewFrame(sampleBuffer: CMSampleBuffer) {
        DispatchQueue.main.async {
            //1. Get UIImage from the sampleBuffer.
            guard let image:UIImage = sampleBuffer.bufferToUIImage(ciContext: ciContext) else {
                return
            }
            //2. update the preview image
            self.cameraPreview?.image = image
        }
    }

### Capturing and saving a photo

To capture a photo, simply call cameraSession?.takePicture(). When the capture is finished, the Data object is returned in the onCapture(imageData: Data) method. Below example shows how to save the file:

    func onCapture(imageData: Data) {
        //below snippet saves a file "test.jpg" into the app files directory
        guard let filedir = imageData.savePhotoToFiles(fileName: "test") else {
            //Something went wrong when saving the file 
            return
        }
    }

### Controlling the CameraSession

The camera can be configured using the [CameraConfiguration](https://truemedinc.com/pharmaledger-sdk/documentation/Classes/CameraConfiguration.html) class. Below is an example of how to configure the camera

    func openCameraWithConfigurations(){
        // option 1a - Initialize a fresh camera
        // configuration with all default values and set
        // the parameters independently
        config:CameraConfiguration = CameraConfiguration.init()
        config.setFlashMode("torch")

        // option 1b - Initialize parameters in the init
        // Any unnecessary parameters can be left out as nil
        config:CameraConfiguration = CameraConfiguration.init(
            flash_mode: "torch", 
            color_space: nil, 
            session_preset: "photo", 
            device_types: nil, 
            camera_position: "back", 
            continuous_focus: true, 
            highResolutionCaptureEnabled: true, 
            auto_orientation_enabled: true
        )

        // Initialize the camera with the configuration
        cameraSession = CameraSession.init(cameraEventListener: self,cameraConfiguration: config)

        // option 2 - Initialize camera without the
        // configurations and get the current configuration from the cameraSession
        cameraSession = CameraSession.init(cameraEventListener: self)
        config = cameraSession.getConfig()
    }

To configure the Camera during session runtime (eg. when toggling the flash mode), call **applyConfiguration**. This will let the current camerasession know that the configurations have updated.

    func setFlashModeOff(){
        config.setFlashConfiguration(flash_mode: "off")
        config.applyConfiguration()
    }

### Lens focus control

The focus mode can be switched between auto and continuous auto focus by setting the **continuousFocus** variable of the **CameraConfiguration** to true or false

To issue a focus request for the CameraSession, simply call **requestFocus** or **requestFocusWIthCallback** to receive completion closure. Focus request callback result is not 100% accurate and behaviour varies between different device types. In general, the callback is more reliable when **continuousFocus** is set to false.

    func requestFocusWithCallback(){
        cameraSession?.requestFocusWithCallback(
            pointOfInterest: nil,
            requestTimeout: 2.0,
            completion: {locked in
                print("locked",locked)
            }
        )
    }

To set a point of interest, pass a CGPoint within range {0.0} to {1,1}. This coordinate system is always relative to a landscape device orientation with the home button on the right, regardless of the actual device orientation. See [focusPointOfInterest documentation](https://developer.apple.com/documentation/avfoundation/avcapturedevice/1385853-focuspointofinterest) for more information.

### Capture session resolution and session presets

Capture session preview resolution is controlled by using [session presets](https://developer.apple.com/documentation/avfoundation/avcapturesession/preset). To change the session preset, call the **setSessionPreset** method from the camera configuration class or predefine the value in the initializer.
The capture size can be changed by setting the highResolutionCaptureEnabled parameter to true or false.

    // Predefining the session preset as "medium" in the initialization
    config:CameraConfiguration = CameraConfiguration.init(flash_mode: nil, 
        color_space: nil, 
        session_preset: "medium", 
        device_types: nil, 
        camera_position: nil, 
        continuous_focus: true, 
        highResolutionCaptureEnabled: true, 
        auto_orientation_enabled: true
    )
    // Using the setSessionPreset method
    config.setSessionPreset("medium")

The aspect ratios for the different settings are as follows:

4:3 parameters:
- "photo"
- "low"
- "medium"
- "vga640x480"

16:9 parameters:
- "high"
- "inputPriority"
- "hd1280x720"
- "hd1920x1080"
- "hd4K3840x2160"
- "iFrame960x540"
- "iFrame1280x720"

11:9 parameters:
- "cif352x288"

### Selecting the capture device

To select which camera the framework chooses, an array of device types can be passed to the configuration using **setDeviceTypes** method (see Apple's documentation on [device types](https://developer.apple.com/documentation/avfoundation/avcapturedevice/devicetype) for more information). The facing of the camera can be chosen using the **setCameraPosition** method.

    func selectPreferredDevice(){
        //select device by priority order: tripleCamera > dualCamera > wideAngleCamera
        config.setDeviceTypes(["tripleCamera","dualCamera","wideAngleCamera"])
        config.setCameraPosition("back")
    }

These parameters can also be defined in configuration init.

### Handling device orientations

By default, the framework detects changes to the device orientation automatically. Orientation can also be managed manually as shown in the example below:

    func initCameraSession(){
        // init the session with auto orientation disabled and fixed to portrait:
        config:CameraConfiguration = CameraConfiguration.init(
            flash_mode: "torch", 
            color_space: nil, 
            session_preset: "photo", 
            device_types: nil, 
            camera_position: "back", 
            continuous_focus: true, 
            highResolutionCaptureEnabled: true, 
            auto_orientation_enabled: false,
            init_orientation: "portrait
        )

        cameraSession = CameraSession.init(cameraEventListener: self, cameraConfiguration: config)
    }

For manually updating the camera orientation during runtime, call the **updateOrientation** or **setOrientation** functions when the view transitions to a new orientation.

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        // Use updateOrientation() to attempt an
        // automatic orientation detection
        cameraSession.updateOrientation()

        // Use below example to set the orientation manually
        cameraSession.setOrientation(orientation: "landscapeRight")
    }

## Development

### Building Documentation

Currently documentation is generated using [Jazzy](https://github.com/realm/jazzy). To generate the documentation, run this command in the PharmaLedger Camera framework root folder (remember to replace VERSION_NUMBER with the version number of the build, eg. 0.3.0):

`jazzy --documentation=../*.md --output docs --copyright "" --author "TrueMed Inc." --author_url https://truemedinc.com --module PharmaLedger_Camera --module-version VERSION_NUMBER --skip-undocumented --hide-documentation-coverage`

Before releasing, you can make sure documentation is up to date by not skipping undocumented code.

### Testing

Quickest way to test the Framework is to boot the sample project **Camera Sample**. Make sure that the Swift framework project is included in the project. This way you can quickly make changes to the source files while testing them in an application project. Make sure you don't have the Framework project open in another window.

### Releasing

To build a release framework, open the **PharmaLedger Camera** project and select the release build scheme (create a new release scheme if there is none available). After this, build the project and find the release build in the project Output.

## WkWebView Interaction

The class `PharmaledgerMessageHandler` is responsible for all interactions between a webview and the native camera framework. It defines custom webkit messages and also uses an embedded webserver to provide GET endpoints to access some native functionalities.  
You can instanciate the message handler so that it creates its own GCDWebServer instance, or you can pass an already available webserver instance. In this case handlers for custom endpoints will be added to the instance, and thus can potentially be replaced in the initial instance.  
To create a new webserver instance, use the below constructor, passing `nil` for `webserver` parameter:  

    public convenience init(staticPath: String? = nil, jsWindowPrefix: String = "", webserver: GCDWebServer? = nil)

And then use instance method `getWebView` to retrieve the webview with custom webkit messages that are mandatory for native camera interaction.

To use an already available webserver either pass the webserver instance to the above constructor, or use the default constructor and method `setWebserver`. This can be useful if you want to pre-load some content in the webview with custom messages before adding the new GET endpoints. The below code snippet shows such a case.

    let messageHandler = PharmaledgerMessageHandler()
    var webView = messageHandler.getWebview(frame: self.view.frame)
    let commonWebserver = GCDWebServer()
    ... do many other stuffs, add handlers to commonWebserver, start it, ...
    messageHandler.setWebserver(webserver: commonWebserver)
    
