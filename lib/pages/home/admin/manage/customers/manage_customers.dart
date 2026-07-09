import 'dart:developer';

import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/common_widget/elevated_button.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/bloc/manage_app_bloc.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/customers/customer_management.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/widgets/shimmer_loading.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ManageCustomersPage extends StatefulWidget {
  const ManageCustomersPage({super.key});

  @override
  State<ManageCustomersPage> createState() => _ManageCustomersPageState();
}

class _ManageCustomersPageState extends State<ManageCustomersPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedFilter = 0;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  late Stream<List<dynamic>> _customersStream;

  @override
  void initState() {
    super.initState();
    _customersStream = AppServices.getAllCustomersStream();
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

  Future<bool?> _showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    required bool isBlocking,
  }) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: AlertDialog(
                backgroundColor: AppColors.bgWhite,
                actionsAlignment: MainAxisAlignment.start,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isBlocking
                              ? [Colors.red.shade400, Colors.red.shade600]
                              : [Colors.green.shade400, Colors.green.shade600],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (isBlocking ? Colors.red : Colors.green)
                                .withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        isBlocking
                            ? Icons.block_rounded
                            : Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                content: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    message,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ),
                actions: [
                  eButton(
                    text: AppLocalizations.of(context)!.cancel,
                    onPressed: () => Navigator.of(context).pop(false),
                    context: context,
                    textColor: Colors.black,
                    backgroundColor: AppColors.bgWhite,
                  ),
                  eButton(
                    text: AppLocalizations.of(context)!.confirm,
                    onPressed: () => Navigator.of(context).pop(true),
                    context: context,
                    textColor: Colors.white,
                    backgroundColor: isBlocking
                        ? Colors.red.shade600
                        : Colors.green.shade600,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ManageAppBloc, ManageAppState>(
      listener: (context, state) {
        if (state is BlockUnblockCustomer) {
          log('state.isBlocked=${state.isBlocked}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    state.isBlocked
                        ? Icons.block_rounded
                        : Icons.check_circle_rounded,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      state.isBlocked
                          ? AppLocalizations.of(
                              context,
                            )!.customerBlockedSuccessfully
                          : AppLocalizations.of(
                              context,
                            )!.customerUnblockedSuccessfully,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              duration: const Duration(seconds: 3),
              backgroundColor: state.isBlocked
                  ? Colors.red.shade600
                  : Colors.green.shade600,

              elevation: 6,
            ),
          );
        } else if (state is BlockUnblockCustomerError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${AppLocalizations.of(context)!.error}: ${state.error}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.red.shade600,

              elevation: 6,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.white,
          scrolledUnderElevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.black,
              size: 20,
            ),
          ),
          title: Text(
            AppLocalizations.of(context)!.manageCustomers,
            style: const TextStyle(
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
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(
                      context,
                    )!.searchByCustomerName,
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear_rounded,
                              color: Colors.grey.shade400,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
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
                physics: const ClampingScrollPhysics(),
                child: Wrap(
                  spacing: 8.0,
                  children: [
                    _buildFilterChip(
                      context: context,
                      label: AppLocalizations.of(context)!.all,
                      icon: Icons.apps_rounded,
                      isSelected: _selectedFilter == 0,
                      onTap: () => setState(() => _selectedFilter = 0),
                      color: AppColors.primary,
                    ),
                    _buildFilterChip(
                      context: context,
                      label: AppLocalizations.of(context)!.active,
                      icon: Icons.check_circle_rounded,
                      isSelected: _selectedFilter == 1,
                      onTap: () => setState(() => _selectedFilter = 1),
                      color: Colors.green,
                    ),
                    _buildFilterChip(
                      context: context,
                      label: AppLocalizations.of(context)!.blocked,
                      icon: Icons.block_rounded,
                      isSelected: _selectedFilter == 2,
                      onTap: () => setState(() => _selectedFilter = 2),
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            ),

            // Customers List
            Expanded(
              child: StreamBuilder(
                stream: _customersStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const ManageShimmerLoading();
                  }

                  if (snapshot.hasError) {
                    return _buildEmptyState(
                      context: context,
                      icon: Icons.error_outline_rounded,
                      title: AppLocalizations.of(context)!.error,
                      subtitle: '${snapshot.error}',
                      color: Colors.red,
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState(
                      context: context,
                      icon: Icons.people_outline_rounded,
                      title: AppLocalizations.of(context)!.noCustomersFound,
                      subtitle: AppLocalizations.of(context)!.noCustomersFound,
                      color: AppColors.primary,
                    );
                  }

                  final customers = snapshot.data!;
                  final filteredCustomers = customers.where((customer) {
                    bool matchesSearch = true;
                    if (_searchQuery.isNotEmpty) {
                      final name = (customer.name ?? '').toLowerCase();
                      final email = (customer.email ?? '').toLowerCase();
                      final phone = (customer.phone ?? '').toLowerCase();
                      matchesSearch =
                          name.contains(_searchQuery) ||
                          email.contains(_searchQuery) ||
                          phone.contains(_searchQuery);
                    }

                    bool matchesBlockStatus = true;
                    final isBlocked = customer.isBlocked ?? false;
                    if (_selectedFilter == 1) {
                      matchesBlockStatus = !isBlocked;
                    } else if (_selectedFilter == 2) {
                      matchesBlockStatus = isBlocked;
                    }
                    return matchesSearch && matchesBlockStatus;
                  }).toList();

                  if (filteredCustomers.isEmpty) {
                    return _buildEmptyState(
                      context: context,
                      icon: Icons.search_off_rounded,
                      title: AppLocalizations.of(
                        context,
                      )!.noCustomersMatchYourSearch,
                      subtitle: AppLocalizations.of(
                        context,
                      )!.tryAdjustingYourSearchCriteria,
                      color: AppColors.primary,
                    );
                  }

                  return ListView.builder(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.only(
                      top: 4,
                      bottom: 100,
                      left: 16,
                      right: 16,
                    ),
                    itemCount: filteredCustomers.length,
                    itemBuilder: (context, index) {
                      return _buildCustomerCard(
                        context: context,
                        customer: filteredCustomers[index],
                        index: index,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.black.withOpacity(0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? color : Colors.grey),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard({
    required BuildContext context,
    required customer,
    required int index,
  }) {
    final isBlocked = customer.isBlocked ?? false;

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
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CustomerInfo(customer: customer),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            customer.name ?? 'Unknown',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: (isBlocked ? Colors.red : Colors.green)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            (isBlocked
                                    ? AppLocalizations.of(context)!.blocked
                                    : AppLocalizations.of(context)!.active)
                                .toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isBlocked ? Colors.red : Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (customer.email != null && customer.email!.isNotEmpty)
                      _buildInfoRow(
                        context: context,
                        icon: Icons.email_outlined,
                        text: customer.email!,
                      ),
                    if (customer.phone != null && customer.phone!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: _buildInfoRow(
                          isPhone: true,
                          context: context,
                          icon: Icons.phone_outlined,
                          text: customer.phone!,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (LocalStore.getCachedAdminData()?.hasFullAccess ?? true)
                IconButton(
                  onPressed: () async {
                    final confirmed = await _showConfirmationDialog(
                      context: context,
                      title: isBlocked
                          ? AppLocalizations.of(context)!.unblockCustomer
                          : AppLocalizations.of(context)!.blockCustomer,
                      message: isBlocked
                          ? AppLocalizations.of(
                              context,
                            )!.areYouSureYouWantToUnBlockThisCustomer
                          : AppLocalizations.of(
                              context,
                            )!.areYouSureYouWantToBlockThisCustomer,
                      isBlocking: !isBlocked,
                    );

                    if (confirmed == true && context.mounted) {
                      context.read<ManageAppBloc>().add(
                        CustomerBlockUnblockEvent(customer.uid, !isBlocked),
                      );
                    }
                  },
                  icon: Icon(
                    isBlocked
                        ? Icons.check_circle_outline
                        : Icons.block_rounded,
                    color: isBlocked ? Colors.green : Colors.red,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required IconData icon,
    required String text,
    bool isPhone = false,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: isPhone
              ? Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    textAlign: Directionality.of(context) == TextDirection.rtl
                        ? TextAlign.right
                        : TextAlign.left,
                    text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              : Text(
                  text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: color),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
