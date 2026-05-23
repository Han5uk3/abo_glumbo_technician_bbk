import 'dart:convert';
import 'dart:developer';
import 'package:aboglumbo_bbk_panel/common_widget/searchable_dropdown.dart';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/booking.dart';
import 'package:aboglumbo_bbk_panel/models/categories.dart';
import 'package:aboglumbo_bbk_panel/models/location_selection.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/widgets/conflict_widgets.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/services/conflict_check_services.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:aboglumbo_bbk_panel/utils/dm_sans_font.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/services.dart';

class AssignUserBottomSheet extends StatefulWidget {
  final BookingModel booking;
  final Function({required BookingModel booking, required UserModel user}) onAssignAgent;
  final Function(BookingModel booking) onRejectOrder;
  final bool isWarranty;

  const AssignUserBottomSheet({
    super.key,
    required this.booking,
    required this.onAssignAgent,
    required this.onRejectOrder,
    this.isWarranty = false,
  });

  @override
  State<AssignUserBottomSheet> createState() => _AssignUserBottomSheetState();
}

class _AssignUserBottomSheetState extends State<AssignUserBottomSheet> {
  late final ConflictCheckService _conflictService;

  List<Region> _regions = [];
  Region? _selectedRegion;
  City? _selectedCity;
  District? _selectedDistrict;
  bool _isDataFullyLoaded = false;

  final ValueNotifier<bool> _isLoadingLocations = ValueNotifier(true);
  final ValueNotifier<bool> _isLoadingCategory = ValueNotifier(true);
  final ValueNotifier<bool> _isAssigning = ValueNotifier(false);

  CategoryModel? _categoryModel;
  final Map<String, CategoryModel> _categoryCache = {};

  Stream<List<UserModel>>? _cachedUsersStream;
  String? _lastLocationKey;

  bool _hasPreloadedConflicts = false;
  List<UserModel>? _lastPreloadedUsers;
  List<String>? _cachedConflictUids;

  @override
  void initState() {
    super.initState();
    _conflictService = ConflictCheckService();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await Future.wait([_loadCategory(), _loadLocations()]);
  }

  @override
  void dispose() {
    _conflictService.dispose();
    _isLoadingLocations.dispose();
    _isLoadingCategory.dispose();
    _isAssigning.dispose();
    super.dispose();
  }

  Future<void> _loadCategory() async {
    _isLoadingCategory.value = true;
    try {
      if (widget.booking.service.category != null) {
        final doc = await AppFirestore.categoriesCollectionRef
            .doc(widget.booking.service.category)
            .get();

        if (doc.exists && mounted) {
          _categoryModel = CategoryModel.fromJson(
            doc.data() as Map<String, dynamic>,
          );
        }
      }
    } catch (e) {
      log('Error loading category: $e');
    } finally {
      if (mounted) _isLoadingCategory.value = false;
    }
  }

  Future<void> _loadLocations() async {
    _isLoadingLocations.value = true;
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/saudi_hierarchical.json',
      );
      final List<dynamic> jsonData = json.decode(jsonString);

      if (mounted) {
        _regions = jsonData.map((r) => Region.fromJson(r)).toList();
      }
    } catch (e) {
      log('Error loading locations: $e');
    } finally {
      if (mounted) _isLoadingLocations.value = false;
    }
  }

  Future<void> _loadCategories(List<String> categoryIds) async {
    if (categoryIds.isEmpty) return;
    final uncachedIds = categoryIds.where((id) => !_categoryCache.containsKey(id)).toList();
    if (uncachedIds.isEmpty) return;
    try {
      final categories = await AppServices.getCategoriesByIds(uncachedIds);
      for (var category in categories) {
        if (category.id != null) _categoryCache[category.id!] = category;
      }
    } catch (e) {
      log('Error loading categories: $e');
    }
  }

  String _getJobRoleNames(List<String>? jobRoleIds, bool isArabic) {
    if (jobRoleIds == null || jobRoleIds.isEmpty) return '';
    return jobRoleIds.map((id) {
          final category = _categoryCache[id];
          if (category == null) return null;
          return isArabic ? category.name_ar : category.name;
        }).where((name) => name != null).join(', ');
  }

  Future<void> _preloadConflictData(List<UserModel> users) async {
    if (!mounted || _conflictService.isCacheValid || _hasPreloadedConflicts) return;
    if (_lastPreloadedUsers != null && _usersAreEqual(_lastPreloadedUsers!, users)) return;

    _hasPreloadedConflicts = true;
    _lastPreloadedUsers = users;

    try {
      final jobRoleIds = users.expand((u) => u.jobRoles ?? []).whereType<String>().toSet().toList();
      await _loadCategories(jobRoleIds);
      if (_cachedConflictUids == null) {
        List<String> conflictUids = [];

        if (widget.isWarranty) {
          final currentBookingDoc = await AppFirestore.bookingsCollectionRef.doc(widget.booking.id).get();
          if (currentBookingDoc.exists) {
            final data = currentBookingDoc.data() as Map<String, dynamic>?;
            final warrantyData = data?['warranty'] as Map<String, dynamic>?;
            final rejectedTechnicians = warrantyData?['rejectedTechnicians'] as List?;
            if (rejectedTechnicians != null) {
              for (var tech in rejectedTechnicians) {
                final uid = tech['uid'] as String?;
                if (uid != null) conflictUids.add(uid);
              }
            }
          }
        } else {
          final currentBookingDoc = await AppFirestore.bookingsCollectionRef.doc(widget.booking.id).get();
          if (currentBookingDoc.exists) {
            final data = currentBookingDoc.data() as Map<String, dynamic>?;
            final uids = data?['cancelledWorkerUids'] as List?;
            if (uids != null) conflictUids.addAll(uids.cast<String>());
          }
        }
        _cachedConflictUids = conflictUids;
      }

      final userIds = users.map((u) => u.uid).whereType<String>().toList();
      await _conflictService.batchCheckConflicts(
        userIds: userIds,
        booking: widget.booking,
        cancelledWorkerUids: _cachedConflictUids!,
      );
    } catch (e) {
      log('Error preloading conflicts: $e');
    } finally {
      if (mounted) setState(() => _isDataFullyLoaded = true);
    }
  }

  bool _usersAreEqual(List<UserModel> list1, List<UserModel> list2) {
    if (list1.length != list2.length) return false;
    final ids1 = list1.map((u) => u.uid).toSet();
    final ids2 = list2.map((u) => u.uid).toSet();
    return ids1.length == ids2.length && ids1.containsAll(ids2);
  }

  Future<void> _handleAssignAgent(UserModel user) async {
    final userId = user.uid;
    if (userId == null) return;
    if (_isAssigning.value) {
      _showSnackBar(AppLocalizations.of(context)!.assignmentInProgress, Colors.orange);
      return;
    }
    _isAssigning.value = true;

    try {
      final conflicts = await _conflictService.batchCheckConflicts(userIds: [userId], booking: widget.booking, cancelledWorkerUids: _cachedConflictUids ?? []);
      final conflictData = conflicts[userId];
      if (conflictData?.hasConflict == true) {
        await _showConflictDialog(user, conflictData!);
        return;
      }

      // Allow admins to reassign/change technician even if already assigned
      // (The check below is removed to support "Change Technician" flow)
      /*
      final currentDoc = await AppFirestore.bookingsCollectionRef.doc(widget.booking.id).get();
      if (currentDoc.exists) {
        final data = currentDoc.data() as Map<String, dynamic>;
        final assignedTo = data['assignedTo'] as String?;
        final status = data['bookingStatusCode'] as String?;
        if (assignedTo != null && assignedTo.isNotEmpty && status != 'P') {
          _showSnackBar(AppLocalizations.of(context)!.thisBookingAlreadyAssignedToAnotherAgent, Colors.red);
          Navigator.pop(context);
          return;
        }
      }
      */

      _conflictService.trackAssignment(userId, widget.booking.bookingDateTime.toDate());
      _conflictService.invalidateCache();
      widget.onAssignAgent(booking: widget.booking, user: user);
      Navigator.pop(context);
    } catch (e) {
      _showSnackBar(AppLocalizations.of(context)!.failedToAssignAgent, Colors.red);
    } finally {
      if (mounted) _isAssigning.value = false;
    }
  }

  Future<void> _showConflictDialog(UserModel user, ConflictData conflictData) async {
    final agentName = user.name ?? AppLocalizations.of(context)?.agent ?? 'Agent';
    if (conflictData.type == ConflictType.workerCancelledThisBooking) {
      await ConflictDialogs.showWorkerCancelledDialog(context, agentName: agentName, conflictTime: conflictData.conflictTime!, conflictDate: conflictData.conflictDate!, isThisBooking: true);
    } else if (conflictData.type == ConflictType.workerCancelled) {
      await ConflictDialogs.showWorkerCancelledDialog(context, agentName: agentName, conflictTime: conflictData.conflictTime!, conflictDate: conflictData.conflictDate!, isThisBooking: false);
    } else {
      await ConflictDialogs.showTimeConflictDialog(context, agentName: agentName, conflictTime: conflictData.conflictTime!, conflictDate: conflictData.conflictDate!);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: DMSansFont.textStyle(color: Colors.white)),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Stream<List<UserModel>> _createUsersStream() {
    final categoryId = widget.booking.service.category;
    if (categoryId != null) return _getCategoryWiseWorkersStream(categoryId);
    return AppFirestore.usersCollectionRef
        .where('isVerified', isEqualTo: true)
        .where('isAdmin', isNotEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => UserModel.fromDocumentSnapshot(doc)).toList());
  }

  Stream<List<UserModel>> _getCategoryWiseWorkersStream(String categoryId) async* {
    try {
      final doc = await AppFirestore.categoriesCollectionRef.doc(categoryId).get();
      if (!doc.exists) { yield []; return; }
      final data = doc.data() as Map<String, dynamic>?;
      final catId = data?['id'] ?? '';
      if (catId.isEmpty) { yield []; return; }
      yield* AppFirestore.usersCollectionRef
          .where('isVerified', isEqualTo: true)
          .where('isAdmin', isNotEqualTo: true)
          .where('jobRoles', arrayContains: catId)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => UserModel.fromDocumentSnapshot(doc)).toList());
    } catch (e) { yield []; }
  }

  Stream<List<UserModel>> _getFilteredUsersStream() {
    final locationKey = '${_selectedRegion?.regionId}_${_selectedCity?.cityId}_${_selectedDistrict?.districtId}';
    if (_cachedUsersStream == null || _lastLocationKey != locationKey) {
      _cachedUsersStream = _createUsersStream();
      _lastLocationKey = locationKey;
      _conflictService.invalidateCache();
      _hasPreloadedConflicts = false;
      _lastPreloadedUsers = null;
      _isDataFullyLoaded = false;
    }
    return _cachedUsersStream!;
  }

  Future<void> _showRejectConfirmationDialog() async {
    _showPremiumDialog(
      title: AppLocalizations.of(context)!.confirmReject,
      message: AppLocalizations.of(context)!.confirmRejectMessage,
      icon: Icons.cancel_outlined,
      iconColor: Colors.red,
      primaryActionLabel: AppLocalizations.of(context)!.reject,
      primaryAction: () {
        widget.onRejectOrder(widget.booking);
        Navigator.pop(context);
      },
      isDanger: true,
    );
  }

  void _showPremiumDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
    required String primaryActionLabel,
    required VoidCallback primaryAction,
    bool isDanger = false,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: DMSansFont.textStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Text(message, style: DMSansFont.textStyle(fontSize: 15, color: Colors.grey[600], height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel, style: DMSansFont.textStyle(fontWeight: FontWeight.w600, color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: primaryAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDanger ? Colors.red : AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(primaryActionLabel, style: DMSansFont.textStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _showLocationFilterDialog() async {
    Region? tempRegion = _selectedRegion;
    City? tempCity = _selectedCity;
    District? tempDistrict = _selectedDistrict;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(AppLocalizations.of(context)!.filterByLocation, style: DMSansFont.textStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSearchableDropdown<Region>(
                  label: AppLocalizations.of(context)!.province,
                  value: tempRegion,
                  items: _regions,
                  itemLabel: (r) => r.getName(LocalStore.getUserlanguage() == 'ar'),
                  onChanged: (r) => setDialogState(() { tempRegion = r; tempCity = null; tempDistrict = null; }),
                  hint: AppLocalizations.of(context)!.typeProvinceNameToSearch,
                ),
                if (tempRegion != null) ...[
                  const SizedBox(height: 16),
                  _buildSearchableDropdown<City>(
                    label: AppLocalizations.of(context)!.city,
                    value: tempCity,
                    items: tempRegion!.cities,
                    itemLabel: (c) => c.getName(LocalStore.getUserlanguage() == 'ar'),
                    onChanged: (c) => setDialogState(() { tempCity = c; tempDistrict = null; }),
                    hint: AppLocalizations.of(context)!.typeCityNameToSearch,
                  ),
                ],
                if (tempCity != null) ...[
                  const SizedBox(height: 16),
                  _buildSearchableDropdown<District>(
                    label: AppLocalizations.of(context)!.neighborhood,
                    value: tempDistrict,
                    items: tempCity!.districts,
                    itemLabel: (d) => d.getName(LocalStore.getUserlanguage() == 'ar'),
                    onChanged: (d) => setDialogState(() { tempDistrict = d; }),
                    hint: AppLocalizations.of(context)!.typeNeighborhoodNameToSearch,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context)!.cancel, style: DMSansFont.textStyle(color: Colors.grey[600], fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: Text(AppLocalizations.of(context)!.apply, style: DMSansFont.textStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {
        _selectedRegion = tempRegion;
        _selectedCity = tempCity;
        _selectedDistrict = tempDistrict;
        _conflictService.invalidateCache();
      });
    }
  }

  Widget _buildSearchableDropdown<T extends Object>({required String label, required T? value, required List<T> items, required String Function(T) itemLabel, required ValueChanged<T?> onChanged, required String hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: DMSansFont.textStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
        const SizedBox(height: 6),
        SearchableDropdown<T>(
          label: "", 
          value: value, 
          items: items, 
          itemLabel: itemLabel, 
          onChanged: onChanged, 
          hintText: hint,
        ),
      ],
    );
  }

  void _clearFilter() {
    setState(() {
      _selectedRegion = null;
      _selectedCity = null;
      _selectedDistrict = null;
      _conflictService.invalidateCache();
      _hasPreloadedConflicts = false;
      _lastPreloadedUsers = null;
      _isDataFullyLoaded = false;
    });
  }

  String _getSelectedLocationText() {
    final isArabic = LocalStore.getUserlanguage() == 'ar';
    final List<String> parts = [];
    if (_selectedDistrict != null) parts.add(_selectedDistrict!.getName(isArabic));
    if (_selectedCity != null) parts.add(_selectedCity!.getName(isArabic));
    if (_selectedRegion != null) parts.add(_selectedRegion!.getName(isArabic));
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopHandle(),
          _buildHeader(),
          _buildLocationSection(),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
          Expanded(child: _buildUserList()),
        ],
      ),
    );
  }

  Widget _buildTopHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: Colors.grey.withOpacity(0.2), borderRadius: BorderRadius.circular(2)),
      ),
    );
  }

  Widget _buildHeader() {
    final isArabic = LocalStore.getUserlanguage() == 'ar';
    final name = isArabic ? _categoryModel?.name_ar : _categoryModel?.name;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name != null ? '${AppLocalizations.of(context)!.assignTo} $name' : AppLocalizations.of(context)!.assignToUser,
                  style: DMSansFont.textStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)!.loadingAgents,
                  style: DMSansFont.textStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _isAssigning,
            builder: (context, assigning, _) => IconButton.filled(
              onPressed: assigning ? null : _showRejectConfirmationDialog,
              icon: const Icon(Icons.close, size: 20),
              style: IconButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.08), foregroundColor: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    final hasFilter = _selectedRegion != null || _selectedCity != null || _selectedDistrict != null;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: _showLocationFilterDialog,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey[50], 
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: hasFilter ? AppColors.primary.withOpacity(0.2) : Colors.grey[100]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on_outlined, color: hasFilter ? AppColors.primary : Colors.grey[600], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      hasFilter ? _getSelectedLocationText() : AppLocalizations.of(context)!.filterByLocation,
                      style: DMSansFont.textStyle(
                        fontSize: 15, 
                        fontWeight: hasFilter ? FontWeight.w600 : FontWeight.w500,
                        color: hasFilter ? AppColors.primary : Colors.grey[700],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasFilter)
                    GestureDetector(
                      onTap: () { _clearFilter(); },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                        child: Icon(Icons.close, size: 14, color: AppColors.primary),
                      ),
                    )
                  else
                    Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<List<UserModel>>(
      stream: _getFilteredUsersStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _buildErrorState(snapshot.error.toString());
        if (!snapshot.hasData) return _buildShimmerList();
        
        final users = snapshot.data!;
        if (users.isEmpty) return _buildEmptyState();

        _preloadConflictData(users);

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          itemCount: users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _buildWorkerTile(users[index]),
        );
      },
    );
  }

  Widget _buildWorkerTile(UserModel user) {
    final conflictData = _conflictService.getConflictData(user.uid ?? '');
    final isArabic = LocalStore.getUserlanguage() == 'ar';
    final roleNames = _getJobRoleNames(user.jobRoles, isArabic);
    
    return InkWell(
      onTap: () => _handleAssignAgent(user),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[100]!),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            _buildAvatar(user),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name ?? '', style: DMSansFont.textStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  if (roleNames.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(roleNames, style: DMSansFont.textStyle(fontSize: 12, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                  if (conflictData != null && conflictData.hasConflict) ...[
                    const SizedBox(height: 6),
                    _buildConflictBadge(conflictData),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(UserModel user) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: user.profileUrl != null && user.profileUrl!.isNotEmpty
            ? Image.network(user.profileUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(user))
            : _buildAvatarPlaceholder(user),
      ),
    );
  }

  Widget _buildAvatarPlaceholder(UserModel user) {
    return Center(child: Text(user.name?.isNotEmpty == true ? user.name![0].toUpperCase() : '?', style: DMSansFont.textStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)));
  }

  Widget _buildConflictBadge(ConflictData data) {
    final isCancelled = data.type == ConflictType.workerCancelled || data.type == ConflictType.workerCancelledThisBooking;
    final color = isCancelled ? Colors.red : Colors.orange;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.15))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isCancelled ? Icons.event_busy : Icons.schedule, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              _getConflictLabel(data),
              style: DMSansFont.textStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _getConflictLabel(ConflictData data) {
    // Add logic to use existing localization keys with fallbacks for missing ones
    if (data.type == ConflictType.workerCancelledThisBooking) return "Worker cancelled this booking";
    if (data.type == ConflictType.workerCancelled) return "Worker cancelled nearby";
    return "Busy at this time";
  }

  Widget _buildShimmerList() {
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[100]!,
        child: Container(height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.noTechniciansFound, style: DMSansFont.textStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context)!.appLoginCaption, style: DMSansFont.textStyle(fontSize: 14, color: Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(error, textAlign: TextAlign.center, style: DMSansFont.textStyle(color: Colors.grey[600])),
            TextButton(
              onPressed: () => setState(() => _cachedUsersStream = null),
              child: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      ),
    );
  }
}
