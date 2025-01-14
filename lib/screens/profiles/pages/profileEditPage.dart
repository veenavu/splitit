
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_edit_controller.dart';


class ProfileEditPage extends GetView<ProfileEditController> {
  const ProfileEditPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.purple,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple, Colors.deepPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (!controller.isProfileLoaded.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildProfileImage(),
                const SizedBox(height: 40),
                _buildInputFields(),
                const SizedBox(height: 40),
                _buildSaveButton(),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildProfileImage() {
    return Center(
      child: Stack(
        children: [
          Obx(() {
            final image = controller.imageFile.value;
            return CircleAvatar(
              radius: 60,
              backgroundColor: Colors.purple.shade100,
              backgroundImage: image != null ? FileImage(image) : null,
              child: image == null
                  ? const Icon(Icons.person, size: 60, color: Colors.purple)
                  : null,
            );
          }),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: InkWell(
                onTap: controller.pickImage,
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputFields() {
    return Column(
      children: [
        TextField(
          controller: controller.nameController,
          decoration: InputDecoration(
            labelText: 'Name',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.purple.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.purple, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: controller.emailController,
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.purple.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.purple, width: 2),
            ),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        Obx(() => TextField(
          controller: TextEditingController(
            text: controller.profile.value?.phone ?? '',
          ),
          decoration: InputDecoration(
            labelText: 'Phone',
            prefixIcon: const Icon(Icons.phone_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.purple.shade200),
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
          ),
          enabled: false,
        )),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Obx(() => ElevatedButton(
      onPressed: controller.isLoading.value ? null : controller.saveProfile,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.purple,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: controller.isLoading.value
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text(
        'Save Changes',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ));
  }
}