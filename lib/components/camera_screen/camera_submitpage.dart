import 'dart:async';
import 'dart:io';
import 'package:dika_regist/components/camera_screen/video_timer.dart';
import 'package:dika_regist/components/screens/submit_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';

class CameraApp extends StatefulWidget {
  final bool recordingMode;
  CameraApp({Key key, this.recordingMode}) : super(key: key);
  @override
  _CameraAppState createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp>
    with AutomaticKeepAliveClientMixin {
  CameraController _controller;
  List<CameraDescription> _cameras;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isRecordingMode = false;
  bool _isRecording = false;
  final _timerKey = GlobalKey<VideoTimerState>();
  String imagePath, videoPath;

  @override
  void initState() {
    _initCamera();
    super.initState();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future _initCamera() async {
    _cameras = await availableCameras();
    _controller = CameraController(_cameras[1], ResolutionPreset.high);
    _controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  // void _scheduler() {
  //   const seconds = const Duration(seconds: 10);
  //   _timer = Timer.periodic(seconds, (timer) {
  //     if (stopTimer >= 5) {
  //       notif = Notifications(
  //           notifId: 2, notifDesc: "From Scheduler", notifTitle: "Close");
  //       notif.showNotifications();
  //       return timer.cancel();
  //     }
  //     notif = Notifications(
  //         notifId: 1,
  //         notifDesc: "From Scheduler ${stopTimer + 1} times",
  //         notifTitle: "Helo");
  //     notif.showNotifications();

  //     setState(() {
  //       stopTimer++;
  //     });
  //   });
  // }

  String _timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  void _captureImage() async {
    if (_controller.value.isInitialized) {
      final Directory extDir = await getApplicationDocumentsDirectory();
      final String dirPath = '${extDir.path}/media';
      await Directory(dirPath).create(recursive: true);
      final String filePath = '$dirPath/${_timestamp()}.jpeg';
      await _controller.takePicture(filePath);
      setState(() {});
    }
  }

  Future<String> takePicture() async {
    _cameras = await availableCameras();

    if (!_controller.value.isInitialized) {
      return null;
    }
    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/media';
    await Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${_timestamp()}.jpg';

    if (_controller.value.isTakingPicture) {
      return null;
    }

    try {
      await _controller.takePicture(filePath);
      _controller?.dispose();
      setState(() {
        imagePath = filePath;
      });
      Navigator.of(context).pop(filePath);
      // Navigator.pushAndRemoveUntil(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => SubmitPage(
      //       imagePath: imagePath,
      //       videoPath: videoPath,
      //     ),
      //   ),
      //   (_) => false,
      // );
    } on CameraException catch (e) {
      print(e);
      return null;
    }
    return filePath;
  }

  Future<String> startVideoRecording() async {
    print('startVideoRecording');
    if (!_controller.value.isInitialized) {
      return null;
    }
    setState(() {
      _isRecording = true;
    });
    _timerKey.currentState.startTimer();
    //_timerKey.currentState.startTimer();

    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/media';
    await Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${_timestamp()}.mp4';

    if (_controller.value.isRecordingVideo) {
      // A recording is already started, do nothing.
      return null;
    }

    try {
      setState(() {
        videoPath = filePath;
      });
      await _controller.startVideoRecording(filePath);
    } on CameraException catch (e) {
      return null;
    }
    print(filePath);
    return filePath;
  }

  Future<void> stopVideoRecording() async {
    print("Video recording stopped");
    if (!_controller.value.isRecordingVideo) {
      return null;
    }
    _timerKey.currentState.stopTimer();
    setState(() {
      _isRecording = false;
    });

    try {
      await _controller.stopVideoRecording();
      Navigator.of(context).pop(videoPath);
      // Navigator.pushAndRemoveUntil(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => SubmitPage(
      //       videoPath: videoPath,
      //       imagePath: imagePath,
      //     ),
      //   ),
      //   (_) => false,
      // );
    } on CameraException catch (e) {
      print(e);
      return null;
    }
  }

  void onCameraSelected(CameraDescription cameraDescription) async {
    if (_controller != null) await _controller.dispose();
    _controller = CameraController(cameraDescription, ResolutionPreset.medium);

    _controller.addListener(() {
      if (mounted) setState(() {});
      if (_controller.value.hasError) {
        print('Camera Error: ${_controller.value.errorDescription}');
      }
    });

    try {
      await _controller.initialize();
    } on CameraException catch (e) {
      print(e);
    }

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_controller != null) {
      if (!_controller.value.isInitialized) {
        return Container();
      }
    } else {
      return const Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_controller.value.isInitialized) {
      return Container();
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('DIKA Regist'),
        centerTitle: true,
      ),
      body: Stack(
        alignment: FractionalOffset.center,
        children: <Widget>[
          Positioned.fill(
            child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: CameraPreview(_controller)),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: Image.asset(
                'images/selfi_ktp_trans.png',
                fit: BoxFit.fill,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            child: Container(
              color: Colors.white,
              width: MediaQuery.of(context).size.width,
              height: 0.2 * MediaQuery.of(context).size.height,
              alignment: Alignment.center,
              child: ClipOval(
                child: Material(
                  color: Colors.black, // button color
                  child: InkWell(
                    splashColor: Colors.red, // inkwell color
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: Icon(
                        (widget.recordingMode)
                            ? (_isRecording) ? Icons.stop : Icons.videocam
                            : Icons.camera,
                        color: Colors.white,
                      ),
                    ),
                    onTap: () {
                      if (!widget.recordingMode) {
                        takePicture();
                      } else {
                        if (_isRecording) {
                          stopVideoRecording();
                        } else {
                          startVideoRecording();
                        }
                      }
                      print("Button tapped");
                    },
                  ),
                ),
              ),
            ),
          ),
          widget.recordingMode
              ? Positioned(
                  left: 0,
                  right: 0,
                  top: 20.0,
                  child: VideoTimer(
                    key: _timerKey,
                  ),
                )
              : Container(),
        ],
      ),
    );
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}
