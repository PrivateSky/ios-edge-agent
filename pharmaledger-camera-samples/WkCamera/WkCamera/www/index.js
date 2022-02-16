var renderer, camera, scene, canvasgl;
var material;
var previewWidth = 360;
var previewHeight = Math.round(previewWidth * 16 / 9); // assume 16:9 portrait at start
var targetPreviewFPS = 25;
var fpsMeasurementInterval = 5;
var previewFramesCounter = 0;
var previewFramesElapsedSum = 0;
var previewFramesMeasuredFPS = 0;
var targetRawFPS = 10;
var rawCrop_x = undefined;
var rawCrop_y = undefined;
var rawCrop_w = undefined;
var rawCrop_h = undefined;
var rawFramesCounter = 0;
var rawFramesElapsedSum = 0;
var rawFramesMeasuredFPS = 0;
var controls;
const bytePerChannel = 3;
// @ts-ignore
if (bytePerChannel === 4) {
    // @ts-ignore
    formatTexture = THREE.RGBAFormat;
} else if (bytePerChannel === 3) {
    // @ts-ignore
    formatTexture = THREE.RGBFormat;
}
var formatTexture;
var flashMode = 'off'
var usingMJPEG = false
var status_test, status_fps_preview, status_fps_raw, title_h2, configInfo;
var startCameraButtonGL, startCameraButtonMJPEG, stopCameraButton;
var takePictureButton1, takePictureButton2, flashButton, getConfigButton, colorspaceButton, continuousAFButton, selectCameraButton;
var afOn = true;
var selectedCamera = "back";
var selectedColorspace = undefined;
var torchRange;
var snapshotImage;
var streamPreview, rawCropCanvas, rawCropCbCanvas, rawCropCrCanvas;
var invertRawFrameCheck, cropRawFrameCheck, ycbcrCheck;
var rawCropRoiInput;
var select_preset;
var selectedPresetName;
var select_cameras;
var selectedDevicesNames;

document.addEventListener("DOMContentLoaded", () => {
    status_test = document.getElementById('status_test');
    status_fps_preview = document.getElementById('status_fps_preview');
    status_fps_raw = document.getElementById('status_fps_raw');

    startCameraButtonGL = document.getElementById('startCameraButtonGL');
    startCameraButtonMJPEG = document.getElementById('startCameraButtonMJPEG');
    stopCameraButton = document.getElementById('stopCameraButton');
    // @ts-ignore
    stopCameraButton.disabled = true

    title_h2 = document.getElementById('title_id');
    takePictureButton1 = document.getElementById('takePictureButton1');
    takePictureButton2 = document.getElementById('takePictureButton2');
    flashButton = document.getElementById('flashButton');
    torchRange = document.getElementById('torchLevelRange');
    torchRange.addEventListener('change', function() {
        let level = parseFloat(torchRange.value);
        if (level != level) {
            alert('failed to parse torch level value');
        } else {
            setTorchLevelNativeCamera(level);
            document.getElementById("torchLevelRangeLabel").innerHTML = `Torch Level: ${torchRange.value}`;
        }
    })
    // @ts-ignore
    torchRange.value = "1.0";
    // @ts-ignore
    document.getElementById("torchLevelRangeLabel").innerHTML = `Torch Level: ${torchRange.value}`;
    snapshotImage = document.getElementById('snapshotImage');
    getConfigButton = document.getElementById("getConfigButton");
    getConfigButton.addEventListener("click", (e) => {
        getCameraConfiguration()
        .then(cameraConfig => {
            getDeviceInfo()
            .then(deviceInfo => {
                configInfo.innerHTML = `cameraConfig: ${JSON.stringify(cameraConfig)}<br/>deviceInfo: ${JSON.stringify(deviceInfo)}`;
            })
        })
    });
    configInfo = document.getElementById("configInfo");
    colorspaceButton = document.getElementById("colorspaceButton");
    colorspaceButton.addEventListener('click', function(e) {
        switch (colorspaceButton.innerHTML) {
            case 'sRGB':
                selectedColorspace = 'HLG_BT2020';
                break;
            case 'HLG_BT2020':
                selectedColorspace = 'P3_D65';
                break;
            default:
                selectedColorspace = 'sRGB';
                break;
        }
        colorspaceButton.innerHTML = selectedColorspace;
        setPreferredColorSpaceNativeCamera(selectedColorspace);
    });
    continuousAFButton = document.getElementById("continuousAFButton");
    continuousAFButton.addEventListener('click', function(e) {
        if (afOn === true) {
            afOn = false;
            continuousAFButton.innerHTML = "AF OFF";
        } else {
            afOn = true;
            continuousAFButton.innerHTML = "AF ON";
        }
    });
    selectCameraButton = document.getElementById("selectCameraButton");
    selectCameraButton.addEventListener('click', function(e) {
        if (selectedCamera === "back") {
            selectedCamera = "front";
            selectCameraButton.innerHTML = "Front Cam";
        } else {
            selectedCamera = "back";
            selectCameraButton.innerHTML = "Back Cam";
        }
    });

    canvasgl = document.getElementById('cameraCanvas');
    streamPreview = document.getElementById('streamPreview');
    rawCropCanvas = document.getElementById('rawCropCanvas');
    rawCropCbCanvas = document.getElementById('rawCropCbCanvas');
    rawCropCrCanvas = document.getElementById('rawCropCrCanvas');
    invertRawFrameCheck = document.getElementById('invertRawFrameCheck');
    cropRawFrameCheck = document.getElementById('cropRawFrameCheck');
    ycbcrCheck = document.getElementById('ycbcrCheck');
    rawCropRoiInput = document.getElementById('rawCropRoiInput');
    rawCropRoiInput.addEventListener('change', function() {
        setCropCoords();
    })
    cropRawFrameCheck.addEventListener('change', function() {
        // @ts-ignore
        if (this.checked) {
            show(rawCropRoiInput);        
        } else {
            hide(rawCropRoiInput);
        }
    });
    hide(rawCropRoiInput);
    hide(rawCropCanvas);
    hide(rawCropCbCanvas);
    hide(rawCropCrCanvas);


    select_preset = document.getElementById('select_preset');
    let i = 0
    for (let presetName of sessionPresetNames) {
        var p_i = new Option(presetName, presetName)
        // @ts-ignore
        select_preset.options.add(p_i);
        i++;
    }
    // @ts-ignore
    for (let i = 0; i < select_preset.options.length; i++) {
        // @ts-ignore
        if (select_preset.options[i].value === 'hd1920x1080') {
            // @ts-ignore
            select_preset.selectedIndex = i;
            break;
        }
    }
    // @ts-ignore
    selectedPresetName = select_preset.options[select_preset.selectedIndex].value;
    status_test.innerHTML = selectedPresetName;

    select_cameras = document.getElementById('select_cameras');
    // hardcoded cameras list
    for (let deviceTypeName of deviceTypeNames) {
        // @ts-ignore
        select_cameras.options.add(new Option(deviceTypeName, deviceTypeName));
    }
    // @ts-ignore
    select_cameras.selectedIndex = 0;
    selectedDevicesNames = [ deviceTypeNames[0] ]


    startCameraButtonGL.addEventListener('click', function(e) {
        usingMJPEG = false
        select_preset.disabled = true;
        startCameraButtonGL.disabled = true
        startCameraButtonMJPEG.disabled = true
        stopCameraButton.disabled = false
        ycbcrCheck.disabled = true
        continuousAFButton.disabled = true
        selectCameraButton.disabled = true
        select_cameras.disabled = true
        setCropCoords();
        show(canvasgl);
        canvasgl.parentElement.style.display = "block";
        hide(streamPreview);
        streamPreview.parentElement.style.display = "none";
        show(status_fps_preview);
        show(status_fps_raw);
        setupGLView(previewWidth, previewHeight);
        const config = new PLCameraConfig(selectedPresetName, flashMode, afOn, false, selectedDevicesNames, selectedCamera, true, selectedColorspace, parseFloat(torchRange.value), 4.0/3.0, "portrait");   
        startNativeCameraWithConfig( 
            config, 
            onFramePreview, 
            targetPreviewFPS, 
            previewWidth, 
            onFrameGrabbed, 
            targetRawFPS, 
            () => {
                title_h2.innerHTML = _serverUrl;
            },
            rawCrop_x,
            rawCrop_y,
            rawCrop_w,
            rawCrop_h,
            ycbcrCheck.checked);
    })
    startCameraButtonMJPEG.addEventListener('click', function(e) {
        usingMJPEG = true
        select_preset.disabled = true;
        startCameraButtonGL.disabled = true
        startCameraButtonMJPEG.disabled = true
        stopCameraButton.disabled = false
        ycbcrCheck.disabled = true
        continuousAFButton.disabled = true
        selectCameraButton.disabled = true
        select_cameras.disabled = true
        setCropCoords();
        hide(canvasgl);
        canvasgl.parentElement.style.display = "none";
        show(streamPreview);
        streamPreview.parentElement.style.display = "block";
        hide(status_fps_preview);
        show(status_fps_raw);
        const config = new PLCameraConfig(selectedPresetName, flashMode, afOn, false, selectedDevicesNames, selectedCamera, true, selectedColorspace, parseFloat(torchRange.value), 4.0/3.0, "portrait");   
        startNativeCameraWithConfig( 
            config, 
            undefined, 
            targetPreviewFPS, 
            previewWidth, 
            onFrameGrabbed, 
            targetRawFPS, 
            () => {
                streamPreview.src = `${_serverUrl}/mjpeg`;
                title_h2.innerHTML = _serverUrl;
            },
            rawCrop_x,
            rawCrop_y,
            rawCrop_w,
            rawCrop_h,
            ycbcrCheck.checked);
    });
    stopCameraButton.addEventListener('click', function(e) {
        window.close(); 
        stopNativeCamera();
        select_preset.disabled = false;
        startCameraButtonGL.disabled = false
        startCameraButtonMJPEG.disabled = false
        stopCameraButton.disabled = true
        ycbcrCheck.disabled = false
        continuousAFButton.disabled = false
        selectCameraButton.disabled = false
        select_cameras.disabled = false
        title_h2.innerHTML = "Camera Test"
    });

    takePictureButton1.addEventListener('click', function(e) {
        takePictureBase64NativeCamera(onPictureTaken)
    });
    takePictureButton2.addEventListener('click', function(e) {
        getSnapshot().then( b => {
            snapshotImage.src = URL.createObjectURL(b);
        });
    });

    flashButton.addEventListener('click', function(e) {
        switch (flashMode) {
            case 'off':
                flashMode = 'flash';
                break;
            case 'flash':
                flashMode = 'torch';
                break;
            case 'torch':
                flashMode = 'off';
                break;
            default:
                break;
        }
        flashButton.innerHTML = `T ${flashMode}`;
        setFlashModeNativeCamera(flashMode);
    });

    hide(canvasgl);
    hide(streamPreview);
    hide(status_fps_preview)
    hide(status_fps_raw)
});

function ChangeDesiredCamerasList() {
    selectedDevicesNames = [];
    for (let i = 0; i < select_cameras.options.length; i++) {
       if (select_cameras.options[i].selected) {
           selectedDevicesNames.push(select_cameras.options[i].value);
       }
   }
}

function setupGLView(w, h) {
    // @ts-ignore
    scene = new THREE.Scene();
    // @ts-ignore
    camera = new THREE.PerspectiveCamera(75, w/h, 0.1, 10000);
    // @ts-ignore
    renderer = new THREE.WebGLRenderer({ canvas: canvasgl, antialias: true });

    let cameraHeight = h/2/Math.tan(camera.fov/2*(Math.PI/180))
    camera.position.set(0,0,cameraHeight);
    let clientHeight = Math.round(h/w * canvasgl.clientWidth);    
    renderer.setSize(canvasgl.clientWidth, clientHeight);

    // @ts-ignore
    controls = new THREE.OrbitControls(camera, renderer.domElement);
    controls.enablePan = false;
    controls.enableZoom = false;
    controls.enableRotate = false;

    const dataTexture = new Uint8Array(w*h*bytePerChannel);
    for (let i=0; i<w*h*bytePerChannel; i++)
        dataTexture[i] = 255;
    // @ts-ignore
    const frameTexture = new THREE.DataTexture(dataTexture, w, h, formatTexture, THREE.UnsignedByteType);
    frameTexture.needsUpdate = true;
    // @ts-ignore
    const planeGeo = new THREE.PlaneBufferGeometry(w, h);
    // @ts-ignore
    material = new THREE.MeshBasicMaterial({
        map: frameTexture,
    });
    material.map.flipY = true;
    // @ts-ignore
    const plane = new THREE.Mesh(planeGeo, material);
    scene.add(plane);

    animate();
}

function animate() {
    window.requestAnimationFrame(() => animate());
    renderer.render(scene, camera);
}

function ChangePresetList() {
    selectedPresetName = select_preset.options[select_preset.selectedIndex].value;
    status_test.innerHTML = selectedPresetName;
}

function setCropCoords() {
    if (cropRawFrameCheck.checked) {
        const coords = rawCropRoiInput.value.split(",");
        rawCrop_x = parseInt(coords[0]);
        rawCrop_y = parseInt(coords[1]);
        rawCrop_w = parseInt(coords[2]);
        rawCrop_h = parseInt(coords[3]);
        if (rawCrop_x != rawCrop_x || rawCrop_y != rawCrop_y || rawCrop_w != rawCrop_w || rawCrop_h != rawCrop_h) {
            alert("failed to parse coords");
            cropRawFrameCheck.checked = false;
            hide(rawCropRoiInput);
            rawCrop_x = undefined;
            rawCrop_y = undefined;
            rawCrop_w = undefined;
            rawCrop_h = undefined;
        }
    } else {
        rawCrop_x = undefined;
        rawCrop_y = undefined;
        rawCrop_w = undefined;
        rawCrop_h = undefined;
    }
    setRawCropRoi(rawCrop_x, rawCrop_y, rawCrop_w, rawCrop_h);
}


/**
 * @param {PLRgbImage} rgbImage preview data coming from native camera
 * @param {number} elapsedTime time in ms elapsed to get the preview frame
 */
function onFramePreview(rgbImage, elapsedTime) {
    var frame = new Uint8Array(rgbImage.arrayBuffer);
    if (rgbImage.width !== previewWidth || rgbImage.height !== previewHeight) {
        previewWidth = rgbImage.width;
        previewHeight = rgbImage.height;
        setupGLView(previewWidth, previewHeight);
    }
    // @ts-ignore
    material.map = new THREE.DataTexture(frame, rgbImage.width, rgbImage.height, formatTexture, THREE.UnsignedByteType);
    material.map.flipY = true;
    material.needsUpdate = true;

    if (previewFramesCounter !== 0 && previewFramesCounter%(fpsMeasurementInterval-1) === 0) {
        previewFramesMeasuredFPS = 1000/previewFramesElapsedSum * fpsMeasurementInterval;
        previewFramesCounter = 0;
        previewFramesElapsedSum = 0;
    } else {
        previewFramesCounter += 1;
        previewFramesElapsedSum += elapsedTime;
    }
    status_fps_preview.innerHTML = `preview ${Math.round(elapsedTime)} ms (max FPS=${Math.round(previewFramesMeasuredFPS)})`;
}

/**
 * @param {PLRgbImage | PLYCbCrImage} plImage raw data coming from native camera
 * @param {number} elapsedTime time in ms elapsed to get the raw frame
 */
function onFrameGrabbed(plImage, elapsedTime) {
    let pSizeText = "";
    if (usingMJPEG === false) {
        pSizeText = `, p(${previewWidth}x${previewHeight}), p FPS:${targetPreviewFPS}`
    } 
    
    let rawframeLengthMB = undefined
    if (plImage instanceof PLRgbImage) {
        rawframeLengthMB = Math.round(10*plImage.arrayBuffer.byteLength/1024/1024)/10;
        placeUint8RGBArrayInCanvas(rawCropCanvas, new Uint8Array(plImage.arrayBuffer), plImage.width, plImage.height);
        show(rawCropCanvas);
        hide(rawCropCbCanvas);
        hide(rawCropCrCanvas);
    } else if (plImage instanceof PLYCbCrImage) {
        rawframeLengthMB = Math.round(10*(plImage.yArrayBuffer.byteLength + plImage.cbCrArrayBuffer.byteLength)/1024/1024)/10;
        placeUint8GrayScaleArrayInCanvas(rawCropCanvas, new Uint8Array(plImage.yArrayBuffer), plImage.width, plImage.height);
        show(rawCropCanvas);
        placeUint8CbCrArrayInCanvas(rawCropCbCanvas, rawCropCrCanvas, new Uint8Array(plImage.cbCrArrayBuffer), plImage.width/2, plImage.height/2);
        show(rawCropCbCanvas);
        show(rawCropCrCanvas);
    } else {
        rawframeLengthMB = -1
    }
    
    status_test.innerHTML = `${selectedPresetName}${pSizeText}, raw FPS:${targetRawFPS}<br/> raw frame length: ${rawframeLengthMB}MB, ${plImage.width}x${plImage.height}`

    if (rawFramesCounter !== 0 && rawFramesCounter%(fpsMeasurementInterval-1) === 0) {
        rawFramesMeasuredFPS = 1000/rawFramesElapsedSum * fpsMeasurementInterval;
        rawFramesCounter = 0;
        rawFramesElapsedSum = 0;
    } else {
        rawFramesCounter += 1;
        rawFramesElapsedSum += elapsedTime;
    }
    status_fps_raw.innerHTML = `raw ${Math.round(elapsedTime)} ms (max FPS=${Math.round(rawFramesMeasuredFPS)})`
}

function onPictureTaken(base64ImageData) {
    console.log(`Inside onPictureTaken`)
    snapshotImage.src = base64ImageData
}

function hide(element) {
    element.style.display = "none";
}

function show(element) {
    element.style.display = "block";
}

function placeUint8RGBArrayInCanvas(canvasElem, array, w, h) {
    let a = 1;
    let b = 0;
    if (invertRawFrameCheck.checked === true){
        a = -1;
        b = 255;
    }
    canvasElem.width = w;
    canvasElem.height = h;
    var ctx = canvasElem.getContext('2d');
    var clampedArray = new Uint8ClampedArray(w*h*4);
    let j = 0
    for (let i = 0; i < 3*w*h; i+=3) {
        clampedArray[j] = b+a*array[i];
        clampedArray[j+1] = b+a*array[i+1];
        clampedArray[j+2] = b+a*array[i+2];
        clampedArray[j+3] = 255;
        j += 4;
    }
    var imageData = new ImageData(clampedArray, w, h);
    ctx.putImageData(imageData, 0, 0);
}

function placeUint8GrayScaleArrayInCanvas(canvasElem, array, w, h) {
    let a = 1;
    let b = 0;
    if (invertRawFrameCheck.checked === true){
        a = -1;
        b = 255;
    }
    canvasElem.width = w;
    canvasElem.height = h;
    var ctx = canvasElem.getContext('2d');
    var clampedArray = new Uint8ClampedArray(w*h*4);
    let j = 0
    for (let i = 0; i < w*h; i++) {
        clampedArray[j] = b+a*array[i];
        clampedArray[j+1] = b+a*array[i];
        clampedArray[j+2] = b+a*array[i];
        clampedArray[j+3] = 255;
        j += 4;
    }
    var imageData = new ImageData(clampedArray, w, h);
    ctx.putImageData(imageData, 0, 0);
}

function placeUint8CbCrArrayInCanvas(canvasElemCb, canvasElemCr, array, w, h) {
    canvasElemCb.width = w;
    canvasElemCb.height = h;
    canvasElemCr.width = w;
    canvasElemCr.height = h;
    var ctxCb = canvasElemCb.getContext('2d');
    var ctxCr = canvasElemCr.getContext('2d');
    var clampedArrayCb = new Uint8ClampedArray(w*h*4);
    var clampedArrayCr = new Uint8ClampedArray(w*h*4);
    let j = 0
    for (let i = 0; i < 2*w*h; i+=2) {
        clampedArrayCb[j] = array[i];
        clampedArrayCb[j+1] = array[i];
        clampedArrayCb[j+2] = array[i];
        clampedArrayCb[j+3] = 255;
        clampedArrayCr[j] = array[i+1];
        clampedArrayCr[j+1] = array[i+1];
        clampedArrayCr[j+2] = array[i+1];
        clampedArrayCr[j+3] = 255;
        j += 4;
    }
    var imageDataCb = new ImageData(clampedArrayCb, w, h);
    ctxCb.putImageData(imageDataCb, 0, 0);
    var imageDataCr = new ImageData(clampedArrayCr, w, h);
    ctxCr.putImageData(imageDataCr, 0, 0);
}
