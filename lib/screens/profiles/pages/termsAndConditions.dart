import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Terms and Conditions',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
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
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: '1. Acceptance of Terms',
              content: 'By accessing and using SplitIt, you agree to be bound by these Terms and Conditions. If you do not agree with any part of these terms, you may not use the application.',
            ),
            _buildSection(
              title: '2. User Accounts',
              content: 'Users must provide accurate and complete information when creating an account. You are responsible for maintaining the confidentiality of your account credentials and for all activities under your account.',
            ),
            _buildSection(
              title: '3. Group Management',
              content: 'When creating or joining groups:\n'
                  '• You agree to only add members with their consent\n'
                  '• You will maintain appropriate and accurate expense records\n'
                  '• You understand that all group members can view expense details',
            ),
            _buildSection(
              title: '4. Expense Recording',
              content: 'Users must:\n'
                  '• Record expenses accurately and truthfully\n'
                  '• Obtain consent from group members before adding expenses\n'
                  '• Maintain proper documentation of actual expenses\n'
                  '• Not manipulate or falsify expense records',
            ),
            _buildSection(
              title: '5. Settlements',
              content: 'Users acknowledge that:\n'
                  '• The app calculations are for reference only\n'
                  '• Actual settlements happen outside the app\n'
                  '• Users are responsible for verifying settlement amounts\n'
                  '• The app is not responsible for payment disputes',
            ),
            _buildSection(
              title: '6. Privacy and Data',
              content: 'We respect your privacy and handle data according to our Privacy Policy. Users agree that:\n'
                  '• Contact information will be used only for app functionality\n'
                  '• Group expense data is visible to all group members\n'
                  '• Personal data will not be shared with third parties',
            ),
            _buildSection(
              title: '7. User Conduct',
              content: 'Users must not:\n'
                  '• Misuse the application for fraudulent purposes\n'
                  '• Harass other users or create spam expenses\n'
                  '• Attempt to manipulate or hack the system\n'
                  '• Share account credentials with others',
            ),
            _buildSection(
              title: '8. Liability',
              content: 'The application is provided "as is" without warranties. We are not responsible for:\n'
                  '• Disputes between users\n'
                  '• Accuracy of expense records\n'
                  '• Failed settlements between users\n'
                  '• Loss of data or financial losses',
            ),
            _buildSection(
              title: '9. Termination',
              content: 'We reserve the right to terminate or suspend accounts that violate these terms or engage in fraudulent activity.',
            ),
            _buildSection(
              title: '10. Changes to Terms',
              content: 'We may modify these terms at any time. Continued use of the application constitutes acceptance of updated terms.',
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Last Updated: ${DateTime.now().year}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade700,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}