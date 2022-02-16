import UIKit
import Flutter
import PharmaLedger_Camera
import AVFoundation

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, CameraEventListener,FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        cameraEventSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        
        return nil
    }
    
    func onPreviewFrame(sampleBuffer: CMSampleBuffer) {
        guard let sampleData:Data = sampleBuffer.bufferToData(ciContext: ciContext, jpegCompression: 0.5)  else {
            return
        }
        let flutterdata = FlutterStandardTypedData(bytes: sampleData)
        cameraEventSink?(flutterdata)
        
    }
    
    func onCapture(imageData: Data) {
        guard let filedir = imageData.savePhotoToFiles(fileName: "test") else {
                //Something went wrong when saving the file
                return
            }
            print("file saved to \(filedir)")

    }
    
    func onCameraInitialized() {
        
    }
    
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    cameraChannel = FlutterMethodChannel(name: "io.truemed.pharmaledgerCameraApp/CameraSDK", binaryMessenger: controller.binaryMessenger)
    
    cameraEventChannel = FlutterEventChannel(name: "io.truemed.pharmaledgerCameraApp/CameraSDKEvents", binaryMessenger: controller.binaryMessenger)
    cameraEventChannel?.setStreamHandler(self)
    
    cameraChannel?.setMethodCallHandler({(call: FlutterMethodCall, result: @escaping FlutterResult)-> Void in
        
        switch call.method{
        case "openCamera":
            self.openCamera()
            result("Opening camera");
            break;
        case "closeCamera":
            self.closeCamera()
            result("Closing camera");
            break;
        case "takePicture":
            self.cameraSession?.takePicture()
            result("Taking picture");
            break;
        default:
            result(FlutterMethodNotImplemented)
            break;
        }
    })
    
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    
    private let ciContext:CIContext = CIContext()
    private var cameraSession:CameraSession?
    private var cameraChannel:FlutterMethodChannel?
    private var cameraEventChannel:FlutterEventChannel?
    private var cameraEventSink:FlutterEventSink?
    
    func openCamera(){
        if(cameraSession == nil){
            cameraSession = CameraSession.init(cameraEventListener: self)
        }else{
            cameraSession?.startCamera()
        }
    }
    
    func closeCamera(){
        cameraSession?.stopCamera()
    }
}
