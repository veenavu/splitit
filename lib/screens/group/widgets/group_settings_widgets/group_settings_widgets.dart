import 'dart:io';
import 'package:flutter/material.dart';
import 'package:splitit/modelClass/models.dart';

class GroupImageWidget extends StatelessWidget {
  final String groupImage;

  const GroupImageWidget({
    super.key,
    required this.groupImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Colors.purple.shade100, Colors.purple.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 3,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 50,
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: groupImage.isNotEmpty
              ? Image.file(
            File(groupImage),
            height: 100,
            width: 100,
            fit: BoxFit.cover,
          )
              : const Icon(
            Icons.group,
            size: 50,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}

class GroupNameDisplay extends StatelessWidget {
  final String groupName;

  const GroupNameDisplay({
    super.key,
    required this.groupName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade300, Colors.purple.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        groupName.toUpperCase(),
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class MemberCountDisplay extends StatelessWidget {
  final int memberCount;

  const MemberCountDisplay({
    super.key,
    required this.memberCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        "Members: $memberCount",
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.purple,
        ),
      ),
    );
  }
}

class MemberListItem extends StatelessWidget {
  final Member member;
  final String balanceSubtitle;

  const MemberListItem({
    super.key,
    required this.member,
    required this.balanceSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: Colors.purple.shade100,
            child: Text(
              member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.purple,
                fontSize: 18,
              ),
            ),
          ),
          title: Text(
            member.name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          subtitle: Text(
            balanceSubtitle,
            style: TextStyle(
              color: balanceSubtitle.contains('owe')
                  ? Colors.red
                  : balanceSubtitle.contains('get')
                  ? Colors.green
                  : Colors.grey,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class GroupAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const GroupAppBar({
    super.key,
    required this.onBack,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: onBack,
        tooltip: 'Go Back',
      ),
      title: const Text(
        "Group Settings",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.white),
          tooltip: 'Edit Group',
          onPressed: onEdit,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.white),
          tooltip: 'Delete Group',
          onPressed: onDelete,
        ),
      ],
      backgroundColor: Colors.purple,
      elevation: 4,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple, Colors.deepPurple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}