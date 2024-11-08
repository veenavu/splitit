import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:splitit/DatabaseHelper/hive_services.dart';
import 'package:splitit/modelClass/models.dart';
import 'package:splitit/screens/group_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _imagePath; // Initialize as nullable

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("lib/assets/background.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
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
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _imagePath != null
                            ? FileImage(File(_imagePath!))
                            : null,
                        child: _imagePath == null
                            ? const Icon(Icons.add_a_photo, size: 50)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 40.0),

                    // Name Input Field
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Name',
                        prefixIcon: const Icon(Icons.person),
                        fillColor: const Color(0xFFD9D9D9),
                        filled: true,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25)),
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
                      controller: _emailController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.email_outlined),
                        hintText: 'Email',
                        fillColor: const Color(0xFFD9D9D9),
                        filled: true,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25)),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }

                        // Updated regex for a more accurate email validation
                        String pattern =
                            r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
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
                      controller: _phoneController,
                      decoration: InputDecoration(
                        hintText: 'Phone Number',
                        prefixIcon: const Icon(Icons.phone),
                        fillColor: const Color(0xFFD9D9D9),
                        filled: true,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25)),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10)
                      ],
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
                            onPressed: () {
                              _submitForm();
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

  Future<void> _pickImage() async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imagePath = pickedFile.path;
        });
      }
    } catch (e) {
      log("Image picker error: $e");
    }
  }


  Future<void> _saveProfileImage() async {
    if (_imagePath == null) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage =
          await File(_imagePath!).copy('${directory.path}/$fileName');

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('profileImagePath', savedImage.path);
    } catch (e) {
      log('Error saving profile image: $e');
    }
  }

  Future<void> _saveProfileData() async {
    try {
      final profileData = Profile(
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        imagePath: _imagePath,
      );

      ExpenseManagerService.saveProfile(profileData);
    } catch (e) {
      log('Error saving profile data: $e');
      rethrow; // Re-throw to handle in _submitForm
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Save profile image if selected
        await _saveProfileImage();

        // Save profile data
        await _saveProfileData();

        // Set login status
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile saved successfully!"),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to GroupsScreen
        log("Navigating to GroupsScreen...");
        await Future.delayed(const Duration(
            milliseconds: 500)); // Brief delay for snackbar to be visible

        if (mounted) {
          final box = Hive.box(ExpenseManagerService.normalBox);
          box.put("mobile", _phoneController.text);
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const GroupPage()));
        }
      } catch (e) {
        // Hide loading indicator if showing
        if (mounted) {
          Navigator.pop(context);
        }

        log("Error in submission: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error saving profile: ${e.toString()}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
