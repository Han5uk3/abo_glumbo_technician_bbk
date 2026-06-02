import 'package:aboglumbo_bbk_panel/common_widget/elevated_button.dart';
import 'package:aboglumbo_bbk_panel/common_widget/text_form.dart';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/admin.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddAdminPage extends StatefulWidget {
  final AdminModel? adminToEdit;
  final bool isPending;

  const AddAdminPage({
    super.key,
    this.adminToEdit,
    this.isPending = false,
  });

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

  String get _submitButtonText {
    if (widget.adminToEdit == null) return 'Add Admin';
    final locale = AppLocalizations.of(context)?.localeName ?? 'en';
    if (locale == 'ar') return 'حفظ التغييرات';
    if (locale == 'ur') return 'تبدیلیاں محفوظ کریں';
    return 'Save Changes';
  }

  String get _pageTitle {
    if (widget.adminToEdit == null) return 'Add New Admin';
    final locale = AppLocalizations.of(context)?.localeName ?? 'en';
    if (locale == 'ar') return 'تعديل المشرف';
    if (locale == 'ur') return 'ایڈمن میں ترمیم کریں';
    return 'Edit Admin';
  }

  String get _pageSubtitle {
    if (widget.adminToEdit == null) {
      return 'Enter admin details to invite them to the platform.';
    }
    final locale = AppLocalizations.of(context)?.localeName ?? 'en';
    if (locale == 'ar') return 'تعديل تفاصيل المشرف ومستوى الوصول.';
    if (locale == 'ur') return 'ایڈمن کی تفصیلات اور رسائی کی سطح میں ترمیم کریں۔';
    return 'Edit admin details and access level.';
  }

  String get _successMessage {
    if (widget.adminToEdit == null) {
      return AppLocalizations.of(context)?.adminAddedSuccessfully ?? 'Admin added successfully to pending invites.';
    }
    final locale = AppLocalizations.of(context)?.localeName ?? 'en';
    if (locale == 'ar') return 'تم تحديث المشرف بنجاح.';
    if (locale == 'ur') return 'ایڈمن کو کامیابی کے ساتھ اپ ڈیٹ کر دیا گیا ہے۔';
    return 'Admin updated successfully.';
  }

  @override
  void initState() {
    super.initState();
    if (widget.adminToEdit != null) {
      _nameController.text = widget.adminToEdit!.name;
      _emailController.text = widget.adminToEdit!.email;
      
      String rawPhone = widget.adminToEdit!.phoneNumber;
      if (rawPhone.startsWith('+966')) {
        rawPhone = rawPhone.substring(4);
      } else if (rawPhone.startsWith('966')) {
        rawPhone = rawPhone.substring(3);
      }
      _phoneController.text = rawPhone;
      _accessLevel = widget.adminToEdit!.accessLevel;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _addOrSaveAdmin() async {
    if (_isLoading) return;

    // Check if the current user is the Core Admin
    final isCoreAdmin = LocalStore.getCachedAdminData()?.isSuperAdmin ?? false;
    if (!isCoreAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.onlyCoreAdminCanAdd ?? 'Only the core admin can add new admins.'),
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

      // Check if phone number already exists, ignoring the current admin if editing
      if (widget.adminToEdit == null || phone != widget.adminToEdit!.phoneNumber) {
        final activeCheck = await AppFirestore.adminsCollectionRef
            .where('phoneNumber', isEqualTo: phone)
            .get();

        for (var doc in activeCheck.docs) {
          if (widget.adminToEdit == null || doc.id != widget.adminToEdit!.uid || widget.isPending) {
            throw 'Admin with this phone number already exists.';
          }
        }

        final pendingCheck = await AppFirestore.pendingAdminsCollectionRef
            .where('phoneNumber', isEqualTo: phone)
            .get();

        for (var doc in pendingCheck.docs) {
          if (widget.adminToEdit == null || doc.id != widget.adminToEdit!.uid || !widget.isPending) {
            throw 'Admin with this phone number is already invited.';
          }
        }
      }

      if (widget.adminToEdit != null) {
        // Edit mode
        if (widget.isPending) {
          await AppFirestore.pendingAdminsCollectionRef.doc(widget.adminToEdit!.uid).update({
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'phoneNumber': phone,
            'accessLevel': _accessLevel,
          });
        } else {
          await AppFirestore.adminsCollectionRef.doc(widget.adminToEdit!.uid).update({
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'phoneNumber': phone,
            'accessLevel': _accessLevel,
          });
        }
      } else {
        // Add mode
        await AppFirestore.pendingAdminsCollectionRef.add({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phoneNumber': phone,
          'accessLevel': _accessLevel,
          'createdAt': FieldValue.serverTimestamp(),
          'isCoreAdmin': false,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_successMessage),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)?.errorOccurred(e.toString()) ?? 'Error: $e'), backgroundColor: Colors.red),
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
        title: Text(
          _pageTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
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
              Text(
                _pageSubtitle,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
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
                          text: _submitButtonText,
                          backgroundColor: AppColors.primary,
                          textColor: Colors.white,
                          onPressed: _addOrSaveAdmin,
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
