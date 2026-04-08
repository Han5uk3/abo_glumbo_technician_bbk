import 'dart:developer';

import 'package:aboglumbo_bbk_panel/common_widget/elevated_button.dart';
import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/bloc/manage_app_bloc.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/customers/customer_management.dart';
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
    final theme = Theme.of(context);

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
        backgroundColor: AppColors.bgWhite,
        appBar: AppBar(
          title: Text(
            AppLocalizations.of(context)!.manageCustomers,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          elevation: 0,
          centerTitle: false,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () {
                setState(() {});
              },
              tooltip: AppLocalizations.of(context)!.refresh,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // Header gradient section
            Column(
              children: [
                // Modern Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Hero(
                    tag: 'search_bar',
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
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
                              color: Colors.grey.shade600,
                              fontSize: 15,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: theme.colorScheme.primary,
                              size: 24,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear_rounded,
                                      color: Colors.grey.shade600,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                        _searchQuery = '';
                                      });
                                    },
                                    tooltip: AppLocalizations.of(
                                      context,
                                    )!.clear,
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Enhanced Filter Chips
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          context: context,
                          label: AppLocalizations.of(context)!.all,
                          icon: Icons.apps_rounded,
                          isSelected: _selectedFilter == 0,
                          onTap: () => setState(() => _selectedFilter = 0),
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        _buildFilterChip(
                          context: context,
                          label: AppLocalizations.of(context)!.active,
                          icon: Icons.check_circle_rounded,
                          isSelected: _selectedFilter == 1,
                          onTap: () => setState(() => _selectedFilter = 1),
                          color: Colors.green,
                        ),
                        const SizedBox(width: 10),
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
              ],
            ),

            // Customers List
            Expanded(
              child: StreamBuilder(
                stream: AppServices.getAllCustomersStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 24, child: Loader()),
                          const SizedBox(height: 24),
                          Text(
                            AppLocalizations.of(context)!.loadingCustomers,
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return _buildEmptyState(
                      context: context,
                      icon: Icons.error_outline_rounded,
                      title: AppLocalizations.of(context)!.error,
                      subtitle: '${snapshot.error}',
                      color: theme.colorScheme.error,
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState(
                      context: context,
                      icon: Icons.people_outline_rounded,
                      title: AppLocalizations.of(context)!.noCustomersFound,
                      subtitle: AppLocalizations.of(context)!.noCustomersFound,
                      color: theme.colorScheme.primary,
                    );
                  }

                  final customers = snapshot.data!;

                  // Apply filters
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
                      color: theme.colorScheme.primary,
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(
                      top: 16,
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
        floatingActionButton: ScaleTransition(
          scale: _fabAnimation,
          child: FloatingActionButton.extended(
            onPressed: () {
              setState(() {
                _searchController.clear();
                _searchQuery = '';
                _selectedFilter = 0;
              });
            },
            backgroundColor: theme.colorScheme.primaryContainer,
            foregroundColor: theme.colorScheme.onPrimaryContainer,
            elevation: 4,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(
              AppLocalizations.of(context)!.resetFilters,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerCard({
    required BuildContext context,
    required customer,
    required int index,
  }) {
    final theme = Theme.of(context);
    final isBlocked = customer.isBlocked ?? false;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Material(
          elevation: 3,
          shadowColor: isBlocked
              ? Colors.red.withOpacity(0.2)
              : Colors.black.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => CustomerInfo(customer: customer),
              ),
            ),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Enhanced Avatar

                    // Customer Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  customer.name ?? 'Unknown',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isBlocked
                                        ? [
                                            Colors.red.shade400,
                                            Colors.red.shade600,
                                          ]
                                        : [
                                            Colors.green.shade400,
                                            Colors.green.shade600,
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          (isBlocked
                                                  ? Colors.red
                                                  : Colors.green)
                                              .withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isBlocked
                                          ? Icons.block_rounded
                                          : Icons.check_circle_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isBlocked
                                          ? AppLocalizations.of(
                                              context,
                                            )!.blocked
                                          : AppLocalizations.of(
                                              context,
                                            )!.active,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (customer.email != null &&
                              customer.email!.isNotEmpty)
                            _buildInfoRow(
                              context: context,
                              icon: Icons.email_outlined,
                              text: customer.email!,
                            ),
                          if (customer.phone != null &&
                              customer.phone!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
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

                    // Enhanced Toggle Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
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
                              CustomerBlockUnblockEvent(
                                customer.uid,
                                !isBlocked,
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isBlocked
                                  ? [
                                      Colors.green.shade400,
                                      Colors.green.shade600,
                                    ]
                                  : [Colors.red.shade400, Colors.red.shade600],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: (isBlocked ? Colors.green : Colors.red)
                                    .withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            isBlocked
                                ? Icons.check_circle_rounded
                                : Icons.block_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
