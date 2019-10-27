import 'package:flutter/material.dart';
import 'package:speech_recognition/speech_recognition.dart';
import 'package:permission/permission.dart';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dialogflow/dialogflow_v2.dart' as d;

List<CameraDescription> cameras;

const languages = const [
  const Language('English', 'en_US'),
];

class Language {
  final String name;
  final String code;

  const Language(this.name, this.code);
}
DatabaseReference _counterRef;
DatabaseReference _messagesRef;
FirebaseApp app;
Future main() async {


  // Fetch the available cameras before initializing the app.
  try {
    WidgetsFlutterBinding.ensureInitialized();
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print(e.description);
  }
  app = await FirebaseApp.configure(
    name: 'vain_android_app',
    options: Platform.isIOS
        ? const FirebaseOptions(
      googleAppID: '1:297855924061:ios:c6de2b69b03a5be8',
      gcmSenderID: '297855924061',
      databaseURL: 'https://flutterfire-cd2f7.firebaseio.com',
    )
        : const FirebaseOptions(
      googleAppID: '1:90982538639:android:df983bf516684ef6127ffa',
      apiKey: 'AIzaSyD5Xaz5vmibDUJ7RAXWCoRiqQd-9V4WzTs',
      databaseURL: 'https://vain-srrgbr.firebaseio.com/',
    ),
  );
  runApp(CameraApp());
}

class CameraApp extends StatefulWidget {
  @override
  _CameraAppState createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> with WidgetsBindingObserver {
  CameraController controller;
  String imagePath;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  bool imageCaptured = false;

  String getPermission = '';
  SpeechRecognition _speech;

  bool _speechRecognitionAvailable = false;
  bool _isListening = false;

  String transcription = '';
  String result = '';

  //String _currentLocale = 'en_US';
  Language selectedLang = languages.first;

  void initState() {
    super.initState();

    // Demonstrates configuring to the database using a file
    _counterRef = FirebaseDatabase.instance.reference().child('vain-srrgbr');

    _counterRef.once().then((a){
      print("Check -> ${a.toString()}",);
    });

    activateSpeechRecognizer();

    // Request microphone/record_audio permissions
//    requestPermission();
    controller = CameraController(cameras[1], ResolutionPreset.medium);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  void activateSpeechRecognizer() {
    print('_MyAppState.activateSpeechRecognizer... ');
    _speech = new SpeechRecognition();
    _speech.setAvailabilityHandler(onSpeechAvailability);
    _speech.setCurrentLocaleHandler(onCurrentLocale);
    _speech.setRecognitionStartedHandler(onRecognitionStarted);
    _speech.setRecognitionResultHandler(onRecognitionResult);
    _speech.setRecognitionCompleteHandler(onRecognitionComplete);
    _speech
        .activate()
        .then((res) => setState(() => _speechRecognitionAvailable = res));
  }

  List<CheckedPopupMenuItem<Language>> get _buildLanguagesWidgets => languages
      .map((l) => new CheckedPopupMenuItem<Language>(
            value: l,
            checked: selectedLang == l,
            child: new Text(l.name),
          ))
      .toList();

  void _selectLangHandler(Language lang) {
    setState(() => selectedLang = lang);
  }

  Widget _buildButton({String label, VoidCallback onPressed}) => new Padding(
      padding: new EdgeInsets.all(12.0),
      child: new RaisedButton(
        color: Colors.cyan.shade600,
        onPressed: onPressed,
        child: new Text(
          label,
          style: const TextStyle(color: Colors.white),
        ),
      ));

  void start() => _speech
      .listen(locale: selectedLang.code)
      .then((result) => print('_MyAppState.start => result ${result}'));

  void cancel() =>
      _speech.cancel().then((result) => setState(() => _isListening = result));

  void stop() {
    _speech.stop().then((result) => setState(() => _isListening = result));
    transcription = '';
  }

  void onSpeechAvailability(bool result) =>
      setState(() => _speechRecognitionAvailable = result);

  void onCurrentLocale(String locale) {
    print('_MyAppState.onCurrentLocale... $locale');
    setState(
        () => selectedLang = languages.firstWhere((l) => l.code == locale));
  }

  void onRecognitionStarted() => setState(() => _isListening = true);

  void onRecognitionResult(String text) {
//     processTextSpeech(text);
     processTextSpeech("Hi");
//    setState(() => transcription = text);
  }

  void onRecognitionComplete() => setState(() => _isListening = false);

  // Setting/Requesting permissions at run time
  requestPermission() async {
    final res =
        await Permission.requestPermissions([PermissionName.Microphone]);
    print(res);
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container();
    }
    return MaterialApp(
      home: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text('Camera example'),
          actions: [

            IconButton(
              icon: Icon(Icons.mic),
              onPressed: () {

                  _speechRecognitionAvailable && !_isListening
                      ? start()
                      : null;

              },
            ),
            IconButton(
              icon: Icon(Icons.message),
              onPressed: () async{await processTextSpeech("Show me a red lipstick");}
            ),
            IconButton(
              icon: Icon(Icons.mic_off),
              onPressed: _isListening ? () => cancel() : null,
            ),
            new PopupMenuButton<Language>(
              onSelected: _selectLangHandler,
              itemBuilder: (BuildContext context) => _buildLanguagesWidgets,
            ),
          ],
        ),
        body: Column(
          children: <Widget>[
            Expanded(
              child: Container(
                child: Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: Center(
                    child: imageCaptured
                        ? _thumbnailWidget()
                        : _cameraPreviewWidget(),
                  ),
                ),
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(
                    color: controller != null ? Colors.redAccent : Colors.grey,
                    width: 3.0,
                  ),
                ),
              ),
            ),
            _captureControlRowWidget(),
          ],
        ),
      ),
    );
  }

  processTextSpeech(text) async{
    d.AuthGoogle authGoogle = await d.AuthGoogle(fileJson: "assets/Vain-5f472a6baa67.json").build();
    d.Dialogflow dialogflow = d.Dialogflow(authGoogle: authGoogle,language: d.Language.ENGLISH);
    d.AIResponse response = await dialogflow.detectIntent(text);
    setState(() {
      result = response.getMessage();
      transcription = text;
    });
    print(result);
  }
  /// Display the preview from the camera (or a message if the preview is not available).
  Widget _cameraPreviewWidget() {
    if (controller == null || !controller.value.isInitialized) {
      return const Text(
        'Tap a camera',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24.0,
          fontWeight: FontWeight.w900,
        ),
      );
    } else {
      return Stack(
        children: <Widget>[
          AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: CameraPreview(controller),
          ),
          Positioned(
              right: 0,
          top: 500,
          bottom: 0,
          left: 50,
          child: Text(result,style: TextStyle(color: Colors.red,fontSize: 25),),
          )
        ],
      );
    }
  }

  /// Display the control bar with buttons to take pictures and record videos.
  Widget _captureControlRowWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        IconButton(
          icon: const Icon(Icons.camera_alt),
          color: Colors.blue,
          onPressed: controller != null && controller.value.isInitialized
              ? onTakePictureButtonPressed
              : null,
        ),
    new Container(
    padding: const EdgeInsets.all(8.0),
    color: Colors.grey.shade200,
    child: new Text(transcription)),
      ],
    );
  }

  /// Display the thumbnail of the captured image or video.
  Widget _thumbnailWidget() {
    return imagePath == null ? Container() : Image.file(File(imagePath));
  }

  void onTakePictureButtonPressed() {
    takePicture().then((String filePath) {
      if (mounted) {
        setState(() {
          imagePath = filePath;
        });
        if (filePath != null) showInSnackBar('Picture saved to $filePath');
      }
    });
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  Future<String> takePicture() async {
    if (!controller.value.isInitialized) {
      showInSnackBar('Error: select a camera first.');
      return null;
    }
    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/Pictures/flutter_test';
    await Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${timestamp()}.jpg';

    if (controller.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }

    try {
      await controller.takePicture(filePath);
      imageCaptured = true;
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
    return filePath;
  }

  void showInSnackBar(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(message)));
  }

  void _showCameraException(CameraException e) {
    showInSnackBar('Error: ${e.code}\n${e.description}');
  }
}
