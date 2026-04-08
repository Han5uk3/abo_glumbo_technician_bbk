import 'package:aboglumbo_bbk_panel/common_widget/booking_cards.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/booking.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:aboglumbo_bbk_panel/pages/bookings/bloc/warranty_bloc.dart';
import 'package:aboglumbo_bbk_panel/sheets/assign_worker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WarrantyPage extends StatefulWidget {
  const WarrantyPage({
    super.key,
    required this.workerData,
    this.isTechnicianView = false,
  });

  final UserModel workerData;
  final bool isTechnicianView;

  @override
  State<WarrantyPage> createState() => _WarrantyPageState();
}

class _WarrantyPageState extends State<WarrantyPage>
    with TickerProviderStateMixin {
  static const List<Map<String, String>> _warrantyStatuses = [
    {'code': 'R', 'name': 'Requested'},
    {'code': 'S', 'name': 'Accepted'},
    {'code': 'C', 'name': 'Completed'},
    {'code': 'X', 'name': 'Rejected'},
    {'code': 'E', 'name': 'Expired'},
  ];

  late TabController _tabController;
  late AnimationController _shimmerController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: _warrantyStatuses.length,
      vsync: this,
      initialIndex: 0,
    );

    _tabController.addListener(() {
      if (_tabController.index != _tabController.previousIndex) {
        setState(() {});
      }
    });

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _shimmerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: Column(
          children: [
            if (!widget.isTechnicianView)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: SearchBar(
                  controller: _searchController,
                  hintText: AppLocalizations.of(context)!.searchByBookingId,
                  leading: const Icon(Icons.search),
                  trailing: _searchQuery.isNotEmpty
                      ? [
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          ),
                        ]
                      : null,
                  padding: const WidgetStatePropertyAll<EdgeInsets>(
                    EdgeInsets.symmetric(horizontal: 16.0),
                  ),
                ),
              ),

            // Filter Chips
            Container(
              height: 64,
              alignment: Alignment.centerLeft,
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: Colors.transparent,
                tabAlignment: TabAlignment.start,
                splashFactory: NoSplash.splashFactory,
                labelPadding: EdgeInsets.zero,
                tabs: List.generate(_warrantyStatuses.length, (index) {
                  final status = _warrantyStatuses[index];
                  final isSelected = _tabController.index == index;
                  return Padding(
                    padding: EdgeInsets.only(
                      left: index == 0 ? 12 : 0,
                      right: index < _warrantyStatuses.length - 1 ? 8 : 12,
                    ),
                    child: _buildStatusChip(
                      context,
                      code: status['code']!,
                      name: status['name']!,
                      isSelected: isSelected,
                      colorScheme: colorScheme,
                      onPressed: () => _tabController.animateTo(index),
                    ),
                  );
                }),
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: List.generate(_warrantyStatuses.length, (index) {
                  return _WarrantyListTab(
                    warrantyStatusCode: _warrantyStatuses[index]['code']!,
                    searchQuery: _searchQuery,
                    isAdmin: widget.workerData.isAdmin ?? false,
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      titleSpacing: 16,
      title: Text(AppLocalizations.of(context)!.warrantyClaims),
      foregroundColor: Colors.black,
      backgroundColor: Colors.white,
      elevation: 0,
      shape: const Border(),
    );
  }

  Widget _buildStatusChip(
    BuildContext context, {
    required String code,
    required String name,
    required bool isSelected,
    required ColorScheme colorScheme,
    required VoidCallback onPressed,
  }) {
    return ActionChip(
      onPressed: onPressed,
      backgroundColor: Colors.white,

      side: BorderSide(
        color: isSelected ? AppColors.primary : Colors.grey.shade600,
        width: isSelected ? 1.5 : 1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      label: Text(
        getLocalizedName(name, context).toUpperCase(),
        style: TextStyle(
          color: isSelected ? AppColors.primary : Colors.grey.shade600,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          fontSize: 14,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    );
  }

  String getLocalizedName(String name, BuildContext context) {
    switch (name.toLowerCase()) {
      case 'requested':
        return AppLocalizations.of(context)!.requested;
      case 'accepted':
        return AppLocalizations.of(context)!.accepted;
      case 'completed':
        return AppLocalizations.of(context)!.completed;
      case 'cancelled':
        return AppLocalizations.of(context)!.cancelled;
      case 'rejected':
        return AppLocalizations.of(context)!.rejected;
      case 'expired':
        return AppLocalizations.of(context)!.expired;
      default:
        return name;
    }
  }
}

class _WarrantyListTab extends StatefulWidget {
  final String warrantyStatusCode;
  final String searchQuery;
  final bool isAdmin;

  const _WarrantyListTab({
    required this.warrantyStatusCode,
    required this.searchQuery,
    required this.isAdmin,
  });

  @override
  State<_WarrantyListTab> createState() => _WarrantyListTabState();
}

class _WarrantyListTabState extends State<_WarrantyListTab> {
  late Stream<List<BookingModel>> _warrantiesStream;

  @override
  void initState() {
    super.initState();
    _warrantiesStream = AppServices.getWarrantiesStream(
      warrantyStatusCode: widget.warrantyStatusCode,
      isAdmin: widget.isAdmin,
    );
  }

  void _showAssignToUserBottomSheet(BookingModel booking) {
    final warrantyBloc = context.read<WarrantyBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return AssignUserBottomSheet(
          booking: booking,
          isWarranty: true, // ← ADD THIS LINE
          onAssignAgent:
              ({required BookingModel booking, required UserModel user}) {
                warrantyBloc.add(
                  AssignWarrantyTechnician(
                    bookingId: booking.id,
                    technician: user,
                  ),
                );
              },
          onRejectOrder: (BookingModel booking) {
            warrantyBloc.add(RejectWarranty(bookingId: booking.id));
          },
        );
      },
    );
  }

  List<BookingModel> _filterWarranties(List<BookingModel> warranties) {
    if (widget.searchQuery.isEmpty) {
      return warranties;
    }

    return warranties.where((warranty) {
      final bookingId = warranty.id.toLowerCase();

      return bookingId.contains(widget.searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BookingModel>>(
      stream: _warrantiesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return _buildLoadingState(context);
        }

        if (snapshot.hasError) {
          return _buildErrorState(context, snapshot.error.toString());
        }

        final allWarranties = snapshot.data ?? [];
        final filteredWarranties = _filterWarranties(allWarranties);

        if (filteredWarranties.isEmpty) {
          return _buildEmptyState(
            context,
            widget.warrantyStatusCode,
            isSearching: widget.searchQuery.isNotEmpty,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: filteredWarranties.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final warranty = filteredWarranties[index];
            return BookingListTileWidget(
              onAssign: () {
                _showAssignToUserBottomSheet(warranty);
              },
              key: ValueKey(warranty.id),
              booking: warranty,
              isWarranty: true,
              isAdmin: widget.isAdmin,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    String selectedWarrantyStatus, {
    bool isSearching = false,
  }) {
    final textTheme = Theme.of(context).textTheme;

    if (isSearching) {
      return Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.8 + (value * 0.2),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off,
                size: 100,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.noresultsfound,
                style: textTheme.labelLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.tryadifferentsearchterm,
                style: textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.8 + (value * 0.2),
            child: Opacity(opacity: value, child: child),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.build_circle_outlined,
              size: 100,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.noWarrantyRequests,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
        highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
        direction: ShimmerDirection.ltr,
        period: const Duration(milliseconds: 1500),
        child: _buildSkeletonCard(context),
      ),
    );
  }

  Widget _buildSkeletonCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 120,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: MediaQuery.of(context).size.width * 0.6,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Opacity(opacity: value, child: child),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error: $error',
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
