import 'package:flutter/material.dart';
import 'package:stopcovid/pages/home.dart';

void main() {
  runApp(MyApp());
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
