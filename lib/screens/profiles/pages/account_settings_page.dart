// account_settings_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/settings_Controller.dart';


class AccountSettingsPage extends GetView<AccountSettingsController> {
  const AccountSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Account Settings',style:TextStyle(color: Colors.white,fontSize: 20,fontWeight: FontWeight.bold)),
        backgroundColor: Colors.purple,
        elevation: 0,
      ),
      body:  SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            _buildProfileSection(),

            const Divider(height: 1, thickness: 0.5, color: Colors.grey),

            // Menu Items
            Expanded(
              child: ListView(
                children: [
                  _buildMenuItem(
                    icon: Icons.cached_outlined,
                    label: 'Clear Cache',
                    onTap: controller.clearCache,
                  ),
                  _buildMenuItem(
                    icon: Icons.delete_outline,
                    label: 'Remove Old Data',
                    onTap: controller.removeOldData,
                  ),
                  _buildMenuItem(
                    icon: Icons.help_outline,
                    label: 'Help & Support',
                    onTap: () => Get.toNamed('/help'),
                  ),
                  _buildMenuItem(
                    icon: Icons.description_outlined,
                    label: 'Terms & Conditions',
                    onTap: () => Get.toNamed('/terms'),
                  ),
                  _buildMenuItem(
                    icon: Icons.bar_chart,
                    label: 'Statistics',
                    onTap: controller.getStatistics,
                  ),
                  _buildMenuItem(
                    icon: Icons.logout_outlined,
                    label: 'Logout',
                    onTap: controller.logout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

    );
  }
  //the profile section with avatar, name, email, and edit button.
  Widget _buildProfileSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Avatar with online indicator
          Stack(
            children: [
              Obx(
                    () => CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.cyan,
                  child: Text(
                    controller.userInitials.value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Name and Email
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(
                        () => Text(
                      controller.userName.value,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Obx(
                        () => Text(
                      controller.userEmail.value,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Edit Button
          IconButton(
            onPressed: controller.editProfile,
            icon: const Icon(
              Icons.edit_outlined,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a reusable menu item with an icon, label, and onTap callback.
  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: Colors.blueGrey,
        size: 24,
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: Colors.grey,
        size: 16,
      ),
    );
  }

}