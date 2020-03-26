import 'package:cached_network_image/cached_network_image.dart';
import 'package:dika_regist/components/submit_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_clippers/flutter_custom_clippers.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  Login({Key key}) : super(key: key);

  @override
  LoginState createState() => LoginState();
}

class LoginState extends State<Login> {
  String inputName, inputNip;
  String prefsName, prefsNip;
  SharedPreferences prefs;
  var _inputName = TextEditingController();
  var _inputNip = TextEditingController();

  String origami =
      'https://firebasestorage.googleapis.com/v0/b/dl-flutter-ui-challenges.appspot.com/o/img%2Forigami.png?alt=media';

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

  void _navigateToSubmitData() async {
    if (inputName != null && inputNip != null) {
      prefs = await SharedPreferences.getInstance();
      prefs.setString("inputName", _inputName.text);
      prefs.setString("inputNip", _inputNip.text);
      print("Login data saved...");
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SubmitPage()),
      );
    } else {
      Alert(
        context: context,
        style: alertStyle,
        type: AlertType.error,
        title: "INVALID",
        desc: "Mohon isi semua data login",
        buttons: [
          DialogButton(
            child: Text(
              "Close",
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

  Widget _buildPageContent(BuildContext context) {
    return Container(
      color: Colors.red,
      child: ListView(
        children: <Widget>[
          SizedBox(
            height: 30.0,
          ),
          CircleAvatar(
            child: CachedNetworkImage(
              imageUrl: origami,
            ),
            maxRadius: 50,
            backgroundColor: Colors.transparent,
          ),
          SizedBox(
            height: 20.0,
          ),
          _buildLoginForm(),
        ],
      ),
    );
  }

  Container _buildLoginForm() {
    return Container(
      padding: EdgeInsets.all(20.0),
      child: Stack(
        children: <Widget>[
          ClipPath(
            clipper: RoundedDiagonalPathClipper(),
            child: Container(
              height: 400,
              padding: EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(40.0)),
                color: Colors.white,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    height: 90.0,
                  ),
                  Container(
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: TextField(
                        textCapitalization: TextCapitalization.sentences,
                        controller: _inputName,
                        onChanged: (value) {
                          inputName = value;
                        },
                        style: TextStyle(color: Colors.blue),
                        decoration: InputDecoration(
                            hintText: "Nama",
                            hintStyle: TextStyle(color: Colors.red),
                            border: InputBorder.none,
                            icon: Icon(Icons.email, color: Colors.red)),
                      )),
                  Container(
                      child: Divider(color: Colors.blue.shade400),
                      padding: EdgeInsets.only(
                          left: 20.0, right: 20.0, bottom: 10.0)),
                  Container(
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: TextField(
                        controller: _inputNip,
                        onChanged: (value) {
                          inputNip = value;
                        },
                        textCapitalization: TextCapitalization.sentences,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: Colors.blue),
                        decoration: InputDecoration(
                            hintText: "NIP",
                            hintStyle: TextStyle(color: Colors.red),
                            border: InputBorder.none,
                            icon: Icon(Icons.lock, color: Colors.red)),
                      )),
                  Container(
                      child: Divider(color: Colors.blue.shade400),
                      padding: EdgeInsets.only(
                          left: 20.0, right: 20.0, bottom: 10.0)),
                  SizedBox(height: 10.0),
                ],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              CircleAvatar(
                radius: 40.0,
                backgroundColor: Colors.red.shade600,
                child: Icon(Icons.person),
              ),
            ],
          ),
          Container(
            height: 420,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: RaisedButton(
                onPressed: () {
                  _navigateToSubmitData();
                },
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40.0)),
                child: Text("Login", style: TextStyle(color: Colors.white70)),
                color: Colors.red,
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildPageContent(context),
    );
  }
}
