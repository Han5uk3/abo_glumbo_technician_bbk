import 'package:aboglumbo_bbk_panel/common_widget/elevated_button.dart';
import 'package:aboglumbo_bbk_panel/models/admin.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/admins/add_admin.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';

class ManageAdmins extends StatefulWidget {
  const ManageAdmins({super.key});

  @override
  State<ManageAdmins> createState() => _ManageAdminsState();
}

class _ManageAdminsState extends State<ManageAdmins>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedFilter = 0; // 0 = All, 1 = Customer Service, 2 = Full Admin
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<bool?> _showRevokeConfirmationDialog({
    required BuildContext context,
    required String adminName,
  }) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.bgWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(AppLocalizations.of(context)?.revokeAccess ?? 'Revoke Access'),
          content: Text(AppLocalizations.of(context)?.confirmRemoveAdmin(adminName) ?? 'Are you sure you want to remove admin access for $adminName?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppLocalizations.of(context)?.cancelLower ?? 'Cancel', style: const TextStyle(color: Colors.grey)),
            ),
            eButton(
              text: 'Revoke',
              onPressed: () => Navigator.of(context).pop(true),
              context: context,
              textColor: Colors.white,
              backgroundColor: Colors.red.shade600,
            ),
          ],
        );
      },
    );
  }

  Future<void> _revokeAdminAccess(AdminModel admin) async {
    if (admin.isSuperAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)?.coreAdminCannotRemove ?? 'Core admin cannot be removed.'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      await AppFirestore.adminsCollectionRef.doc(admin.uid).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)?.adminAccessRevoked(admin.name) ?? 'Admin access revoked for ${admin.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)?.errorOccurred(e.toString()) ?? 'Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deletePendingInvite(AdminModel admin) async {
     try {
      await AppFirestore.pendingAdminsCollectionRef.doc(admin.uid).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)?.inviteDeleted(admin.name) ?? 'Invite deleted for ${admin.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)?.errorOccurred(e.toString()) ?? 'Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
        ),
        title: const Text(
          'Manage Admins',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        shape: Border.all(style: BorderStyle.none),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) =>
                    setState(() => _searchQuery = value.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search admins...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),

          // Filter Chips
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(0, 'All', Icons.apps_rounded),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                      1, 'Customer Service', Icons.support_agent_rounded),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                      2, 'Full Admin', Icons.admin_panel_settings_rounded),
                ],
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<List<AdminModel>>(
              stream: Rx.combineLatest2(
                AppServices.getAdminsStream(),
                AppServices.getPendingAdminsStream(),
                (List<AdminModel> active, List<AdminModel> pending) {
                  // Mark pending admins as pending for UI
                  final pWithFlag = pending
                      .map((e) => e.copyWith(uid: 'pending_${e.uid}'))
                      .toList();
                  return [...active, ...pWithFlag];
                },
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text(AppLocalizations.of(context)?.noAdminsFound ?? 'No admins found.'));
                }

                final allAdmins = snapshot.data!.where((admin) {
                  final matchesSearch =
                      admin.name.toLowerCase().contains(_searchQuery) ||
                          admin.phoneNumber.contains(_searchQuery) ||
                          admin.email.toLowerCase().contains(_searchQuery);

                  final effectiveAccessLevel = admin.hasFullAccess ? 2 : 1;
                  final matchesFilter =
                      _selectedFilter == 0 || effectiveAccessLevel == _selectedFilter;

                  return matchesSearch && matchesFilter;
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  itemCount: allAdmins.length,
                  itemBuilder: (context, index) {
                    final admin = allAdmins[index];
                    final isPending =
                        admin.uid?.startsWith('pending_') ?? false;
                    return _buildAdminCard(admin, isPending);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => const AddAdminPage())),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterChip(int index, String label, IconData icon) {
    final isSelected = _selectedFilter == index;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.black.withOpacity(0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primary : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard(AdminModel admin, bool isPending) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    admin.name.isNotEmpty ? admin.name[0].toUpperCase() : 'A',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              admin.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isPending)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6)),
                              child: Text(AppLocalizations.of(context)?.invited ?? 'INVITED',
                                  style: const TextStyle(
                                      color: Colors.orange,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      Text(
                        admin.email,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context)?.accessLevelUpper ?? 'ACCESS LEVEL',
                          style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        admin.isSuperAdmin
                            ? 'Core Admin'
                            : (admin.hasFullAccess ? 'Full Admin' : 'Customer Service'),
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context)?.phoneUpper ?? 'PHONE',
                          style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        admin.phoneNumber,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                if (!admin.isSuperAdmin)
                  IconButton(
                    onPressed: () async {
                      final confirm = await _showRevokeConfirmationDialog(
                          context: context, adminName: admin.name);
                      if (confirm == true) {
                        if (isPending) {
                          final actualId =
                              admin.uid!.replaceFirst('pending_', '');
                          await _deletePendingInvite(
                              admin.copyWith(uid: actualId));
                        } else {
                          await _revokeAdminAccess(admin);
                        }
                      }
                    },
                    icon: Icon(Icons.delete_outline_rounded,
                        color: Colors.red.shade400, size: 20),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
