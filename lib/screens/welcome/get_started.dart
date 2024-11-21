import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:splitit/routes/app_routes.dart';
import 'package:splitit/screens/auth/login_page.dart';
import 'package:splitit/screens/auth/sign_up.dart';

class GetStartedPage extends StatelessWidget {
  const GetStartedPage({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
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
            Container(
              width: isMobile ? screenWidth * 0.8 : screenWidth * 0.5,
              height: screenHeight * 0.07, // Responsive button height
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5F0967), Color(0xFFBD11CD)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: () {
                  //Navigate to the Login screen
                  Get.offNamed(Routes.login);

                  // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.02,
                  ),
                ),
                child: Text(
                  'Get Started',
                  style: TextStyle(
                    fontSize: screenWidth * 0.05,
                    color: const Color(0xFF5F0967),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.03), // Responsive spacing
          ],
        ),
      ),
    );
  }
}
