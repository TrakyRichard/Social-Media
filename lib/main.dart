import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:stopcovid/pages/home.dart';

void main() {
  runApp(MyApp());
  Firestore.instance.settings(timestampsInSnapshotsEnabled: true).then((_) {
    print("Timestamp enabled in snapshot \n");
  }, onError: (_) {
    print("There was an error enabling snapshot \n");
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StopCovid',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.red,
        accentColor: Colors.blueAccent[900]
      ),
      home: Home(),
    );
  }
}
