import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'dart:math';
import 'package:tflite/tflite.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List _output = [];
  List<CameraDescription>? cameras; //list out the camera available
  CameraController? controller; //controller for camera
  File? image; //for captured image

  bool isInitSuccess = false;
  @override
  void initState() {
    super.initState();
    loadCamera();
    loadModel();
  }

  detectImage(File image) async {
    var output = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 2,
      threshold: 0.6,
      imageMean: 127.5,
      imageStd: 127.5,
    );
    setState(() {
      _output = output!;
    });
  }

  loadModel() async {
    await Tflite.loadModel(
      model: 'assets/vit_trashnet.tflite',
      labels: 'assets/labels_trash.txt',
    );
  }

  void loadCamera() async {
    cameras = await availableCameras();
    if (cameras != null) {
      controller = CameraController(cameras![0], ResolutionPreset.max);
      //cameras[0] = first camera, change to 1 to another camera

      controller!.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {});
      });
    } else {
      print("NO any camera found");
    }
  }

  void captureImage() async {
    try {
      if (controller != null) {
        //check if contrller is not null
        if (controller!.value.isInitialized) {
          //check if controller is initialized
          XFile recordImage = await controller!.takePicture(); //capture image
          print("path of image after take is " + recordImage.path);

          //image = File(recordImage.path); //
          image = await resizeImg(recordImage.path);
          detectImage(image!);
          print("path of image after resize is " + image!.path);
          setState(() {});
          // predictResult();
        }
      }
    } catch (e) {
      print(e); //show error
    }
  }

  Future<File> resizeImg(String path) async {
    print("path parameter : " + path);
    var bytes = await File(path).readAsBytes();
    img.Image? _image = img.decodeImage(bytes);
    //resize the image
    img.Image? newImag = img.copyResize(_image!, width: 224, height: 224);

    //encode image
    final png = img.encodePng(newImag);
    var rng = Random();
    // Write the PNG formatted data to a file.
    return await File(
            '/data/user/0/com.example.flutter_python/cache/${rng.nextInt(100)}.png')
        .writeAsBytes(png);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              //camera preview
              SizedBox(
                height: 300,
                width: 400,
                child: controller == null
                    ? const Center(child: Text("Loading Camera..."))
                    : !controller!.value.isInitialized
                        ? const Center(
                            child: CircularProgressIndicator(),
                          )
                        : CameraPreview(controller!),
              ),
              //capture picture btn
              ElevatedButton.icon(
                //image capture button
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                onPressed: captureImage,
                icon: const Icon(Icons.camera),
                label: const Text("Capture"),
              ),
              const SizedBox(
                height: 20,
              ),
              //test run py script btn

              const SizedBox(
                height: 20,
              ),
              //test run py script btn
              Container(
                //show captured image
                padding: const EdgeInsets.all(30),
                child: image == null
                    ? const Text("No image captured")
                    : Image.file(
                        image!,
                      ),
                //display captured image
              ),
              _output.isNotEmpty ? Text("${_output[0]}") : const Text(""),
              const SizedBox(
                height: 100,
              )
            ],
          ),
        ),
      ),
    );
  }
}
