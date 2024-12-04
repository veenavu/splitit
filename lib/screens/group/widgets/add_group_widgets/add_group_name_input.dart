import 'package:flutter/material.dart';

class GroupNameInput extends StatelessWidget {
  final TextEditingController controller;

  const GroupNameInput({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Enter Group Name',
        hintStyle: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 14,
          fontStyle: FontStyle.italic,
        ),
        filled: true,
        fillColor: Colors.purple.shade50,
        prefixIcon: const Icon(
          Icons.group,
          color: Colors.purple,
          size: 24,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.purple.shade100),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.purple, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
      style: const TextStyle(
        fontSize: 16,
        color: Colors.black87,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}