import 'package:dika_regist/components/login.dart';
import 'package:dika_regist/components/submit_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String name = prefs.getString('inputName');
  String nip = prefs.getString("inputNip");
  print('Name $name and NIP $nip');

  runApp(MaterialApp(
      title: 'DIKA E-Regist',
      theme: ThemeData(
          primarySwatch: Colors.red, textTheme: GoogleFonts.ralewayTextTheme()),
      home: name != null && nip != null ? SubmitPage() : Login()));
}

// class MyApp extends StatefulWidget {
//   // This widget is the root of your application.

//   @override
//   _MyAppState createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   String name, nip;

//   SharedPreferences prefs;
//   Widget _toChoose;

//   @override
//   void initState() {
//     super.initState();
//     //_test();
//   }

//   Future _test() async {
//     prefs = await SharedPreferences.getInstance();
//     name = prefs.getString('inputName');
//     nip = prefs.getString("inputNip");

//     if (name != null && nip != null) {
//       setState(() {
//         print("Has value");
//         _toChoose = SubmitPage();
//       });
//     } else {
//       print("No value");
//       setState(() {
//         _toChoose = Login();
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Demo',
//       theme: ThemeData(
//           primarySwatch: Colors.red, textTheme: GoogleFonts.ralewayTextTheme()),
//       home: Login(),
//     );
//   }
// }
