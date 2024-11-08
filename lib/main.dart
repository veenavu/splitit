import 'package:flutter/material.dart';
import 'package:splitit/DatabaseHelper/hive_services.dart';
import 'package:splitit/screens/get_started.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ExpenseManagerService.initHive();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SplitIt',
      home: const GetStartedPage(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xff5f0967),
        primarySwatch: Colors.purple,
      ),
    );
  }
}
