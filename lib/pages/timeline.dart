
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:stopcovid/widgets/header.dart';
import 'package:stopcovid/widgets/progress.dart';

final userRef =  Firestore.instance.collection('users');


class Timeline extends StatefulWidget {
  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {

  @override
  void initState() {
    // TODO: implement initState
    getUsers();
    super.initState();
  }
  @override
  Widget build(context) {
    return Scaffold(
      appBar: header(context, isAppTitle: true),
      body: circularProgress(),
    );
  }
}

getUsers() {
}
