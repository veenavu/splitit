import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splitit/DatabaseHelper/hive_services.dart';
import 'package:splitit/routes/app_pages.dart';
import 'package:splitit/screens/welcome/get_started.dart';

import 'routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ExpenseManagerService.initHive();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'SplitIt',
      initialRoute: Routes.initial,
      debugShowCheckedModeBanner: false,
      getPages: AppPages.pages,
      theme: ThemeData(
        primaryColor: const Color(0xff5f0967),
        primarySwatch: Colors.purple,
      ),
    );
  }
}
