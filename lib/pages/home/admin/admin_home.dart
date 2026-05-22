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
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/sheets/assign_worker.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:rxdart/rxdart.dart';

class AdminHome extends StatefulWidget {
  final String? initialStatus;
  const AdminHome({super.key, this.initialStatus});

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

  int _getInitialIndex() {
    if (widget.initialStatus != null) {
      final index = bookingStatus.indexWhere((status) => status['code'] == widget.initialStatus);
      if (index != -1) {
        return index;
      }
    }
    return 0;
  }

  @override
  void didUpdateWidget(covariant AdminHome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialStatus != oldWidget.initialStatus && widget.initialStatus != null) {
      final targetIndex = bookingStatus.indexWhere((status) => status['code'] == widget.initialStatus);
      if (targetIndex != -1 && targetIndex != _tabController.index) {
        _tabController.animateTo(targetIndex);
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: bookingStatus.length,
      vsync: this,
      initialIndex: _getInitialIndex(),
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
                AppLocalizations.of(context)?.orders ?? "Orders",
              ),
              elevation: 0,
              shape: Border.all(style: BorderStyle.none),
              actions: [],
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

  // Filter data based on search query, date range, and remove duplicates
  List<dynamic> _filterData(List<dynamic> data) {
    // 1. Remove duplicates by Booking ID to avoid UI ghosting
    final Map<String, dynamic> uniqueMap = {};
    for (var item in data) {
      if (item is JobOfferContainer) {
        final id = item.booking?.id ?? item.requestId ?? item.offerId;
        uniqueMap[id] = item;
      } else if (item is BookingModel) {
        uniqueMap[item.id] = item;
      }
    }
    var filtered = uniqueMap.values.toList();

    // 2. Date filter
    if (_startDate != null && _endDate != null) {
      filtered = filtered.where((item) {
        DateTime? createdAt;
        if (item is BookingModel) {
          createdAt = item.createdAt?.toDate();
        } else if (item is JobOfferContainer) {
          final data = item.offerData;
          createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        }

        if (createdAt == null) return false;
        final endDateTime = _endDate!.add(const Duration(days: 1));
        return createdAt.compareTo(_startDate!) >= 0 &&
            createdAt.isBefore(endDateTime);
      }).toList();
    }

    // 3. Search filter
    if (_searchQuery.isEmpty) {
      return filtered;
    }

    return filtered.where((item) {
      String id = '';
      if (item is BookingModel) {
        id = item.id.toLowerCase();
      } else if (item is JobOfferContainer) {
        id = (item.booking?.id ?? item.requestId ?? '').toLowerCase();
      }
      return id.contains(_searchQuery);
    }).toList();
  }

  Widget _buildBookingsList(
    BuildContext context, {
    required String selectedBookingStatus,
  }) {
    Stream<List<dynamic>> stream;
    if (selectedBookingStatus == 'P') {
      final offers = AppServices.getJobOffersStream(isAdmin: true);
      final bookings = AppServices.getBookingsStream(
        bookingStatusCode: 'P',
        isAdmin: true,
      );
      stream = Rx.combineLatest2(
        offers,
        bookings,
        (List<JobOfferContainer> o, List<BookingModel> b) => [...o, ...b],
      ).cast<List<dynamic>>();
    } else {
      stream = AppServices.getBookingsStream(
        bookingStatusCode: selectedBookingStatus,
        isAdmin: true,
      ).cast<List<dynamic>>();
    }

    return StreamBuilder<List<dynamic>>(
      stream: stream,
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

        final allData = snapshot.data ?? [];
        final filteredData = _filterData(allData);

        if (filteredData.isEmpty) {
          return _buildEmptyState(
            context,
            selectedBookingStatus,
            isSearching: _searchQuery.isNotEmpty,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: filteredData.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = filteredData[index];
            if (item is JobOfferContainer) {
              return JobOfferTileWidget(
                key: ValueKey(item.offerId),
                offer: item,
                isAdmin: true,
                onAssign: item.booking != null
                    ? () => showAssignToUserBottomSheet(item.booking!)
                    : null,
              );
            } else if (item is BookingModel) {
              return BookingListTileWidget(
                key: ValueKey(item.id),
                booking: item,
                isAdmin: true,
                isWarranty: item.warranty != null,
                onAssign: () {
                  showAssignToUserBottomSheet(item);
                },
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 100,
              color: Colors.grey,
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
            color: Colors.grey,
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
