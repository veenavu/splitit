import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:splitit/DatabaseHelper/hive_services.dart';
import 'package:splitit/routes/app_routes.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Center(child: Text('Profile Page', style: TextStyle(fontSize: 24))),
        IconButton(
            onPressed: () {
              final box = Hive.box(ExpenseManagerService.normalBox);

              box.put("isLoggedIn", false);

              Get.offAllNamed(Routes.login);
            },
            icon: const Icon(Icons.logout))
      ],
    );
  }
}
