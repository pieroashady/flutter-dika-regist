import 'dart:convert';
import 'dart:io';

import 'package:dika_regist/components/file_status.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
          primarySwatch: Colors.red, textTheme: GoogleFonts.ralewayTextTheme()),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var data;
  File _imageFile;
  File _videoFile;

  @override
  void initState() {
    super.initState();
  }

  Future _getImage() {
    return ImagePicker.pickImage(source: ImageSource.camera).then((image) {
      setState(() {
        _imageFile = image;
        print(_imageFile.toString());
      });
    }).catchError((error) => debugPrint(error));
  }

  Future _getVideo() {
    return ImagePicker.pickVideo(source: ImageSource.camera).then((video) {
      setState(() {
        _videoFile = video;
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
    var fileName =
        'Aldi' + new DateTime.now().millisecondsSinceEpoch.toString();
    FormData formData = FormData.fromMap({
      "name": "Aldi",
      "nik": "12173055",
      "video_file": await MultipartFile.fromFile(_videoFile.path,
          filename: "video" + fileName),
      "ktp_image": await MultipartFile.fromFile(_imageFile.path,
          filename: "ktp" + fileName),
    });
    dio
        .post("http://52.77.8.120/upload.php",
            data: formData,
            options:
                Options(headers: <String, String>{'authorization': basicAuth}))
        .then((value) {
      value.statusCode == 200 ? print("Success") : print(value.statusCode);
    }).catchError((err) => print(err));
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
                Text("Upload foto selfie kamu dan video kamu selama 2 detik"),
          )
        : Container(
            margin: EdgeInsets.only(bottom: 20),
            child: Text("All is set up"),
          );
  }

  Widget _submitButton() {
    return Column(
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
            : Container(
                height: 50,
                child: RaisedButton(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0)),
                  color: Colors.redAccent,
                  onPressed: _uploadData,
                  child: const Text('Submit Data',
                      style: TextStyle(fontSize: 20, color: Colors.white)),
                ),
              ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          centerTitle: true,
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
        onPressed: _getImage,
        tooltip: 'Open camera',
        child: Icon(Icons.camera),
      ),
    );
  }
}
