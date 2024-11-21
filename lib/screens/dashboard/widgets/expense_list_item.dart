import 'dart:io';

import 'package:flutter/material.dart';

class ExpenseListItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<String>? details;
  final IconData? icon;
  final Color iconColor;
  final bool showImage;
  final bool showGroupImage;
  final String? groupImage; // Add the groupImage property

  const ExpenseListItem({
    super.key,
    required this.title,
    required this.subtitle,
    this.details,
    this.icon,
    required this.iconColor,
    this.showImage = false,
    this.showGroupImage = false,
    this.groupImage, // Accept groupImage
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: groupImage != null ? Colors.transparent : iconColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: groupImage != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(groupImage!), // Display the groupImage
                    fit: BoxFit.cover,
                  ),
                )
              : Icon(
                  icon ?? Icons.article, // Fallback to icon if groupImage is null
                  color: iconColor,
                ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subtitle,
              style: TextStyle(
                color: subtitle.contains('owe')
                    ? Colors.orange
                    : subtitle.contains('lent')
                        ? Colors.green
                        : Colors.grey,
                fontSize: 14,
              ),
            ),
            if (details != null) ...[
              const SizedBox(height: 4),
              ...details!.map(
                (detail) => Text(
                  detail,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
