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

  const AddAdminPage({super.key, this.adminToEdit, this.isPending = false});

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
    if (widget.adminToEdit == null)
      return AppLocalizations.of(context)?.addAdmin ?? 'Add Admin';
    return AppLocalizations.of(context)?.saveChanges ?? 'Save Changes';
  }

  String get _pageTitle {
    if (widget.adminToEdit == null)
      return AppLocalizations.of(context)?.addNewAdmin ?? 'Add New Admin';
    return AppLocalizations.of(context)?.editAdmin ?? 'Edit Admin';
  }

  String get _pageSubtitle {
    if (widget.adminToEdit == null) {
      return AppLocalizations.of(context)?.enterAdminDetails ??
          'Enter admin details to invite them to the platform.';
    }
    return AppLocalizations.of(context)?.editAdminDetails ??
        'Edit admin details and access level.';
  }

  String get _successMessage {
    if (widget.adminToEdit == null) {
      return AppLocalizations.of(context)?.adminAddedSuccessfully ??
          'Admin added successfully to pending invites.';
    }
    return AppLocalizations.of(context)?.adminUpdatedSuccessfully ??
        'Admin updated successfully.';
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
          content: Text(
            AppLocalizations.of(context)?.onlyCoreAdminCanAdd ??
                'Only the core admin can add new admins.',
          ),
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
      if (widget.adminToEdit == null ||
          phone != widget.adminToEdit!.phoneNumber) {
        final activeCheck = await AppFirestore.adminsCollectionRef
            .where('phoneNumber', isEqualTo: phone)
            .get();

        for (var doc in activeCheck.docs) {
          if (widget.adminToEdit == null ||
              doc.id != widget.adminToEdit!.uid ||
              widget.isPending) {
            throw AppLocalizations.of(context)?.adminPhoneExists ??
                'Admin with this phone number already exists.';
          }
        }

        final pendingCheck = await AppFirestore.pendingAdminsCollectionRef
            .where('phoneNumber', isEqualTo: phone)
            .get();

        for (var doc in pendingCheck.docs) {
          if (widget.adminToEdit == null ||
              doc.id != widget.adminToEdit!.uid ||
              !widget.isPending) {
            throw AppLocalizations.of(context)?.adminPhoneInvited ??
                'Admin with this phone number is already invited.';
          }
        }
      }

      if (widget.adminToEdit != null) {
        // Edit mode
        if (widget.isPending) {
          await AppFirestore.pendingAdminsCollectionRef
              .doc(widget.adminToEdit!.uid)
              .update({
                'name': _nameController.text.trim(),
                'email': _emailController.text.trim(),
                'phoneNumber': phone,
                'accessLevel': _accessLevel,
              });
        } else {
          await AppFirestore.adminsCollectionRef
              .doc(widget.adminToEdit!.uid)
              .update({
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
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.errorOccurred(e.toString()) ??
                  'Error: $e',
            ),
            backgroundColor: Colors.red,
          ),
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
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _pageTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormWidget(
                controller: _nameController,
                label: AppLocalizations.of(context)?.fullName ?? 'Full Name',
                hintText:
                    AppLocalizations.of(context)?.enterFullName ??
                    'Enter full name',
                validator: (v) => v == null || v.isEmpty
                    ? (AppLocalizations.of(context)?.pleaseEnterName ??
                          'Please enter name')
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormWidget(
                controller: _emailController,
                label:
                    AppLocalizations.of(context)?.emailAddress ??
                    'Email Address',
                hintText:
                    AppLocalizations.of(context)?.enterEmailAddress ??
                    'Enter email address',
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v == null || !v.contains('@')
                    ? (AppLocalizations.of(context)?.pleaseEnterValidEmail ??
                          'Please enter a valid email')
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormWidget(
                controller: _phoneController,
                label:
                    AppLocalizations.of(context)?.phoneNumber ?? 'Phone Number',
                hintText:
                    AppLocalizations.of(context)?.egPhoneNumber ??
                    'e.g. +9665XXXXXXXXX',
                isPhoneNumber: true,
                validator: (v) => v == null || v.isEmpty
                    ? (AppLocalizations.of(context)?.pleaseEnterPhoneNumber ??
                          'Please enter phone number')
                    : null,
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)?.phoneNoteWithCountryCode ??
                    '(enter phone number along with country code example : +966)',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)?.accessLevelTitle ??
                    'Access Level',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildAccessLevelOption(
                value: 1,
                title:
                    AppLocalizations.of(context)?.customerServiceOnly ??
                    'Customer Service Only',
                subtitle:
                    AppLocalizations.of(context)?.customerServiceDesc ??
                    'View only access to bookings and manage sections.',
              ),
              _buildAccessLevelOption(
                value: 2,
                title:
                    AppLocalizations.of(context)?.fullAdminAccess ??
                    'Full Admin Access',
                subtitle:
                    AppLocalizations.of(context)?.fullAdminDesc ??
                    'Full access except management of other admins.',
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: _isLoading
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
