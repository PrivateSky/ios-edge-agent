
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CameraPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _CameraPageState();

}

const platform = const MethodChannel('io.truemed.pharmaledgerCameraApp/CameraSDK');
const cameraChannel = EventChannel('io.truemed.pharmaledgerCameraApp/CameraSDKEvents');

class _CameraPageState extends State<CameraPage>{
  ui.Image _previewImage;

  @override
  void initState() {
    super.initState();

    cameraChannel.receiveBroadcastStream().listen((event) async { 
      _loadImage(event);
    });
    openCamera();
  }

  @override
  void deactivate() {
    super.deactivate();
    closeCamera();
    print("View deactivated");
  }

  @override
  void dispose(){
    super.dispose();
    print("View was disposed of");
  }

  _loadImage(Uint8List bytes) async {
    if(!mounted){
      print("no longer mounted!");
      _previewImage.dispose();
      return;
    }
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.Image image = (await codec.getNextFrame()).image;
    codec.dispose();
    setState(() {
      _previewImage = image;
    });
  }

  Future<void> openCamera() async {
    try {
      final String result = await platform.invokeMethod("openCamera");
      print("Camera open result: $result");
    }on PlatformException catch (e){
      print("Error launching camera ${e.message}");
    }
  }

  Future<void> closeCamera() async {
    try {
      final String result = await platform.invokeMethod("closeCamera");
      print("Camera closed called succesfully: $result");
    }on PlatformException catch (e){
      print("Error stopping camera ${e.message}");
    }
  }

  Future<void> takePicture() async {
    try {
      final String result = await platform.invokeMethod("takePicture");
    }on PlatformException catch (e){
      print("Error when taking picture ${e.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Camera"),
      ),
      body: Column(
        children: [
        AspectRatio(
          aspectRatio: 3.0/4.0,
            child: CustomPaint(
              painter: MyPainter(_previewImage),
              child: AspectRatio(aspectRatio: 3.0/4.0,),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.camera_alt),
              onPressed: () => takePicture(),
            )
          ],
        )
      ],
      ),
    );
  }

}

class MyPainter extends CustomPainter{
  ui.Image image;
  MyPainter(this.image) : super();

  @override
  void paint(Canvas canvas, Size size) {
      // TODO: implement paint
      canvas.drawImage(image, Offset(0,0), Paint());
    }
  
     @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return image != (oldDelegate as MyPainter).image;
  }

}