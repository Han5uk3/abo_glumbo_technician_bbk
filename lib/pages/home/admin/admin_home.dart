import 'package:aboglumbo_bbk_panel/common_widget/booking_cards.dart';
import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/common_widget/period_selector.dart';
import 'package:aboglumbo_bbk_panel/helpers/localization_helper.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/booking.dart';
import 'package:aboglumbo_bbk_panel/models/categories.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/pages/account/bloc/account_bloc.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/bloc/admin_bloc.dart';
import 'package:aboglumbo_bbk_panel/pages/notifications/notifications_page.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/sheets/assign_worker.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' show DateFormat;

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> with TickerProviderStateMixin {
  final List<Map<String, String>> bookingStatus = [
    {'code': 'P', 'name': 'Pending'},
    {'code': 'A', 'name': 'Accepted'},
    {'code': 'CP', 'name': 'Payment Pending'},
    {'code': 'C', 'name': 'Completed'},
    {'code': 'X', 'name': 'Cancelled'},
  ];

  late TabController _tabController;

  CategoryModel? cat;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> _selectDateRange(BuildContext context) async {
    final result = await showDialog<DateTimeRange>(
      context: context,
      builder: (context) => const HorizontalDateRangePicker(),
    );

    if (result != null) {
      setState(() {
        _startDate = result.start;
        _endDate = result.end;
      });
    }
  }

  showAssignToUserBottomSheet(BookingModel booking) {
    final adminBloc = context.read<AdminBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return AssignUserBottomSheet(
          booking: booking,
          onAssignAgent:
              ({required BookingModel booking, required UserModel user}) {
                adminBloc.add(AssignAgentEvent(booking: booking, user: user));
              },
          onRejectOrder: (BookingModel booking) {
            adminBloc.add(RejectOrderEvent(booking: booking));
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: bookingStatus.length,
      vsync: this,
      initialIndex: 0,
    );

    // Add listener to rebuild on tab change
    _tabController.addListener(() {
      if (_tabController.index != _tabController.previousIndex) {
        setState(() {}); // rebuild to update check mark UI
      }
    });

    // Search listener
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });

    context.read<AccountBloc>().add(LoadDistrictsEvent());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<AdminBloc, AdminState>(
      listener: (context, state) {
        if (state is AgentAssigned) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)?.agentAssignedSuccessfully ??
                    'Technician assigned successfully',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else if (state is AgentAssignmentError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${AppLocalizations.of(context)?.failedToAssignAgent ?? 'Failed to assign technician'}: ${state.error}',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        } else if (state is OrderRejected) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)?.orderRejectedSuccessfully ??
                    'Order rejected successfully',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        } else if (state is OrderRejectionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${AppLocalizations.of(context)?.failedToRejectOrder ?? 'Failed to reject order'}: ${state.error}',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      child: BlocBuilder<AccountBloc, AccountState>(
        builder: (context, accountState) {
          return Scaffold(
            appBar: AppBar(
              titleSpacing: 16,
              title: Text(
                AppLocalizations.of(context)?.manageOrders ?? "Manage Orders",
              ),
              elevation: 0,
              shape: Border.all(style: BorderStyle.none),
              actions: [
                StreamBuilder<int>(
                  stream: AppServices.getUnreadNotificationsCountStream(),
                  builder: (context, snapshot) {
                    final unreadCount = snapshot.data ?? 0;
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_none_rounded, color: Colors.black, size: 24),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NewNotificationsPage(),
                              ),
                            );
                          },
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              constraints: const BoxConstraints(
                                minWidth: 14,
                                minHeight: 14,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF4848),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                              child: Center(
                                child: Text(
                                  unreadCount > 9 ? '9+' : unreadCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value.toLowerCase();
                              });
                            },
                            decoration: InputDecoration(
                              hintStyle: TextStyle(fontSize: 12),
                              hintText: AppLocalizations.of(
                                context,
                              )?.searchByBookingId,
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        setState(() {
                                          _searchController.clear();
                                          _searchQuery = '';
                                        });
                                      },
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 0,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _selectDateRange(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _startDate != null
                                    ? colorScheme.primary
                                    : Colors.grey.shade400,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: _startDate != null
                                  ? colorScheme.primary.withOpacity(0.1)
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 20,
                                  color: _startDate != null
                                      ? colorScheme.primary
                                      : Colors.grey.shade600,
                                ),
                                if (_startDate != null && _endDate != null) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '${DateFormat('MMM dd').format(_startDate!)} - ${DateFormat('MMM dd').format(_endDate!)}',
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _startDate = null;
                                        _endDate = null;
                                      });
                                    },
                                    child: Icon(
                                      Icons.close,
                                      size: 18,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ] else ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    AppLocalizations.of(
                                          context,
                                        )?.filterByDate ??
                                        "Filter Date",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                      tabs: List.generate(bookingStatus.length, (index) {
                        final status = bookingStatus[index];
                        final isSelected = _tabController.index == index;
                        return Padding(
                          padding: EdgeInsets.only(
                            left: index == 0 ? 12 : 0,
                            right: index < bookingStatus.length - 1 ? 8 : 12,
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
                      children: List.generate(bookingStatus.length, (index) {
                        return _buildBookingsList(
                          context,

                          selectedBookingStatus: bookingStatus[index]['code']!,
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
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
        width: 1,
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

  // Filter bookings based on search query and date range
  List<BookingModel> _filterBookings(List<BookingModel> bookings) {
    var filtered = bookings;

    // Date filter
    if (_startDate != null && _endDate != null) {
      filtered = filtered.where((booking) {
        if (booking.createdAt == null) return false;
        final createdAt = booking.createdAt!.toDate();
        // Compare dates: start date inclusive, end date inclusive (up to end of day)
        final endDateTime = _endDate!.add(const Duration(days: 1));
        return createdAt.compareTo(_startDate!) >= 0 &&
            createdAt.isBefore(endDateTime);
      }).toList();
    }

    if (_searchQuery.isEmpty) {
      return filtered;
    }

    return filtered.where((booking) {
      final bookingId = booking.id.toLowerCase();

      return bookingId.contains(_searchQuery);
    }).toList();
  }

  Widget _buildBookingsList(
    BuildContext context, {
    required String selectedBookingStatus,
  }) {
    return StreamBuilder<List<BookingModel>>(
      stream: AppServices.getBookingsStream(
        bookingStatusCode: selectedBookingStatus,
        isAdmin: true,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [SizedBox(height: 24, child: Loader())],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }

        final allBookings = snapshot.data ?? [];
        final filteredBookings = _filterBookings(allBookings);

        if (filteredBookings.isEmpty) {
          return _buildEmptyState(
            context,
            selectedBookingStatus,
            isSearching: _searchQuery.isNotEmpty,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: filteredBookings.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final booking = filteredBookings[index];
            return BookingListTileWidget(
              key: ValueKey(booking.id),
              booking: booking,
              isAdmin: true,
              onAssign: () {
                showAssignToUserBottomSheet(booking);
              },
            );
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
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.hourglass_empty,
            size: 100,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          const SizedBox(height: 12),
          Text(
            localizations!.noBookings,
            style: textTheme.labelLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
