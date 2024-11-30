import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:splitit/DatabaseHelper/hive_services.dart';
import 'package:splitit/routes/app_routes.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    Future.delayed(const Duration(seconds: 2), () {
      _navigateToNextPage();
    });
    super.initState();
  }

  _navigateToNextPage() {
    final box = Hive.box(ExpenseManagerService.normalBox);
    final isLoggedIn = box.get("isLoggedIn", defaultValue: false);

    if (isLoggedIn) {
      Get.offNamed(Routes.dashboard);
    } else {
      Get.offNamed(Routes.getStarted);
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.sizeOf(context).width;
    double screenHeight = MediaQuery.sizeOf(context).height;
    bool isMobile = screenWidth < 600; // Define mobile breakpoint

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/background.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05, // Responsive horizontal padding
          vertical: screenHeight * 0.05, // Responsive vertical padding
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Split It',
              style: GoogleFonts.lato(
                textStyle: Theme.of(context).textTheme.displayLarge,
                fontSize: isMobile ? screenWidth * 0.12 : screenWidth * 0.08,
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: screenHeight * 0.03), // Responsive spacing
            Text(
              'Welcome to our app! Let’s get started by exploring the features.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isMobile ? screenWidth * 0.04 : screenWidth * 0.03,
                color: Colors.white,
              ),
            ),
            SizedBox(height: screenHeight * 0.2), // Adjust spacing for layout
          ],
        ),
      ),
    );
  }
}
