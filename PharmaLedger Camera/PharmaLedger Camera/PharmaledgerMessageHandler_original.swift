//
//  PharmaledgerMessageHandler.swift
//  PSKNodeServer
//  Created by Sergio Mota on 20/07/2021.
//  Based on file:
//  https://github.com/PharmaLedger-IMI/pharmaledger-camera/blob/feature/jscamera/WkCamera/WkCamera/JsMessageHandler.swift
//  JsMessageHandler.swift
//  jscamera
//
//  Created by Yves Delacrétaz on 29.06.21.
//  Updated from code @ 01.102021 https://github.com/PharmaLedger-IMI/pharmaledger-camera/commit/4847c378127f5d0b6d240c5ca36b1df916bc9ed8
//

import Foundation
import WebKit
import AVFoundation
import Accelerate
import GCDWebServers

public enum MessageNames: String, CaseIterable {
    case StartCamera = "StartCamera"
    case StartCameraWithConfig = "StartCameraWithConfig"
    case StopCamera = "StopCamera"
    case TakePicture = "TakePicture"
    case SetFlashMode = "SetFlashMode"
    case SetTorchLevel = "SetTorchLevel"
    case SetPreferredColorSpace = "SetPreferredColorSpace"
}

enum StreamResponseError: Error {
    case cannotCreateCIImage
    case cannotCreateCGImage
    case cannotCreateFrameHeadersData
}

public class PharmaledgerMessageHandler: NSObject, CameraEventListener, WKScriptMessageHandler {
    // const method to run inside the iframe from the leaflet app...
    private var jsWindowPrefix = "";
    
    // MARK: public vars
    public var cameraSession: CameraSession?
    public var cameraConfiguration: CameraConfiguration?
    public var webserverPort: UInt {
        if let webserver = webserver {
            return webserver.port
        } else {
            return 0
        }
    }
    
    // MARK: WKScriptMessageHandler Protocol
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        var args: [String: AnyObject]? = nil
        var jsCallback: String? = nil
        if let messageName = MessageNames(rawValue: message.name) {
            if let bodyDict = message.body as? [String: AnyObject] {
                args = bodyDict["args"] as? [String: AnyObject]
                jsCallback = bodyDict["callback"] as? String
            }
            self.handleMessage(message: messageName, args: args, jsCallback: jsCallback, completion: {result in
                if let result = result {
                    print("result from js: \(result)")
                }
            })
        } else {
            print("Unrecognized message")
        }
    }
    
    // MARK: CameraEventListener Protocol
    public func onCameraPermissionDenied() {
        print("Permission denied")
    }
    
    public func onPreviewFrame(sampleBuffer: CMSampleBuffer) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("Cannot get imageBuffer")
            return
        }
        currentCIImage = CIImage(cvImageBuffer: imageBuffer, options: nil)
    }
    
    public func onCapture(imageData: Data) {
        print("captureCallback")
//        if let image = UIImage.init(data: imageData){
//            print("image acquired \(image.size.width)x\(image.size.height)")
//        }
        if let jsCallback = self.onCaptureJsCallback {
            guard let webview = self.webview else {
                print("WebView was nil")
                return
            }
            let base64 = "data:image/jpeg;base64, " + imageData.base64EncodedString()
            let js = "\(jsWindowPrefix)\(jsCallback)(\"\(base64)\")"
            DispatchQueue.main.async {
                webview.evaluateJavaScript(js, completionHandler: {result, error in
                    guard error == nil else {
                        print(error!)
                        return
                    }
                })
            }
        }
    }
    
    public func onCameraInitialized() {
        print("Camera initialized")
        DispatchQueue.main.async {
            self.callJsAfterCameraStart()
        }
    }
    
    // MARK: privates vars
    private var hasOwnWebserver = false
    private var ypCbCrPixelRange = vImage_YpCbCrPixelRange(Yp_bias: 0,
                                                     CbCr_bias: 128,
                                                     YpRangeMax: 255,
                                                     CbCrRangeMax: 255,
                                                     YpMax: 255,
                                                     YpMin: 0,
                                                     CbCrMax: 255,
                                                     CbCrMin: 0)
    private var argbToYpCbCr: vImage_ARGBToYpCbCr {
        var outInfo = vImage_ARGBToYpCbCr()
        
        vImageConvert_ARGBToYpCbCr_GenerateConversion(kvImage_ARGBToYpCbCrMatrix_ITU_R_709_2,
                                                      &ypCbCrPixelRange,
                                                      &outInfo,
                                                      kvImageARGB8888,
                                                      kvImage420Yp8_CbCr8,
                                                      vImage_Flags(kvImageNoFlags))
        return outInfo
    }
    private var dataBuffer_w = -1
    private var dataBuffer_h = -1
    private var dataBufferRGBA: UnsafeMutableRawPointer? = nil
    private var dataBufferRGB: UnsafeMutableRawPointer? = nil
    private var dataBufferYp: UnsafeMutableRawPointer? = nil
    private var dataBufferCbCr: UnsafeMutableRawPointer? = nil
    private var dataBufferRGBsmall: UnsafeMutableRawPointer? = nil
    private var rawData = Data()
    private var previewData = Data()
    private var currentCIImage: CIImage? = nil
    private var webview: WKWebView? = nil
    private var onGrabFrameJsCallBack: String?
    private let ciContext = CIContext(options: nil)
    private var previewWidth = 640;
    private var previewHeight = -1;
    private var onCameraInitializedJsCallback: String?
    private var onCaptureJsCallback: String?
    var webserver: GCDWebServer?
    let mjpegQueue = DispatchQueue(label: "stream-queue", qos: .userInteractive, attributes: [], autoreleaseFrequency: .workItem, target: nil)
    let rawframeQueue = DispatchQueue(label: "rawframe-queue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem, target: nil)
    let previewframeQueue = DispatchQueue(label: "previewframe-queue", qos: .userInteractive, attributes: [], autoreleaseFrequency: .workItem, target: nil)
    
    
    // MARK: public methods
    
    /// Initialisation
    /// - Parameters:
    ///   - staticPath: internal bundle filepath that will be served as '/'.
    ///   - jsWindowPrefix: string that will be prepended to all callbacks evaluated with evaluateJavascript webview method.
    ///   - webserver: an already available GCDWebServer instance can be re-used. WARNING: if some endpoints are already defined in the instance passed as parameter, they will be replaced.
    public convenience init(staticPath: String? = nil, jsWindowPrefix: String = "", webserver: GCDWebServer? = nil) {
        self.init()
        if let webserver = webserver {
            self.webserver = webserver
        } else {
            self.webserver = GCDWebServer()
            self.hasOwnWebserver = true
        }
        self.jsWindowPrefix = jsWindowPrefix
        addWebserverHandlers(staticPath: staticPath)
        // start server only if not provided from outside
        if webserver == nil {
            startWebserver()
        }
    }
    
    public override init() {
        super.init()
    }
    
    /// To use when you want to initialise with default constructor (for example to get the webview from this instance that implements WKScriptMessageHandler
    /// - Parameters:
    ///   - webserver: an already available GCDWebServer instance. WARNING: if some endpoints are already defined in the instance passed as parameter, they will be replaced.
    ///   - jsWindowPrefix: string that will be prepended to all callbacks evaluated with evaluateJavascript webview method.
    ///   - staticPath: internal bundle filepath that will be served as '/'.
    public func setWebserver(webserver: GCDWebServer, jsWindowPrefix: String = "", staticPath: String? = nil) {
        self.webserver = webserver
        self.jsWindowPrefix = jsWindowPrefix
        addWebserverHandlers(staticPath: staticPath)
    }
    
    deinit {
        if let webview = webview {
            if let cameraSession = self.cameraSession {
                if let captureSession = cameraSession.captureSession {
                    if captureSession.isRunning {
                        cameraSession.stopCamera()
                    }
                }
                self.cameraSession = nil
            }
            for m in MessageNames.allCases {
                webview.configuration.userContentController.removeScriptMessageHandler(forName: m.rawValue)
            }
            self.webview = nil
            if let webserver = webserver {
                if (self.hasOwnWebserver) {
                    webserver.stop()
                    webserver.removeAllHandlers()
                } 
            }
        }
    }
    
    /// Returns a WKWebView with custom messages needed for native camera
    /// - Parameters:
    ///   - frame: the webview frame
    public func getWebview(frame: CGRect) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = WKUserContentController()
        // add all messages defined in MessageNames
        for m in MessageNames.allCases {
            configuration.userContentController.add(self, name: m.rawValue)
        }
        self.webview = WKWebView(frame: frame, configuration: configuration)
        return self.webview!
    }
    
    public func handleMessage(message: MessageNames, args: [String: AnyObject]? = nil, jsCallback: String? = nil, completion: ( (Any?) -> Void )? = nil) {
        guard let webview = self.webview else {
            print("WebView was nil")
            return
        }
        // string used as returned argument that can be passed back to js with the callback
        var jsonString: String = ""
        switch message {
        case .StartCamera:
            if let pWidth = args?["previewWidth"] as? Int {
                self.previewWidth = pWidth
            }
            handleCameraStart(onCameraInitializedJsCallback: args?["onInitializedJsCallback"] as? String,
                              sessionPreset: args?["sessionPreset"] as! String,
                              flash_mode: args?["flashMode"] as? String,
                              auto_orientation_enabled: args?["auto_orientation_enabled"] as? Bool)
            jsonString = ""
        case .StartCameraWithConfig:
            if let pWidth = args?["previewWidth"] as? Int {
                self.previewWidth = pWidth
            }
            if let configDict = args?["config"] as? [String: AnyObject] {
                handleCameraStart(onCameraInitializedJsCallback: args?["onInitializedJsCallback"] as? String, configDict: configDict)
            }
            jsonString = ""
        case .StopCamera:
            stopCameraSession()
            jsonString = ""
        case .TakePicture:
            handleTakePicture(onCaptureJsCallback: args?["onCaptureJsCallback"] as? String)
        case .SetFlashMode:
            handleSetFlashMode(mode: args?["mode"] as? String)
        case .SetTorchLevel:
            if let level = args?["level"] as? NSNumber {
                let levelVal = level.floatValue
                if levelVal > 0.0 {
                    handleSetTorchLevel(level: levelVal)
                } else {
                    print("Torch level must be greater than 0.0")
                }
            } else {
                print("JsMessageHandler: cannot convert argument to NSNumber")
                return
            }
        case .SetPreferredColorSpace:
            if let colorspace = args?["colorspace"] as? String {
                if let cameraConfiguration = self.cameraConfiguration {
                    cameraConfiguration.setPreferredColorSpace(color_space: colorspace)
                    cameraConfiguration.applyConfiguration()
                }
            } else {
                print("JsMessageHandler: cannot convert argument to String")
                return
            }
        }
        if let callback = jsCallback {
            if !callback.isEmpty {
                DispatchQueue.main.async {
                    let js = "\(self.jsWindowPrefix)\(callback)(\(jsonString))"
                    webview.evaluateJavaScript(js, completionHandler: {result, error in
                        guard error == nil else {
                            print(error!)
                            return
                        }
                        if let completion = completion {
                            completion(result)
                        }
                    })
                }
            }
        }
    }
    
    // MARK: private methods
    private func enforceRawBuffer(cgImage: CGImage) {
        if cgImage.width != dataBuffer_w || cgImage.height != dataBuffer_h {
            if dataBufferRGBA != nil {
                free(dataBufferRGBA)
                dataBufferRGBA = nil
            }
            if dataBufferRGB != nil {
                free(dataBufferRGB)
                dataBufferRGB = nil
            }
            if dataBufferYp != nil {
                free(dataBufferYp)
                dataBufferYp = nil
            }
            if dataBufferCbCr != nil {
                free(dataBufferCbCr)
                dataBufferCbCr = nil
            }
        }
        if dataBufferRGBA == nil {
            dataBufferRGBA = malloc(cgImage.bytesPerRow*cgImage.height)
            dataBuffer_w = cgImage.width
            dataBuffer_h = cgImage.height
        }
        if dataBufferRGB == nil {
            dataBufferRGB = malloc(3*cgImage.width*cgImage.height)
        }
        if dataBufferYp == nil {
            dataBufferYp = malloc(cgImage.width*cgImage.height)
        }
        if dataBufferCbCr == nil {
            dataBufferCbCr = malloc(cgImage.width*cgImage.height / 2)
        }
    }
    
    private func buildRgba_vImage(cgImage: CGImage, vimage: inout vImage_Buffer) {
        enforceRawBuffer(cgImage: cgImage)
        let colorspace = CGColorSpaceCreateDeviceRGB()
        let cgContext = CGContext(data: dataBufferRGBA, width: cgImage.width, height: cgImage.height, bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: cgImage.bytesPerRow, space: colorspace, bitmapInfo: cgImage.bitmapInfo.rawValue)
        
        cgContext?.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
        vimage = vImage_Buffer(
            data: dataBufferRGBA!,
            height: vImagePixelCount(cgImage.height),
            width: vImagePixelCount(cgImage.width),
            rowBytes: cgImage.bytesPerRow)
    }
    
    private func prepareRGBData(ciImage: CIImage, roi: CGRect?) -> Data {
        let extent: CGRect = roi ?? ciImage.extent
        guard let cgImage = ciContext.createCGImage(ciImage, from: extent) else {
            return Data()
        }
        var inBuffer: vImage_Buffer = vImage_Buffer()
        buildRgba_vImage(cgImage: cgImage, vimage: &inBuffer)
        var outBuffer = vImage_Buffer(
            data: dataBufferRGB,
            height: vImagePixelCount(cgImage.height),
            width: vImagePixelCount(cgImage.width),
            rowBytes: 3*cgImage.width)
        vImageConvert_RGBA8888toRGB888(&inBuffer, &outBuffer, UInt32(kvImageNoFlags))
        
        let data = Data(bytesNoCopy: dataBufferRGB!, count: 3*cgImage.width*cgImage.height, deallocator: .none)
        return data
    }
    
    private func prepare420Yp8_CbCr8Data(ciImage: CIImage, roi: CGRect?) -> Data {
        let extent: CGRect = roi ?? ciImage.extent
        guard let cgImage = ciContext.createCGImage(ciImage, from: extent) else {
            return Data()
        }
        var inBuffer: vImage_Buffer = vImage_Buffer()
        buildRgba_vImage(cgImage: cgImage, vimage: &inBuffer)
        var ypOut = vImage_Buffer(data: dataBufferYp, height: vImagePixelCount(cgImage.height), width: vImagePixelCount(cgImage.width), rowBytes: cgImage.width)
        var cbCrOut = vImage_Buffer(data: dataBufferCbCr, height: vImagePixelCount(cgImage.height/2), width: vImagePixelCount(cgImage.width/2), rowBytes: cgImage.width)
        _ = withUnsafePointer(to: argbToYpCbCr, {info in
            vImageConvert_ARGB8888To420Yp8_CbCr8(&inBuffer, &ypOut, &cbCrOut, info, [3, 0, 1, 2], vImage_Flags(kvImagePrintDiagnosticsToConsole))
        })
        let dataYp = Data(bytesNoCopy: dataBufferYp!, count: cgImage.width*cgImage.height, deallocator: .none)
        let dataCbCr = Data(bytesNoCopy: dataBufferCbCr!, count: cgImage.width*cgImage.height/2, deallocator: .none)
        var fullData = Data()
        fullData.append(dataYp)
        fullData.append(dataCbCr)
        return fullData
    }
    
    private func preparePreviewData(ciImage: CIImage) -> (Data, Int, Int) {
        let resizeFilter = CIFilter(name: "CILanczosScaleTransform")!
        resizeFilter.setValue(ciImage, forKey: kCIInputImageKey)
        let previewHeight = Int(CGFloat(ciImage.extent.height) / CGFloat(ciImage.extent.width) * CGFloat(self.previewWidth))
        if self.previewHeight != previewHeight {
            self.previewHeight = previewHeight
            if dataBufferRGBsmall != nil {
                free(dataBufferRGBsmall)
                dataBufferRGBsmall = nil
            }
            dataBufferRGBsmall = malloc(3*self.previewHeight*self.previewWidth)
        }
        let scale = CGFloat(previewHeight) / ciImage.extent.height
        let ratio = CGFloat(self.previewWidth) / CGFloat(ciImage.extent.width) / scale
        resizeFilter.setValue(scale, forKey: kCIInputScaleKey)
        resizeFilter.setValue(ratio, forKey: kCIInputAspectRatioKey)
        let ciImageRescaled = resizeFilter.outputImage!
        //
        guard let cgImage = ciContext.createCGImage(ciImageRescaled, from: ciImageRescaled.extent) else {
            return (Data(), -1, -1)
        }
        let colorspace = CGColorSpaceCreateDeviceRGB()
        let bpc = cgImage.bitsPerComponent
        let Bpr = cgImage.bytesPerRow
        let cgContext = CGContext(data: nil, width: cgImage.width, height: cgImage.height, bitsPerComponent: bpc, bytesPerRow: Bpr, space: colorspace, bitmapInfo: cgImage.bitmapInfo.rawValue)

        cgContext?.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
        var inBufferSmall = vImage_Buffer(
            data: cgContext!.data!,
            height: vImagePixelCount(cgImage.height),
            width: vImagePixelCount(cgImage.width),
            rowBytes: Bpr)
        var outBufferSmall = vImage_Buffer(
            data: dataBufferRGBsmall,
            height: vImagePixelCount(cgImage.height),
            width: vImagePixelCount(cgImage.width),
            rowBytes: 3*cgImage.width)
        vImageConvert_RGBA8888toRGB888(&inBufferSmall, &outBufferSmall, UInt32(kvImageNoFlags))
        let data = Data(bytesNoCopy: dataBufferRGBsmall!, count: 3*cgImage.width*cgImage.height, deallocator: .none)
        return (data, self.previewWidth, previewHeight)
    }
    
    
    private func startWebserver() {
        let options: [String: Any] = [
            GCDWebServerOption_Port: findFreePort(),
            GCDWebServerOption_BindToLocalhost: true
        ]
        do {
            if let webserver = webserver {
                try webserver.start(options: options)
                print("*** camera webserver: http://localhost:\(options[GCDWebServerOption_Port]!)")
            }
        } catch {
            print(error)
        }
    }
    
    // MARK: webserver endpoints definitions
    private func addWebserverHandlers(staticPath: String?) {
        if let webserver = webserver {
            if let staticPath = staticPath {
                webserver.addGETHandler(forBasePath: "/", directoryPath: staticPath, indexFilename: nil, cacheAge: 0, allowRangeRequests: false)
            }
            webserver.addHandler(forMethod: "GET", path: "/mjpeg", request: GCDWebServerRequest.classForCoder(), asyncProcessBlock: {(request, completion) in
                let response = GCDWebServerStreamedResponse(contentType: "multipart/x-mixed-replace; boundary=0123456789876543210", asyncStreamBlock: {completion in
                    self.mjpegQueue.async {
                        if let ciImage = self.currentCIImage {
                            if let tempImage = self.ciContext.createCGImage(ciImage, from: ciImage.extent) {
                                let image = UIImage(cgImage: tempImage)
                                let jpegData = image.jpegData(compressionQuality: 0.5)!
                                
                                let frameHeaders = [
                                    "",
                                    "--0123456789876543210",
                                    "Content-Type: image/jpeg",
                                    "Content-Length: \(jpegData.count)",
                                    "",
                                    ""
                                ]
                                if let frameHeadersData = frameHeaders.joined(separator: "\r\n").data(using: String.Encoding.utf8) {
                                    var allData = Data()
                                    allData.append(frameHeadersData)
                                    allData.append(jpegData)
                                    let footersData = ["", ""].joined(separator: "\r\n").data(using: String.Encoding.utf8)!
                                    allData.append(footersData)
                                    completion(allData, nil)
                                } else {
                                    print("Could not make frame headers data")
                                    completion(nil, StreamResponseError.cannotCreateFrameHeadersData)
                                }
                            } else {
                                completion(nil, StreamResponseError.cannotCreateCGImage)
                            }
                        } else {
                            completion(nil, StreamResponseError.cannotCreateCIImage)
                        }
                    }
                })
                response.setValue("keep-alive", forAdditionalHeader: "Connection")
                response.setValue("0", forAdditionalHeader: "Ma-age")
                response.setValue("0", forAdditionalHeader: "Expires")
                response.setValue("no-store,must-revalidate", forAdditionalHeader: "Cache-Control")
                response.setValue("*", forAdditionalHeader: "Access-Control-Allow-Origin")
                response.setValue("accept,content-type", forAdditionalHeader: "Access-Control-Allow-Headers")
                response.setValue("GET", forAdditionalHeader: "Access-Control-Allow-Methods")
                response.setValue("Cache-Control,Content-Encoding", forAdditionalHeader: "Access-Control-expose-headers")
                response.setValue("no-cache", forAdditionalHeader: "Pragma")
                completion(response)
            })
            
            webserver.addHandler(forMethod: "GET", path: "/rawframe", request: GCDWebServerRequest.classForCoder(), asyncProcessBlock: { (request, completion) in
                self.rawframeQueue.async {
                    var roi: CGRect? = nil
                    if let query = request.query {
                        if query.count > 0 {
                            guard let x = query["x"], let y = query["y"], let w = query["w"], let h = query["h"] else {
                                let response = GCDWebServerErrorResponse.init(text: "Must specify exactly 4 params (x, y, w, h) or none.")
                                response?.statusCode = 400
                                completion(response)
                                return
                            }
                            guard let x = Int(x), let y = Int(y), let w = Int(w), let h = Int(h) else {
                                let response = GCDWebServerErrorResponse.init(text: "(x, y, w, h) must be integers.")
                                response?.statusCode = 400
                                completion(response)
                                return
                            }
                            roi = CGRect(x: x, y: y, width: w, height: h)
                        }
                    }
                    if let ciImage = self.currentCIImage {
                        let data = self.prepareRGBData(ciImage: ciImage, roi: roi)
                        let contentType = "application/octet-stream"
                        let response = GCDWebServerDataResponse(data: data, contentType: contentType)
                        response.setValue("*", forAdditionalHeader: "Access-Control-Allow-Origin")
                        let imageSize: CGSize = roi?.size ?? ciImage.extent.size
                        response.setValue(String(Int(imageSize.width)), forAdditionalHeader: "image-width")
                        response.setValue(String(Int(imageSize.height)), forAdditionalHeader: "image-height")
                        response.setValue("image-width,image-height", forAdditionalHeader: "Access-Control-Expose-Headers")
                        completion(response)
                    } else {
                        completion(GCDWebServerErrorResponse.init(statusCode: 500))
                    }
                }
            })
            webserver.addHandler(forMethod: "GET", path: "/rawframe_ycbcr", request: GCDWebServerRequest.classForCoder(), asyncProcessBlock: { (request, completion) in
                self.rawframeQueue.async {
                    var roi: CGRect? = nil
                    if let query = request.query {
                        if query.count > 0 {
                            guard let x = query["x"], let y = query["y"], let w = query["w"], let h = query["h"] else {
                                let response = GCDWebServerErrorResponse.init(text: "Must specify exactly 4 params (x, y, w, h) or none.")
                                response?.statusCode = 400
                                completion(response)
                                return
                            }
                            guard let x = Int(x), let y = Int(y), let w = Int(w), let h = Int(h) else {
                                let response = GCDWebServerErrorResponse.init(text: "(x, y, w, h) must be integers.")
                                response?.statusCode = 400
                                completion(response)
                                return
                            }
                            roi = CGRect(x: x, y: y, width: w, height: h)
                        }
                    }
                    if let ciImage = self.currentCIImage {
                        let data = self.prepare420Yp8_CbCr8Data(ciImage: ciImage, roi: roi)
                        let contentType = "application/octet-stream"
                        let response = GCDWebServerDataResponse(data: data, contentType: contentType)
                        let imageSize: CGSize = roi?.size ?? ciImage.extent.size
                        response.setValue(String(Int(imageSize.width)), forAdditionalHeader: "image-width")
                        response.setValue(String(Int(imageSize.height)), forAdditionalHeader: "image-height")
                        response.setValue("*", forAdditionalHeader: "Access-Control-Allow-Origin")
                        response.setValue("image-width,image-height", forAdditionalHeader: "Access-Control-Expose-Headers")
                        completion(response)
                    } else {
                        completion(GCDWebServerErrorResponse.init(statusCode: 500))
                    }
                }
            })
            
            webserver.addHandler(forMethod: "GET", path: "/previewframe", request: GCDWebServerRequest.self, asyncProcessBlock: {(request, completion) in
                self.previewframeQueue.async {
                    if let ciImage = self.currentCIImage {
                        let (data, w, h) = self.preparePreviewData(ciImage: ciImage)
                        let contentType = "application/octet-stream"
                        let response = GCDWebServerDataResponse(data: data, contentType: contentType)
                        response.setValue("*", forAdditionalHeader: "Access-Control-Allow-Origin")
                        response.setValue(String(w), forAdditionalHeader: "image-width")
                        response.setValue(String(h), forAdditionalHeader: "image-height")
                        response.setValue("image-width,image-height", forAdditionalHeader: "Access-Control-Expose-Headers")
                        completion(response)
                    } else {
                        completion(GCDWebServerErrorResponse(statusCode: 500))
                    }
                }
            })
            
            webserver.addHandler(forMethod: "GET", path: "/snapshot", request: GCDWebServerRequest.classForCoder(), asyncProcessBlock: {(request, completion) in
                DispatchQueue.global().async {
                    let semaphore = DispatchSemaphore(value: 0)
                    let photoSettings = AVCapturePhotoSettings()
                    photoSettings.isHighResolutionPhotoEnabled = true
                    guard let flashMode = self.cameraSession?.getConfig()?.getFlashMode() else {
                        completion(nil)
                        return
                    }
                    photoSettings.flashMode = flashMode
                    var response: GCDWebServerResponse? = nil
                    let processor = CaptureProcessor(completion: {data in
                        let contentType = "image/jpeg"
                        response = GCDWebServerDataResponse(data: data, contentType: contentType)
                        response?.setValue("*", forAdditionalHeader: "Access-Control-Allow-Origin")
                        semaphore.signal()
                    })
                    guard let photoOutput = self.cameraSession?.getPhotoOutput() else {
                        completion(nil)
                        return
                    }
                    photoOutput.capturePhoto(with: photoSettings, delegate: processor)
                    _ = semaphore.wait(timeout: DispatchTime.now().advanced(by: DispatchTimeInterval.seconds(10)))
                    completion(response)
                }
            })
            
            webserver.addHandler(forMethod: "GET", path: "/cameraconfig", request: GCDWebServerRequest.classForCoder(), processBlock: {request in
                var response: GCDWebServerDataResponse!
                let cameraConfigDict: [String: AnyObject] = self.cameraConfiguration?.toDict() ?? [String: AnyObject]()
                response = GCDWebServerDataResponse(jsonObject: cameraConfigDict)
                response.setValue("*", forAdditionalHeader: "Access-Control-Allow-Origin")
                return response
            })
            
            webserver.addHandler(forMethod: "GET", path: "/deviceinfo", request: GCDWebServerRequest.classForCoder(), processBlock: {rerquest in
                let deviceInfoDict = UIDevice.getDeviceInfo()
                if let response = GCDWebServerDataResponse(jsonObject: deviceInfoDict) {
                    response.setValue("*", forAdditionalHeader: "Access-Control-Allow-Origin")
                    return response
                } else {
                    return nil
                }
            })
        }
    }
    
    // MARK: Public functionalities
    public func startCameraSessionWith(configuration: CameraConfiguration) {
        self.cameraConfiguration = configuration
        self.cameraSession = .init(cameraEventListener: self, cameraConfiguration: self.cameraConfiguration!)
    }
    
    private func stopCameraSession() {
        if let cameraSession = self.cameraSession {
            if let captureSession = cameraSession.captureSession {
                if captureSession.isRunning {
                    cameraSession.stopCamera()
                }
            }
        }
        self.cameraConfiguration = nil
        self.cameraSession = nil
        if dataBufferRGBA != nil {
            free(dataBufferRGBA!)
            dataBufferRGBA = nil
        }
        if dataBufferRGB != nil {
            free(dataBufferRGB)
            dataBufferRGB = nil
        }
        if dataBufferYp != nil {
            free(dataBufferYp)
            dataBufferYp = nil
        }
        if dataBufferCbCr != nil {
            free(dataBufferCbCr)
            dataBufferCbCr = nil
        }
        if dataBufferRGBsmall != nil {
            free(dataBufferRGBsmall)
            dataBufferRGBsmall = nil
        }
        self.previewWidth = -1
        self.previewHeight = -1
        dataBuffer_w = -1
        dataBuffer_h = -1
        self.currentCIImage = nil
    }
    
    // MARK: js message handlers implementations
    private func handleCameraStart(onCameraInitializedJsCallback: String?, sessionPreset: String, flash_mode: String?, auto_orientation_enabled: Bool?) {
        self.onCameraInitializedJsCallback = onCameraInitializedJsCallback
        let configuration: CameraConfiguration = .init(flash_mode: flash_mode, color_space: nil, session_preset: sessionPreset, device_types: ["wideAngleCamera"], camera_position: "back", continuous_focus: true, highResolutionCaptureEnabled: true, auto_orientation_enabled: auto_orientation_enabled ?? false)
        startCameraSessionWith(configuration: configuration)
    }
    
    private func handleCameraStart(onCameraInitializedJsCallback: String?, configDict: [String: AnyObject]) {
        self.onCameraInitializedJsCallback = onCameraInitializedJsCallback
        startCameraSessionWith(configuration: CameraConfiguration.createFromConfig(configDict: configDict))
    }
    
   
    
    private func handleTakePicture(onCaptureJsCallback: String?) {
        self.onCaptureJsCallback = onCaptureJsCallback
        self.cameraSession?.takePicture()
    }
    
    private func handleSetFlashMode(mode: String?) {
        guard let mode = mode, let cameraConfiguration = cameraConfiguration else {
            return
        }
        cameraConfiguration.setFlashConfiguration(flash_mode: mode)
        if let cameraSession = self.cameraSession {
            if let captureSession = cameraSession.captureSession {
                if captureSession.isRunning {
                    cameraConfiguration.applyConfiguration()
                }
            }
        }
    }
    
    private func handleSetTorchLevel(level: Float) {
        guard let cameraConfiguration = cameraConfiguration else {
            return
        }
        cameraConfiguration.setTorchLevel(level: level)
        if let cameraSession = self.cameraSession {
            if let captureSession = cameraSession.captureSession {
                if captureSession.isRunning {
                    cameraConfiguration.applyConfiguration()
                }
            }
        }
    }
    
    private func callJsAfterCameraStart() {
        if let jsCallback = self.onCameraInitializedJsCallback {
            guard let webview = self.webview else {
                print("WebView was nil")
                return
            }
            DispatchQueue.main.async {
                webview.evaluateJavaScript("\(self.jsWindowPrefix)\(jsCallback)(\(self.webserverPort))", completionHandler: {result, error in
                    guard error == nil else {
                        print(error!)
                        return
                    }
                })
            }
        }
    }
}

//extension GCDWebServerResponse {
//    func applyCORSHeaders() -> Self {
//        let resp = self
//        resp.setValue("*", forAdditionalHeader: "Access-Control-Allow-Origin")
//        resp.setValue("*", forAdditionalHeader: "Access-Control-Allow-Methods")
//        resp.setValue("*", forAdditionalHeader: "Access-Control-Allow-Headers")
//        resp.setValue("true", forAdditionalHeader: "Access-Control-Allow-Credentials")
//        return self
//    }
//}

