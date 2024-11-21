import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:splitit/DatabaseHelper/hive_services.dart';
import 'package:splitit/modelClass/models.dart';
import 'package:splitit/screens/auth/controller/auth_controller.dart';
import 'package:splitit/screens/dashboard/dashboard.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/background.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: authController.signUpFormKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40.0),
                    Text(
                      'Split It',
                      style: GoogleFonts.lato(
                        textStyle: Theme.of(context).textTheme.displayLarge,
                        fontSize: 48,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 40.0),
                    Obx(() {
                        return GestureDetector(
                          onTap: authController.pickImage,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: authController.imagePath != null ? FileImage(File(authController.imagePath!.value)) : null,
                            child: authController.imagePath == null ? const Icon(Icons.add_a_photo, size: 50) : null,
                          ),
                        );
                      }
                    ),
                    const SizedBox(height: 40.0),

                    // Name Input Field
                    TextFormField(
                      controller: authController.nameController,
                      decoration: InputDecoration(
                        hintText: 'Name',
                        prefixIcon: const Icon(Icons.person),
                        fillColor: const Color(0xFFD9D9D9),
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      keyboardType: TextInputType.name,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),

                    // Email Input Field
                    TextFormField(
                      controller: authController.emailController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.email_outlined),
                        hintText: 'Email',
                        fillColor: const Color(0xFFD9D9D9),
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }

                        // Updated regex for a more accurate email validation
                        String pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
                        RegExp regex = RegExp(pattern);

                        if (!regex.hasMatch(value)) {
                          return 'Enter a valid email address';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),

                    // Phone Input Field
                    TextFormField(
                      controller: authController.signUpPhoneController,
                      decoration: InputDecoration(
                        hintText: 'Phone Number',
                        prefixIcon: const Icon(Icons.phone),
                        fillColor: const Color(0xFFD9D9D9),
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }

                        if (!RegExp(r'^\+?\d+$').hasMatch(value)) {
                          return 'Enter a valid phone number (digits only, optional + at start)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 100.0),

                    // Submit Button
                    Center(
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: Builder(
                          builder: (context) => ElevatedButton(
                            onPressed: (){
                              authController.signup();
                            },
                            child: const Text(
                              'Submit',
                              style: TextStyle(
                                color: Color(0xff5F0967),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


}
