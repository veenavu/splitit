import 'package:flutter/material.dart';

class MemberAddingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Members Screen"),
      ),
      body: Center(child: Text("Your content goes here")),
      floatingActionButton: Container(
        height: 50, // Adjust height to match the button design
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            colors: [Color(0xFF8E2DE2), Color(0xFFDA22FF)], // Purple-pink gradient colors
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            // Action when button is pressed
            print("Add members pressed");
          },
          backgroundColor: Colors.transparent, // Transparent to use the gradient container's background
          elevation: 0, // Remove shadow to match the flat style
          label: Row(
            children: [
              Icon(Icons.person_add, color: Colors.white), // Add member icon
              SizedBox(width: 8), // Space between icon and text
              Text(
                "Add Members",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat, // Centered at bottom
    );
  }
}
