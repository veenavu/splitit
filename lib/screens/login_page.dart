import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:splitit/DatabaseHelper/hive_services.dart';
import 'package:splitit/modelClass/models.dart';
import 'package:splitit/screens/group_page.dart';
import 'package:splitit/screens/profile_creation.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();


  @override
  Widget build(BuildContext context) {
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
                    // Phone Input Field
                    TextFormField(
                      controller: _phoneController,
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
                    const SizedBox(height: 40.0),

                    // Submit Button
                    Center(
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: Builder(
                          builder: (context) => ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                Profile? userProfile = ExpenseManagerService.getProfileByPhone(_phoneController.text);
                                if(userProfile != null) {
                                  final box = Hive.box(ExpenseManagerService.normalBox);
                                  box.put("mobile", _phoneController.text);
                                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const GroupPage()));
                                }else{
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('User not found, please sign up.')),
                                  );
                                }
                              }

                              // _submitForm();
                            },
                            child: const Text(
                              'Login',
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

                    const SizedBox(height: 20.0),
                    TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SignUpPage()));
                        },
                        child: Text("Don't have an account? Sign up",
                            style: GoogleFonts.lato(color: Colors.white, fontSize: 16))),
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
