import 'package:aboglumbo_bbk_panel/common_widget/elevated_button.dart';
import 'package:aboglumbo_bbk_panel/common_widget/text_form.dart';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddAdminPage extends StatefulWidget {
  const AddAdminPage({super.key});

  @override
  State<AddAdminPage> createState() => _AddAdminPageState();
}

class _AddAdminPageState extends State<AddAdminPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  int _accessLevel = 1; // 1 = Customer Service, 2 = Full Admin
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _addAdmin() async {
    if (_isLoading) return;

    // Check if the current user is the Core Admin
    final currentUser = LocalStore.getCachedUserData();
    if (currentUser?.phone != '+966501234567') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only the core admin can add new admins.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String phone = _phoneController.text.trim();
      if (!phone.startsWith('+')) {
        if (phone.startsWith('0')) {
          phone = '+966${phone.substring(1)}';
        } else if (!phone.startsWith('966')) {
          phone = '+966$phone';
        } else {
          phone = '+$phone';
        }
      }

      // Check if admin already exists in active or pending
      final activeCheck = await AppFirestore.adminsCollectionRef
          .where('phoneNumber', isEqualTo: phone)
          .limit(1)
          .get();

      if (activeCheck.docs.isNotEmpty) {
        throw 'Admin with this phone number already exists.';
      }

      final pendingCheck = await AppFirestore.pendingAdminsCollectionRef
          .where('phoneNumber', isEqualTo: phone)
          .limit(1)
          .get();

      if (pendingCheck.docs.isNotEmpty) {
        throw 'Admin with this phone number is already invited.';
      }

      await AppFirestore.pendingAdminsCollectionRef.add({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phoneNumber': phone,
        'accessLevel': _accessLevel,
        'createdAt': FieldValue.serverTimestamp(),
        'isCoreAdmin': false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Admin added successfully to pending invites.'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add New Admin',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter admin details to invite them to the platform.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              TextFormWidget(
                controller: _nameController,
                label: 'Full Name',
                hintText: 'Enter full name',
                validator:
                    (v) => v == null || v.isEmpty ? 'Please enter name' : null,
              ),
              const SizedBox(height: 16),
              TextFormWidget(
                controller: _emailController,
                label: 'Email Address',
                hintText: 'Enter email address',
                keyboardType: TextInputType.emailAddress,
                validator:
                    (v) =>
                        v == null || !v.contains('@')
                            ? 'Please enter a valid email'
                            : null,
              ),
              const SizedBox(height: 16),
              TextFormWidget(
                controller: _phoneController,
                label: 'Phone Number',
                hintText: 'e.g. 50XXXXXXX',
                isPhoneNumber: true,
                validator:
                    (v) =>
                        v == null || v.isEmpty
                            ? 'Please enter phone number'
                            : null,
              ),
              const SizedBox(height: 24),
              const Text(
                'Access Level',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildAccessLevelOption(
                value: 1,
                title: 'Customer Service Only',
                subtitle: 'View only access to bookings and manage sections.',
              ),
              _buildAccessLevelOption(
                value: 2,
                title: 'Full Admin Access',
                subtitle: 'Full access except management of other admins.',
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child:
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : eButton(
                          context: context,
                          text: 'Add Admin',
                          backgroundColor: AppColors.primary,
                          textColor: Colors.white,
                          onPressed: _addAdmin,
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccessLevelOption({
    required int value,
    required String title,
    required String subtitle,
  }) {
    return RadioListTile<int>(
      value: value,
      groupValue: _accessLevel,
      onChanged: (v) => setState(() => _accessLevel = v!),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      activeColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
    );
  }
}
