import 'dart:io';

import 'package:flutter/material.dart';

class FileStatus extends StatefulWidget {
  FileStatus({Key key, this.imgFile, this.videoFile}) : super(key: key);
  final File imgFile, videoFile;

  @override
  _FileStatusState createState() => _FileStatusState();
}

class _FileStatusState extends State<FileStatus> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          margin: EdgeInsets.only(right: 100),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text("KTP Status"),
              SizedBox(
                height: 20,
              ),
              Text("Video Status")
            ],
          ),
        ),
        Container(
          alignment: Alignment.centerRight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              widget.imgFile == null ? Text("❌") : Text("✔️"),
              SizedBox(
                height: 20,
              ),
              widget.videoFile == null ? Text('❌') : Text("✔️")
            ],
          ),
        ),
      ],
    );
  }
}
