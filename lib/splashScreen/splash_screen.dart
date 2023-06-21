import 'dart:async';


import 'package:dixa_user/Assistants/assistant_method.dart';
import 'package:dixa_user/global/global.dart';
import 'package:dixa_user/screens/login_screen.dart';
import 'package:dixa_user/screens/main_screen.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  startTimer() {
    Timer(Duration(seconds: 3), () async {
      if (await firebaseAuth.currentUser != null) {
        firebaseAuth.currentUser != null
            ? AssitantMethods.readCurrentOnlineUserInfo()
            : null;
        Navigator.push(
            context, MaterialPageRoute(builder: (c) => MainScreen()));
      } else {
        Navigator.push(
            context, MaterialPageRoute(builder: (c) => LoginScreen()));
      }
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Dixa-app',
          style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
