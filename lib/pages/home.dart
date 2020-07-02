import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stopcovid/models/user.dart';
import 'package:stopcovid/pages/activity_feed.dart';
import 'package:stopcovid/pages/profile.dart';
import 'package:stopcovid/pages/search.dart';
import 'package:stopcovid/pages/timeline.dart';
import 'package:stopcovid/pages/upload.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'create_account.dart';

final GoogleSignIn googleSignIn = GoogleSignIn();
final StorageReference storageRef = FirebaseStorage.instance.ref();
final userRef = Firestore.instance.collection('users');
final postRef = Firestore.instance.collection('posts');
final commentRef = Firestore.instance.collection("comments");
final activityFeedRef = Firestore.instance.collection("feed");
final followersRef = Firestore.instance.collection("followers");
final followingRef = Firestore.instance.collection("following");
final timelineRef = Firestore.instance.collection("timeline");
final DateTime timestamp = DateTime.now();
User currentUser;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  FirebaseMessaging _firebaseMessenging = FirebaseMessaging();
  bool _isAuth = false;
  PageController pageController;
  int pageIndex = 0;

  @override
  void initState() {
    super.initState();
    pageController = PageController();
    // detects xhen user sigin in
    googleSignIn.onCurrentUserChanged.listen((account) {
      handleGoogleSign(account);
    }, onError: (err) {
      print("Error Signin in: $err");
    });
    // Reauthenticate user when app is opened again
    googleSignIn.signInSilently(suppressErrors: false).then((account) {
      handleGoogleSign(account);
    }).catchError((err) {
      print("Error Signin in: $err");
    });
  }

  @override
  dispose() {
    pageController.dispose();
    super.dispose();
  }

  handleGoogleSign(GoogleSignInAccount account) async {
    if (account != null) {
      await createUserInFirestore();
      setState(() {
        _isAuth = true;
      });
      await configurePushNotifications();
    } else {
      setState(() {
        _isAuth = false;
      });
    }
  }

  configurePushNotifications() {
    final GoogleSignInAccount user = googleSignIn.currentUser;
    if (Platform.isIOS) getiosPermission();

    _firebaseMessenging.getToken().then((token) {
      print('Firebase Messenging token: $token\n');
      userRef.document(user.id).updateData({"androidNotificatonToken": token});
    });
    _firebaseMessenging.configure(
      // onLaunch: (Map<String, dynamic> message) async {},
      // onResume: (Map<String, dynamic> message) async {},
      onMessage: (Map<String, dynamic> message) async {
        print('on message: $message\n');
        final String recipientId = message['data']['recipient'];
        final String body = message['notification']['body'];

        if (recipientId == user.id) {
          print('Notification Shown ! ');
          SnackBar snackBar = SnackBar(
            content: Text(
              body,
              overflow: TextOverflow.ellipsis,
            ),
          );
          _scaffoldKey.currentState.showSnackBar(snackBar);
        }

        print('Notification Not Shown');
      },
    );
  }

  getiosPermission() {
    _firebaseMessenging.requestNotificationPermissions(
        IosNotificationSettings(alert: true, sound: true, badge: true));
    _firebaseMessenging.onIosSettingsRegistered.listen((settings) {
      print("Setting Registered : $settings");
    });
  }

  createUserInFirestore() async {
    // Check if user existe in user colloection in database according to their user id

    final GoogleSignInAccount user = googleSignIn.currentUser;
    DocumentSnapshot doc = await userRef.document(user.id).get();
    if (!doc.exists) {
      // if the user doesn't exist, then we want to take them to the create account page
      final username = await Navigator.push(
          context, MaterialPageRoute(builder: (context) => CreateAccount()));
      // get username from create account,use it to make new user document in users collection
      userRef.document(user.id).setData({
        'id': user.id,
        'username': username,
        'photoUrl': user.photoUrl,
        "email": user.email,
        "displayName": user.displayName,
        "bio": "",
        'timestamp': timestamp
      });

      //Make the new user their own followers to include their posts in their timeline

      await followersRef
          .document(user.id)
          .collection("userFollowers")
          .document(user.id)
          .setData({});

      doc = await userRef.document(user.id).get();
    }

    currentUser = User.fromDocument(doc);
    print(currentUser);
    print(currentUser.username);
  }

  Scaffold buildUnAuthScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).accentColor
              //Theme.of(context).primaryColor,
              //Theme.of(context).accentColor
            ])),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              "#CS Social Media",
              style: TextStyle(
                  fontFamily: "Signatra", fontSize: 50.0, color: Colors.white),
            ),
            GestureDetector(
              onTap: () {
                Login();
              },
              child: Container(
                width: 260.0,
                height: 60,
                decoration: BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage(
                          'assets/images/google_signin_button.png',
                        ),
                        fit: BoxFit.cover)),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isAuth ? buildAuthScreen() : buildUnAuthScreen();
  }

  // ignore: non_constant_identifier_names
  Login() {
    googleSignIn.signIn();
  }

  // ignore: non_constant_identifier_names
  Logout() {
    googleSignIn.signOut();
  }

  onPageChanged(int pageIndex) {
    setState(() {
      this.pageIndex = pageIndex;
    });
  }

  onTap(int pageIndex) {
    pageController.animateToPage(pageIndex,
        duration: Duration(milliseconds: 200), curve: Curves.easeInOutCirc);
  }

  Scaffold buildAuthScreen() {
    return Scaffold(
      key: _scaffoldKey,
      body: PageView(
        children: <Widget>[
          Timeline(currentUser: currentUser),
          ActivityFeed(),
          Upload(currentUser: currentUser),
          Search(),
          Profile(profileId: currentUser?.id),
        ],
        controller: pageController,
        onPageChanged: onPageChanged,
        physics: NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: CupertinoTabBar(
        currentIndex: pageIndex,
        onTap: onTap,
        activeColor: Theme.of(context).primaryColor,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.whatshot),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_active),
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.photo_camera,
              size: 35.0,
            ),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
          ),
        ],
      ),
    );
  }
}
