import 'dart:convert';
import 'dart:io';

import 'package:dika_regist/components/file_status.dart';
import 'package:dika_regist/components/login.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_video_compress/flutter_video_compress.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubmitPage extends StatefulWidget {
  SubmitPage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _SubmitPageState createState() => _SubmitPageState();
}

class _SubmitPageState extends State<SubmitPage> {
  var data;
  File _imageFile;
  File _videoFile;
  String _videoPath;
  ProgressDialog pr;
  var _flutterVideoCompress = FlutterVideoCompress();
  SharedPreferences prefs;
  String baseUrl = "http://52.77.8.120/upload.php";

  var alertStyle = AlertStyle(
    animationType: AnimationType.fromTop,
    isCloseButton: false,
    isOverlayTapDismiss: false,
    descStyle: TextStyle(fontWeight: FontWeight.bold),
    animationDuration: Duration(milliseconds: 400),
    alertBorder: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(0.0),
      side: BorderSide(
        color: Colors.grey,
      ),
    ),
    titleStyle: TextStyle(
      color: Colors.red,
    ),
  );

  @override
  void initState() {
    super.initState();
  }

  Future<bool> _showAlert(
      {AlertType alertType, String alertTitle, String alertDesc}) {
    return Alert(
      context: context,
      style: alertStyle,
      type: alertType,
      title: alertTitle,
      desc: alertDesc,
      buttons: [
        DialogButton(
          child: Text(
            "Sip",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          onPressed: () => Navigator.pop(context),
          color: Color.fromRGBO(0, 179, 134, 1.0),
          radius: BorderRadius.circular(0.0),
        ),
      ],
    ).show();
  }

  Future<bool> _confirmLogout() {
    return Alert(
      context: context,
      style: alertStyle,
      type: AlertType.warning,
      title: "Logout",
      desc: "Logout akan menghapus data login anda. Yakin logout?",
      buttons: [
        DialogButton(
          child: Text(
            "Ya",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          onPressed: () async {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            prefs.clear().then((data) {
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => Login()));
            });
          },
          color: Colors.red,
          radius: BorderRadius.circular(0.0),
        ),
        DialogButton(
          child: Text(
            "Tidak",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          onPressed: () => Navigator.pop(context),
          color: Colors.blue,
          radius: BorderRadius.circular(0.0),
        ),
      ],
    ).show();
  }

  Future _getImage() {
    return ImagePicker.pickImage(source: ImageSource.camera, imageQuality: 70)
        .then((image) {
      setState(() {
        _imageFile = image;
        print(_imageFile.toString());
      });
    }).catchError((error) => debugPrint(error));
  }

  Future _getVideo() {
    return ImagePicker.pickVideo(source: ImageSource.camera)
        .then((video) async {
      var compressedVideo = await _flutterVideoCompress.compressVideo(
        video.path,
        quality:
            VideoQuality.HighestQuality, // default(VideoQuality.DefaultQuality)
        deleteOrigin: false, // default(false)
      );
      debugPrint(compressedVideo.toJson().toString());
      setState(() {
        _videoFile = compressedVideo.file;
        _videoPath = compressedVideo.path;
      });
      print(_videoFile);
    }).catchError((error) {
      print(error);
    });
  }

  Future _uploadData() async {
    String username = 'adminDika';
    String password = 'D1k4@passw0rd';
    String basicAuth =
        'Basic ' + base64Encode(utf8.encode('$username:$password'));

    Dio dio = Dio();
    dio.options.headers['authorization'] = basicAuth;

    var fileName = new DateTime.now().millisecondsSinceEpoch.toString();

    prefs = await SharedPreferences.getInstance();
    String name = prefs.getString('inputName');
    String nip = prefs.getString('inputNip');

    if (name == null && nip == null) {
      return print("Null data");
    }

    FormData formData = FormData.fromMap({
      "name": name,
      "nik": nip,
      "ktp_image": await MultipartFile.fromFile(_imageFile.path,
          filename: "ktp" + fileName + ".jpg"),
      "video_file": await MultipartFile.fromFile(_videoFile.path,
          filename: "video" + fileName + ".mp4")
    });

    pr = new ProgressDialog(context,
        type: ProgressDialogType.Normal, isDismissible: true, showLogs: false);
    pr.style(message: "Submitting Data...");

    print("Submitting....");
    dio.post(baseUrl, data: formData).then((value) {
      value.statusCode == 200 ? print("Success") : print(value.statusCode);
      pr.hide();
      print("Done");
      setState(() {
        _imageFile = null;
        _videoFile = null;
      });
      _showAlert(
          alertType: AlertType.success,
          alertTitle: "Success",
          alertDesc: "Terimakasih sudah absen! ✔️");
    }).catchError((err) {
      print(err);
      pr.hide();
      print("Done");
      setState(() {
        _imageFile = null;
        _videoFile = null;
      });
      _showAlert(
          alertType: AlertType.error,
          alertTitle: "Gagal",
          alertDesc: "Gagal absen, mohon coba lagi! ❌ ");
    });
  }

  Widget _uploadStatus() {
    return Container(
      padding: EdgeInsets.all(20),
      child: FileStatus(
        imgFile: _imageFile,
        videoFile: _videoFile,
      ),
    );
  }

  Widget _textStatus() {
    return _videoFile == null || _imageFile == null
        ? Container(
            margin: EdgeInsets.only(bottom: 20),
            child:
                Text("Upload foto selfie kamu dan video kamu selama 2 detik"))
        : Container(
            margin: EdgeInsets.only(bottom: 20), child: Text("All is set up"));
  }

  Widget _buttonHelper() {
    return Row(
      children: <Widget>[
        Container(
          height: 50,
          margin: EdgeInsets.only(right: 20),
          child: RaisedButton(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0)),
            color: Colors.redAccent,
            onPressed: () {
              _getVideo();
            },
            child: const Text('Upload Video',
                style: TextStyle(fontSize: 20, color: Colors.white)),
          ),
        ),
        Container(
          height: 50,
          child: RaisedButton(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0)),
            color: Colors.redAccent,
            onPressed: () {
              pr.show();
              _uploadData();
            },
            child: const Text('Submit Data',
                style: TextStyle(fontSize: 20, color: Colors.white)),
          ),
        )
      ],
    );
  }

  Widget _submitButton() {
    pr = new ProgressDialog(context,
        type: ProgressDialogType.Normal, isDismissible: true, showLogs: false);
    pr.style(message: "Submitting Data...");

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _videoFile == null || _imageFile == null
            ? Container(
                height: 50,
                child: RaisedButton(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0)),
                  color: Colors.redAccent,
                  onPressed: _getVideo,
                  child: const Text('Upload Video',
                      style: TextStyle(fontSize: 20, color: Colors.white)),
                ),
              )
            : _buttonHelper()
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          centerTitle: true,
          actions: <Widget>[
            PopupMenuButton(onSelected: (value) {
              switch (value) {
                case 1:
                  print("value from switch case");
                  _confirmLogout();
                  break;
                default:
              }
            }, itemBuilder: (BuildContext context) {
              return [PopupMenuItem(value: 1, child: Text("Logout"))];
            })
          ],
          title: Text(
            'DIKA Regist',
            style: GoogleFonts.raleway(
                fontWeight: FontWeight.normal, letterSpacing: 1.5),
          )),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          _uploadStatus(),
          _textStatus(),
          _submitButton(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _getImage();
        },
        tooltip: 'Open camera',
        child: Icon(Icons.camera),
      ),
    );
  }
}
