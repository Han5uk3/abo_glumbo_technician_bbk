import 'package:aboglumbo_bbk_panel/common_widget/booking_cards.dart';
import 'package:aboglumbo_bbk_panel/helpers/localization_helper.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/booking.dart';

import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:aboglumbo_bbk_panel/utils/dm_sans_font.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shimmer/shimmer.dart';

class WorkerHome extends StatefulWidget {
  final String? selectedIndex;
  const WorkerHome({super.key, this.selectedIndex});

  @override
  State<WorkerHome> createState() => _WorkerHomeState();
}

class _WorkerHomeState extends State<WorkerHome> with TickerProviderStateMixin {
  static const List<Map<String, String>> _bookingStatuses = [
    {'code': 'P', 'name': 'Pending'},
    {'code': 'A', 'name': 'Accepted'},
    {'code': 'CP', 'name': 'Payment Pending'},
    {'code': 'C', 'name': 'Completed'},
    {'code': 'X', 'name': 'Cancelled'},
    {'code': 'R', 'name': 'Rejected'},
  ];
  late TabController _tabController;

  late AnimationController _shimmerController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    final initialIndex = _bookingStatuses.indexWhere(
      (e) => e['code'] == (widget.selectedIndex ?? 'P'),
    );
    _tabController = TabController(
      length: _bookingStatuses.length,
      vsync: this,
      initialIndex: initialIndex == -1 ? 0 : initialIndex,
    );

    // Fixed listener - rebuild on ANY index change
    _tabController.addListener(() {
      if (!mounted) return;
      if (!_tabController.indexIsChanging) {
        setState(() {}); // build for check mark UI update
      }
    });
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Search listener
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void didUpdateWidget(covariant WorkerHome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex &&
        widget.selectedIndex != null) {
      final newIndex = _bookingStatuses.indexWhere(
        (e) => e['code'] == widget.selectedIndex,
      );
      if (newIndex != -1 && newIndex != _tabController.index) {
        _tabController.animateTo(newIndex);
      }
    }
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
            // Search bar removed for technician view as per request
            Container(
              height: 64,
              alignment: AlignmentDirectional.centerStart,
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: Colors.transparent,
                tabAlignment: TabAlignment.start,
                splashFactory: NoSplash.splashFactory,
                labelPadding: EdgeInsets.zero,
                tabs: List.generate(_bookingStatuses.length, (index) {
                  final status = _bookingStatuses[index];
                  final isSelected = _tabController.index == index;
                  return Padding(
                    padding: EdgeInsets.only(
                      left: index == 0 ? 12 : 0,
                      right: index < _bookingStatuses.length - 1 ? 8 : 12,
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
                children: List.generate(_bookingStatuses.length, (index) {
                  return _BookingListTab(
                    bookingStatusCode: _bookingStatuses[index]['code']!,
                    searchQuery: _searchQuery,
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
      centerTitle: true,
      backgroundColor: Colors.white,
      elevation: 0,
      title: Text(
        AppLocalizations.of(context)?.orders ?? "Manage Orders",
        style: DMSansFont.textStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      shape: Border.all(style: BorderStyle.none),
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
        LocalizationHelper()
            .localizedBookingStatus(name, context: context)
            .toUpperCase(),
        style: TextStyle(
          color: isSelected ? AppColors.primary : Colors.grey.shade600,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          fontSize: 14,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    );
  }
}

class _BookingListTab extends StatefulWidget {
  final String bookingStatusCode;
  final String searchQuery;

  const _BookingListTab({
    required this.bookingStatusCode,
    required this.searchQuery,
  });

  @override
  State<_BookingListTab> createState() => _BookingListTabState();
}

class _BookingListTabState extends State<_BookingListTab>
    with AutomaticKeepAliveClientMixin {
  late Stream<List<dynamic>> _bookingsStream;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.bookingStatusCode == 'P') {
      // Combine job offers and pending bookings for the 'Pending' tab
      final offers = AppServices.getJobOffersStream();
      final bookings = AppServices.getBookingsStream(bookingStatusCode: 'P');

      _bookingsStream = Rx.combineLatest2(
        offers,
        bookings,
        (List<JobOfferContainer> o, List<BookingModel> b) => [...o, ...b],
      ).cast<List<dynamic>>();
    } else {
      _bookingsStream = AppServices.getBookingsStream(
        bookingStatusCode: widget.bookingStatusCode,
      ).cast<List<dynamic>>();
    }
  }

  List<dynamic> _filterData(List<dynamic> data) {
    // 1. Remove duplicates by Booking ID to avoid UI ghosting
    // Even if multiple offer documents were created, we only want one card per booking.
    final Map<String, dynamic> uniqueMap = {};
    for (var item in data) {
      if (item is BookingModel) {
        uniqueMap[item.id] = item;
      }
    }
    for (var item in data) {
      if (item is JobOfferContainer) {
        final id = item.booking?.id ?? item.requestId ?? item.offerId;
        uniqueMap[id] = item;
      }
    }
    final List<dynamic> uniqueData = uniqueMap.values.toList();

    if (widget.searchQuery.isEmpty) {
      return uniqueData;
    }

    return uniqueData.where((item) {
      String id = '';
      String newId = '';
      if (item is BookingModel) {
        id = item.id.toLowerCase();
        newId = (item.newBookingId ?? '').toLowerCase();
      } else if (item is JobOfferContainer) {
        id = (item.booking?.id ?? item.requestId ?? '').toLowerCase();
        newId = (item.booking?.newBookingId ?? '').toLowerCase();
      }
      return id.contains(widget.searchQuery) || (newId.isNotEmpty && newId.contains(widget.searchQuery));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return StreamBuilder<List<dynamic>>(
      stream: _bookingsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return _buildLoadingState(context);
        }

        if (snapshot.hasError) {
          return _buildErrorState(context, snapshot.error.toString());
        }

        final allData = snapshot.data ?? [];
        final filteredData = _filterData(allData);

        if (filteredData.isEmpty) {
          return _buildEmptyState(
            context,
            widget.bookingStatusCode,
            isSearching: widget.searchQuery.isNotEmpty,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 120),
          itemCount: filteredData.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = filteredData[index];
            if (item is JobOfferContainer) {
              return JobOfferTileWidget(
                key: ValueKey(item.offerId),
                offer: item,
              );
            } else if (item is BookingModel) {
              return BookingListTileWidget(
                key: ValueKey(item.id),
                booking: item,
                isFromOffersTab: widget.bookingStatusCode == 'P',
              );
            }
            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    String selectedBookingStatus, {
    bool isSearching = false,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final localizations = AppLocalizations.of(context);

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
              Icon(Icons.search_off, size: 100, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                localizations?.noBookingsFound ?? 'No results found',
                style: textTheme.labelLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                localizations?.tryAdjustingYourSearchCriteria ??
                    'Try a different search term',
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
            Icon(Icons.hourglass_empty, size: 100, color: Colors.grey),
            const SizedBox(height: 12),
            Text(localizations!.noBookings, textAlign: TextAlign.center),
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
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 80,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              Container(
                width: 100,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ],
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
