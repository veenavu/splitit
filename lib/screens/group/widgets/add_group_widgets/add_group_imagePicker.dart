import 'dart:io';
import 'package:flutter/material.dart';

class GroupImagePicker extends StatelessWidget {
  final String? imagePath;
  final VoidCallback onTap;

  const GroupImagePicker({
    super.key,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Colors.purple.shade200, Colors.purple.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: imagePath != null
            ? ClipOval(
          child: Image.file(
            File(imagePath!),
            fit: BoxFit.cover,
            width: 120,
            height: 120,
          ),
        )
            : const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate,
                size: 40,
                color: Colors.white,
              ),
              SizedBox(height: 8),
              Text(
                "Add Image",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}