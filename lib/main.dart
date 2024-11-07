import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:splitit/screens/Addgroup.dart';
import 'package:splitit/screens/GroupMainPage.dart';
import 'package:splitit/screens/addGroupMembers.dart';
import 'package:splitit/screens/setProfile.dart';
import 'package:splitit/screens/demo.dart';
import 'package:splitit/screens/getStarted.dart';
import 'package:splitit/screens/groupDetails.dart';
import 'package:splitit/screens/setProfile.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';



void main(){

  runApp(const MyApp());

}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SplitIt',
      home:

      AuthCheck(),

      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xff5f0967),
        primarySwatch: Colors.purple,
      ),
    );
  }
}
class AuthCheck extends StatelessWidget {
  Future<bool> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkLoginStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container();
        }
        return snapshot.data == true ? GroupsScreen() : GetStartedPage();
      },
    );
  }
}


