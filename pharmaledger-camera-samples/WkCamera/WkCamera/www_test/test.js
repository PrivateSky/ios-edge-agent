var sourceIpInput = undefined
var showStreamBtn = undefined
var streamDisplayImg = undefined
var getCameraConfigBtn = undefined
var cameraConfigOutput = undefined

document.addEventListener("DOMContentLoaded", () => {
    sourceIpInput = document.getElementById("src_ip");
    showStreamBtn = document.getElementById("show_stream");
    streamDisplayImg = document.getElementById("stream_display");
    getCameraConfigBtn = document.getElementById("get_camera_config");
    cameraConfigOutput = document.getElementById("camera_config_output");

    sourceIpInput.addEventListener('change', (e) => {
        // hijack _serverUrl
        _serverUrl = sourceIpInput.value;
    });

    showStreamBtn.addEventListener("click", e => {
        let src_stream = `${sourceIpInput.value}/mjpeg`;
        streamDisplayImg.src = src_stream;
    });

    getCameraConfigBtn.addEventListener('click', (e) => {
        getCameraConfiguration().then(data => {
            cameraConfigOutput.innerHTML = JSON.stringify(data);
        })
    });
});