import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dika_regist/components/file_status.dart';
import 'package:dika_regist/components/login.dart';
import 'package:dika_regist/components/absen_reco.dart';
import 'package:dika_regist/components/notifications.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_video_compress/flutter_video_compress.dart';
import 'package:geolocator/geolocator.dart';
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
  ProgressDialog pr;
  ProgressDialog pr2;
  ProgressDialog pr3;
  var _flutterVideoCompress = FlutterVideoCompress();
  SharedPreferences prefs;
  String baseUrl = "http://52.77.8.120/upload.php";
  String notifRegistrasi = "http://52.77.8.120/status_register.php";
  Geolocator geolocator = Geolocator();
  Position userPosition;
  String userLongitude;
  String userLatitude;
  Timer _timer;
  var responseApi;
  int i = 0;
  bool stop = false;
  Notifications notif, notif2;
  String nama, nip, recoId;

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
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  void initState() {
    notif = Notifications();
    notif.initializing();
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

  Future _getImage() {
    return ImagePicker.pickImage(source: ImageSource.camera, imageQuality: 70)
        .then((image) {
      setState(() {
        _imageFile = image;
      });
    }).catchError((error) {
      _showAlert(
          alertType: AlertType.error,
          alertDesc: "Error",
          alertTitle: "Gagal mengambil foto, coba lagi");
    });
  }

  Future getVideo() {
    return ImagePicker.pickVideo(source: ImageSource.camera)
        .then((video) async {
      pr2 = new ProgressDialog(context,
          type: ProgressDialogType.Normal,
          isDismissible: true,
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

  Future _statusRegistrasi() async {
    String username = 'adminDika';
    String password = 'D1k4@passw0rd';
    String basicAuth =
        'Basic ' + base64Encode(utf8.encode('$username:$password'));

    Dio dio = Dio();
    dio.options.headers['authorization'] = basicAuth;

    prefs = await SharedPreferences.getInstance();
    String namePrefs = prefs.getString('inputName');
    String nipPrefs = prefs.getString('inputNip');
    String recoIdPrefs = prefs.getString('reco_id');

    FormData formData = FormData.fromMap(
        {"name": namePrefs, "nik": nipPrefs, "reco_id": recoIdPrefs});

    dio.post(notifRegistrasi, data: formData).then((value) async {
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
            responseApi = jsonDecode(value.data);
          });
          print(responseApi);
        }
      }
    }).catchError((err) {
      print(err);
      pr.hide();
      setState(() {
        _videoFile = null;
      });
      _showAlert(
          alertType: AlertType.error,
          alertTitle: "Gagal",
          alertDesc:
              "Gagal registrasi! Coba lagi. Nama: $namePrefs, NIP: $nipPrefs");
    });
  }

  void _showNotif(int id, String title, String desc) {
    notif = Notifications(notifId: id, notifTitle: title, notifDesc: desc);
    notif.showNotifications();
  }

  void _scheduler() {
    const seconds = const Duration(minutes: 1);
    _timer = new Timer.periodic(seconds, (Timer t) {
      if (i >= 5) {
        print("Gagal");

        _showNotif(
            1, "Registrasi $nama $nip", "Wajah masih dalam proses training");

        _showAlert(
            alertType: AlertType.warning,
            alertTitle: 'Warning',
            alertDesc: "Wajah masih menunggu proses training.");
        setState(() {
          stop = !stop;
          i = 0;
        });

        return t.cancel();
      }

      print(i);

      print("Scheduler aktif from timer");
      _statusRegistrasi();

      print("response from scheduler");
      print(responseApi);

      try {
        if (responseApi != null) {
          if (responseApi["status"] == "1" &&
              responseApi["status_error"] == "0") {
            print(responseApi);

            _showNotif(int.parse(recoId), "Registrasi $nama $nip",
                "Wajah kamu berhasil ditraining");

            _showAlert(
                alertTitle: "Success",
                alertDesc: "Wajah berhasil ditraining. Nama: $nama, NIP: $nip",
                alertType: AlertType.success);

            setState(() {
              stop = !stop;
              i = 0;
            });
            return t.cancel();
          } else if (responseApi["status"] == "0" &&
              responseApi["status_error"] == "0") {
            print(responseApi);

            _showNotif(1, "Registrasi $nama $nip",
                "Wajah kamu masih dalam proses training");

            _showAlert(
                alertTitle: "Perhatian",
                alertDesc:
                    "Wajah masih dalam proses training. Nama: $nama, NIP: $nip",
                alertType: AlertType.warning);
            setState(() {
              stop = !stop;
              i = 0;
            });
            return t.cancel();
          } else if (responseApi["status"] == "0" &&
              responseApi["status_error"] == "1") {
            print("Gagal");

            _showNotif(1, "Registrasi $nama $nip",
                "Wajah kamu gagal ditraining. Silahkan coba lagi");

            _showAlert(
                alertTitle: "Gagal",
                alertDesc: "Wajah gagal di training. Nama: $nama, NIP: $nip",
                alertType: AlertType.error);

            setState(() {
              stop = !stop;
              i = 0;
            });
            return t.cancel();
          }
        }
      } catch (e) {
        print(e);
      }

      setState(() {
        i = i + 1;
      });
    });
  }

  Future _uploadData() async {
    String username = 'adminDika';
    String password = 'D1k4@passw0rd';
    String basicAuth =
        'Basic ' + base64Encode(utf8.encode('$username:$password'));

    Dio dio = Dio();
    dio.options.headers['authorization'] = basicAuth;

    prefs = await SharedPreferences.getInstance();
    String namePrefs = prefs.getString('inputName');
    String nipPrefs = prefs.getString('inputNip');

    FormData formData = FormData.fromMap({
      "name": namePrefs,
      "nik": nipPrefs,
      "longitude": userLongitude,
      "latitude": userLatitude,
      "ktp_image": await MultipartFile.fromFile(_imageFile.path,
          filename: namePrefs.toUpperCase() + ".jpg"),
      "video_file": await MultipartFile.fromFile(_videoFile.path,
          filename: namePrefs.toUpperCase() + ".avi")
    });

    pr = new ProgressDialog(context,
        type: ProgressDialogType.Normal, isDismissible: true, showLogs: false);
    pr.style(message: "Submitting Data...");

    dio.post(baseUrl, data: formData).then((value) async {
      if (value.statusCode == 200) {
        var jsonResponse = jsonDecode(value.data);
        SharedPreferences prefs2 = await SharedPreferences.getInstance();
        prefs2.setString("reco_id", jsonResponse['user_id']);
        print(jsonResponse);
        pr.hide();
        setState(() {
          _imageFile = null;
          _videoFile = null;
          recoId = jsonResponse['user_id'];
          nama = namePrefs;
          nip = nipPrefs;
        });
        _showAlert(
            alertType: AlertType.success,
            alertTitle: "Success",
            alertDesc:
                "Terimakasih sudah register! Mohon tunggu status registrasi pada notifikasi ✔️");
      }
    }).then((_) {
      if (stop) {
        setState(() {
          stop = false;
          i = 0;
        });
      } else if (stop == false) {
        print("scheduler aktif");
        _scheduler();
      }
    }).catchError((err) {
      pr.hide();
      setState(() {
        _imageFile = null;
        _videoFile = null;
      });
      _showAlert(
          alertType: AlertType.error,
          alertTitle: "Gagal",
          alertDesc: "Gagal register, mohon coba lagi! ❌");
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

  Widget _pageTitle() {
    return Center(
      child: Container(
        margin: EdgeInsets.only(bottom: 40, left: 20, right: 20),
        child: Text(
          "Regist Your Face Here",
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
    );
  }

  Widget _textStatus() {
    return _videoFile == null || _imageFile == null
        ? Center(
            child: Container(
                margin: EdgeInsets.only(bottom: 20, left: 20, right: 20),
                child: Text(
                  "Upload foto ktp kamu dan video wajah kamu selama 2 detik",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                )),
          )
        : Center(
            child: Container(
                margin: EdgeInsets.only(bottom: 20, left: 20, right: 20),
                child: Text(
                    "Pastikan foto dan video sudah sesuai format. Tekan submit data",
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          );
  }

  Widget _buttonHelper() {
    return Container(
      child: Row(
        children: <Widget>[
          Container(
            height: 50,
            margin: EdgeInsets.only(right: 20),
            child: RaisedButton(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0)),
              color: Colors.redAccent,
              onPressed: () {
                getVideo();
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
      ),
    );
  }

  Widget _submitButton() {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          _videoFile == null || _imageFile == null
              ? Container(
                  height: 50,
                  child: RaisedButton(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0)),
                    color: Colors.redAccent,
                    onPressed: getVideo,
                    child: const Text('Upload Video',
                        style: TextStyle(fontSize: 20, color: Colors.white)),
                  ),
                )
              : _buttonHelper()
        ],
      ),
    );
  }

  Widget _loginButton() {
    return Container(
      height: 50,
      child: RaisedButton(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        color: Colors.redAccent,
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => LoginReco()));
        },
        child: const Text('Absen by face',
            style: TextStyle(fontSize: 20, color: Colors.white)),
      ),
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
          _loginButton()
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
