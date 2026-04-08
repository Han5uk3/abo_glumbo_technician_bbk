import 'package:aboglumbo_bbk_panel/common_widget/elevated_button.dart';
import 'package:aboglumbo_bbk_panel/models/admin.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/admins/add_admin.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

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
          title: const Text('Revoke Access'),
          content: Text('Are you sure you want to remove admin access for $adminName?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
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
    if (admin.isCoreAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Core admin cannot be removed.'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      await AppFirestore.adminsCollectionRef.doc(admin.uid).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Admin access revoked for ${admin.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deletePendingInvite(AdminModel admin) async {
     try {
      await AppFirestore.pendingAdminsCollectionRef.doc(admin.uid).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invite deleted for ${admin.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      appBar: AppBar(
        title: const Text('Manage Admins', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search admins...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip(0, 'All', Icons.apps),
                const SizedBox(width: 8),
                _buildFilterChip(1, 'Customer Service', Icons.support_agent),
                const SizedBox(width: 8),
                _buildFilterChip(2, 'Full Admin', Icons.admin_panel_settings),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<List<AdminModel>>(
              stream: Rx.combineLatest2(
                AppServices.getAdminsStream(),
                AppServices.getPendingAdminsStream(),
                (List<AdminModel> active, List<AdminModel> pending) {
                  // Mark pending admins as pending for UI
                  final pWithFlag = pending.map((e) => e.copyWith(uid: 'pending_${e.uid}')).toList();
                  return [...active, ...pWithFlag];
                },
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No admins found.'));
                }

                final allAdmins = snapshot.data!.where((admin) {
                  final matchesSearch = admin.name.toLowerCase().contains(_searchQuery) || 
                                      admin.phoneNumber.contains(_searchQuery) ||
                                      admin.email.toLowerCase().contains(_searchQuery);
                  
                  final matchesFilter = _selectedFilter == 0 || admin.accessLevel == _selectedFilter;
                  
                  return matchesSearch && matchesFilter;
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: allAdmins.length,
                  itemBuilder: (context, index) {
                    final admin = allAdmins[index];
                    final isPending = admin.uid?.startsWith('pending_') ?? false;
                    return _buildAdminCard(admin, isPending);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddAdminPage())),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Add Admin'),
        ),
      ),
    );
  }

  Widget _buildFilterChip(int index, String label, IconData icon) {
    final isSelected = _selectedFilter == index;
    return FilterChip(
      selected: isSelected,
      onSelected: (val) => setState(() => _selectedFilter = index),
      label: Text(label),
      avatar: Icon(icon, size: 18, color: isSelected ? AppColors.primary : Colors.grey),
      selectedColor: AppColors.primary.withOpacity(0.1),
      checkmarkColor: AppColors.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? AppColors.primary : Colors.grey.shade300),
      ),
    );
  }

  Widget _buildAdminCard(AdminModel admin, bool isPending) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(admin.name.isNotEmpty ? admin.name[0].toUpperCase() : 'A', style: TextStyle(color: AppColors.primary)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(admin.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(admin.email, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                ),
                if (isPending)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Text('Invited', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Access Level', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(admin.accessLevel == 2 ? 'Full Admin' : 'Customer Service', style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Phone', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(admin.phoneNumber, style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
                if (!admin.isCoreAdmin)
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                    onPressed: () async {
                      final confirm = await _showRevokeConfirmationDialog(context: context, adminName: admin.name);
                      if (confirm == true) {
                        if (isPending) {
                          final actualId = admin.uid!.replaceFirst('pending_', '');
                          await _deletePendingInvite(admin.copyWith(uid: actualId));
                        } else {
                          await _revokeAdminAccess(admin);
                        }
                      }
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
