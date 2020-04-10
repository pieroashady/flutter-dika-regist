import 'dart:async';
import 'dart:convert' as convert;
import 'dart:io';

import 'package:flutter/scheduler.dart' as scheduler;
import 'package:dika_regist/utils/utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_video_compress/flutter_video_compress.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login.dart';

class LoginReco extends StatefulWidget {
  LoginReco({Key key}) : super(key: key);

  @override
  _LoginRecoState createState() => _LoginRecoState();
}

class _LoginRecoState extends State<LoginReco> {
  File _videoFile;
  ProgressDialog pr2, pr, pr3;
  var _flutterVideoCompress = FlutterVideoCompress();
  SharedPreferences prefs, prefs2;
  Geolocator geolocator = Geolocator();
  Position userPosition;
  String userLongitude;
  String userLatitude;
  String baseUrl = "http://52.77.8.120/absen.php";
  String notifUrl = "http://52.77.8.120/notif.php";
  int i = 0;
  Timer _timer;
  var responseApi;
  bool stop = false;

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
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
          _pageTitle(),
          _textStatus(),
          _uploadStatus(),
          _submitButton(),
        ],
      ),
    );
  }

  Widget _submitButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _videoFile == null
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
              _getUserLocation();
            },
            child: const Text('Submit Data',
                style: TextStyle(fontSize: 20, color: Colors.white)),
          ),
        )
      ],
    );
  }

  Future _getReco() async {
    String username = 'adminDika';
    String password = 'D1k4@passw0rd';
    String basicAuth = 'Basic ' +
        convert.base64Encode(convert.utf8.encode('$username:$password'));

    Dio dio = Dio();
    dio.options.headers['authorization'] = basicAuth;

    prefs = await SharedPreferences.getInstance();
    String name = prefs.getString('inputName');
    String nip = prefs.getString('inputNip');
    String recoId = prefs.getString('user_id');

    FormData formData =
        FormData.fromMap({"name": name, "nik": nip, "reco_id": recoId});

    dio.post(notifUrl, data: formData).then((value) async {
      if (value.statusCode == 200) {
        if (value.data == "") {
          print("value from dio, ${value.data}");
          setState(() {
            responseApi = "";
          });
          print("No data");
        } else if (value.data != "") {
          print(value.data);
          print("ada data");
          setState(() {
            responseApi = convert.jsonDecode(value.data);
          });
          print(responseApi);
        }
      }
    }).catchError((err) {
      print(err);
      pr.hide();
      setState(() {
        _videoFile = null;
        stop = false;
        i = 0;
      });
      _showAlert(
          alertType: AlertType.error,
          alertTitle: "Gagal",
          alertDesc: "Gagal face matching! ❌ ");
    });
  }

  void _scheduler() {
    const seconds = const Duration(minutes: 1);
    _timer = new Timer.periodic(seconds, (Timer t) {
      pr3 = new ProgressDialog(context,
          type: ProgressDialogType.Normal,
          isDismissible: true,
          showLogs: false);
      pr3.style(message: "Scanning data...");

      if (i >= 5) {
        print("Gagal");
        _showAlert(
            alertType: AlertType.warning,
            alertTitle: 'Warning',
            alertDesc: "Wajah belum di recognition");
        setState(() {
          stop = !stop;
          i = 0;
        });
        pr3.hide();
        return t.cancel();
      }

      setState(() {
        i = i + 1;
      });

      print(i);

      print("Scheduler aktif from timer");
      _getReco();

      try {
        if (responseApi != null) {
          if (responseApi != "") {
            if (responseApi["Status"] == "1") {
              pr3.hide();
              print(responseApi);
              _showAlert(
                  alertTitle: "Success",
                  alertDesc: "Wajah berhasil di recognition",
                  alertType: AlertType.success);
              setState(() {
                stop = !stop;
                i = 0;
              });
              return t.cancel();
            } else if (responseApi["Status"] == "2") {
              pr3.hide();
              print(responseApi);
              _showAlert(
                  alertTitle: "Gagal",
                  alertDesc: "Wajah tidak dikenal",
                  alertType: AlertType.warning);
              setState(() {
                stop = !stop;
                i = 0;
              });
              return t.cancel();
            }
          }
        }
      } catch (e) {
        print(e);
      }
    });
  }

  Future _getUserLocation() {
    pr = new ProgressDialog(context,
        type: ProgressDialogType.Normal, isDismissible: true, showLogs: false);
    pr.style(message: "Submitting Data...");

    return geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) {
      setState(() {
        userPosition = position;
        userLatitude = userPosition.latitude.toString();
        userLongitude = userPosition.longitude.toString();
      });
      pr.show();
      _uploadData();
    }).catchError((e) {
      print(e);
      _showAlert(
          alertType: AlertType.warning,
          alertDesc: "Please turn on GPS permission thanks",
          alertTitle: "Permission");
      setState(() {
        userPosition = null;
      });
    });
  }

  Future _uploadData() async {
    String username = 'adminDika';
    String password = 'D1k4@passw0rd';
    String basicAuth = 'Basic ' +
        convert.base64Encode(convert.utf8.encode('$username:$password'));

    Dio dio = Dio();
    dio.options.headers['authorization'] = basicAuth;

    prefs = await SharedPreferences.getInstance();
    String name = prefs.getString('inputName');
    String nip = prefs.getString('inputNip');

    FormData formData = FormData.fromMap({
      "name": name,
      "nik": nip,
      "longitude": userLongitude,
      "latitude": userLatitude,
      "video_file": await MultipartFile.fromFile(_videoFile.path,
          filename: name.toUpperCase() + ".avi")
    });

    pr = new ProgressDialog(context,
        type: ProgressDialogType.Normal, isDismissible: true, showLogs: false);
    pr.style(message: "Submitting Data...");

    dio.post(baseUrl, data: formData).then((value) async {
      if (value.statusCode == 200) {
        var jsonResponse = convert.jsonDecode(value.data);
        print(jsonResponse['user_id']);
        prefs2 = await SharedPreferences.getInstance();
        prefs2.setString("user_id", jsonResponse['user_id']);
        pr.hide();
        setState(() {
          _videoFile = null;
        });
        _showAlert(
            alertType: AlertType.success,
            alertTitle: "Success",
            alertDesc: "Terimakasih sudah melakukan face reco ✔️");
      }
    }).then((x) {
      pr3 = new ProgressDialog(context,
          type: ProgressDialogType.Normal,
          isDismissible: true,
          showLogs: false);
      pr3.style(message: "Scanning data...");
      pr3.show();
      if (stop == false) {
        print("scheduler aktif");
        _scheduler();
      } else {
        pr3.hide();
        pr3.dismiss();
        return setState(() {
          stop = false;
          i = 0;
        });
      }
    }).catchError((err) {
      print(err);
      pr.hide();
      setState(() {
        stop = false;
        _videoFile = null;
      });
      _showAlert(
          alertType: AlertType.error,
          alertTitle: "Gagal",
          alertDesc: "Gagal face matching, mohon coba lagi! ❌ ");
    });
    _timer.cancel();
  }

  Future _getVideo() {
    return ImagePicker.pickVideo(source: ImageSource.camera)
        .then((video) async {
      pr2 = new ProgressDialog(context,
          type: ProgressDialogType.Normal,
          isDismissible: false,
          showLogs: false);
      pr2.style(message: "Processing video...");
      pr2.show();
      var compressedVideo = await _flutterVideoCompress.compressVideo(
        video.path,
        quality:
            VideoQuality.HighestQuality, // default(VideoQuality.DefaultQuality)
        deleteOrigin: false, // default(false)
      );
      setState(() {
        _videoFile = compressedVideo.file;
      });
      pr2.hide();
    }).catchError((error) {
      _showAlert(
          alertType: AlertType.error,
          alertDesc: "Error",
          alertTitle: "Gagal mengambil video, coba lagi");
    });
  }

  Widget _pageTitle() {
    return Center(
      child: Container(
          margin: EdgeInsets.only(bottom: 40, left: 20, right: 20),
          child: Text(
            "Absen Here",
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          )),
    );
  }

  Widget _uploadStatus() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(20),
        margin: EdgeInsets.only(bottom: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text("Video Status"),
            SizedBox(width: 100),
            _videoFile == null ? Text("❌") : Text("✔️")
          ],
        ),
      ),
    );
  }

  Widget _textStatus() {
    return _videoFile == null
        ? Center(
            child: Container(
                margin: EdgeInsets.only(bottom: 20, left: 20, right: 20),
                child: Text(
                  "Upload video wajah kamu selama 2 detik",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                )),
          )
        : Center(
            child: Container(
                margin: EdgeInsets.only(bottom: 20, left: 20, right: 20),
                child: Text(
                    "Pastikan video sudah sesuai format. Tekan submit data",
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          );
  }

  Future<bool> _showAlert(
      {AlertType alertType, String alertTitle, String alertDesc}) {
    return Alert(
      context: context,
      style: Utils.alertType,
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
      style: Utils.alertType,
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
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => Login()),
                  (_) => false);
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
}
