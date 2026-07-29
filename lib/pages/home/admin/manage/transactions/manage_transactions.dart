import 'package:aboglumbo_bbk_panel/services/time_service.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/widgets/transaction_tile.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/widgets/shimmer_loading.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:aboglumbo_bbk_panel/models/transaction.dart';
import 'package:aboglumbo_bbk_panel/models/booking.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'dart:async';

class ManageTransactionsPage extends StatefulWidget {
  const ManageTransactionsPage({super.key});

  @override
  State<ManageTransactionsPage> createState() => _ManageTransactionsPageState();
}

class _ManageTransactionsPageState extends State<ManageTransactionsPage> {
  String _selectedFilter = 'all'; // all, inApp, outsideApp
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;
  String _periodLabel = 'All Time';
  StreamSubscription? _bookingsSub;
  final Map<String, BookingModel> _bookingsMap = {};
  late Stream<List<TransactionModel>> _transactionsStream;

  String get _displayPeriodLabel {
    if (_startDate == null && _endDate == null) {
      return AppLocalizations.of(context)?.allTime ?? 'All Time';
    }
    return _periodLabel;
  }

  @override
  void initState() {
    super.initState();
    _transactionsStream = AppServices.getAllTransactionsStream();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    _bookingsSub = AppServices.getBookingsStream(isAdmin: true).listen((
      bookings,
    ) {
      if (mounted) {
        setState(() {
          for (var b in bookings) {
            _bookingsMap[b.id] = b;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bookingsSub?.cancel();
    super.dispose();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: KsaTime.now.add(const Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
        );
        _endDate = DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
        );
        _periodLabel =
            "${DateFormat('dd/MM/yyyy').format(picked.start)} - ${DateFormat('dd/MM/yyyy').format(picked.end)}";
      });
    }
  }

  Future<void> _selectMonth() async {
    final now = KsaTime.now;
    final months = List.generate(12, (index) {
      return DateTime(now.year, now.month - index, 1);
    });

    final selected = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            AppLocalizations.of(context)?.selectMonth ?? "Select Month",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: months.length,
              itemBuilder: (context, index) {
                final monthDate = months[index];
                final label = DateFormat(
                  'MMMM yyyy',
                  Localizations.localeOf(context).languageCode,
                ).format(monthDate);
                return ListTile(
                  title: Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => Navigator.pop(context, monthDate),
                );
              },
            ),
          ),
        );
      },
    );

    if (selected != null) {
      if (!mounted) return;
      setState(() {
        _startDate = DateTime(selected.year, selected.month, 1);
        _endDate = DateTime(selected.year, selected.month + 1, 0, 23, 59, 59);
        _periodLabel = DateFormat(
          'MMMM yyyy',
          Localizations.localeOf(context).languageCode,
        ).format(selected);
      });
    }
  }

  void _showPeriodSelectorSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)?.selectPeriod ?? "Select Period",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.all_inclusive_rounded,
                    color: Colors.blue,
                  ),
                ),
                title: Text(
                  AppLocalizations.of(context)?.allTime ?? "All Time",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                    _periodLabel =
                        AppLocalizations.of(context)?.allTime ?? 'All Time';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.today_rounded, color: Colors.green),
                ),
                title: Text(
                  AppLocalizations.of(context)?.thisMonth ?? "This Month",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  final now = KsaTime.now;
                  setState(() {
                    _startDate = DateTime(now.year, now.month, 1);
                    _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
                    _periodLabel = DateFormat(
                      'MMMM yyyy',
                      Localizations.localeOf(context).languageCode,
                    ).format(now);
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.date_range_rounded,
                    color: Colors.orange,
                  ),
                ),
                title: Text(
                  AppLocalizations.of(context)?.selectMonth ?? "Select Month",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _selectMonth();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: Colors.purple,
                  ),
                ),
                title: Text(
                  AppLocalizations.of(context)?.customDateRange ??
                      "Custom Date Range",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _selectDateRange(context);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  List<TransactionModel> _getFilteredTransactions(
    List<TransactionModel> allTransactions,
  ) {
    return allTransactions.where((t) {
      // 1. Payment Method Filter
      if (_selectedFilter != 'all') {
        final method = t.paymentMethod.toLowerCase();
        final isOutside =
            method.contains('outside') ||
            method.contains('cash') ||
            method.contains('hand');
        if (_selectedFilter == 'outsideApp') {
          if (!isOutside) return false;
        } else if (_selectedFilter == 'inApp') {
          if (isOutside) return false;
        }
      }

      // 2. Date Range Filter
      final date = t.createdAt.toDate();
      if (_startDate != null && date.isBefore(_startDate!)) return false;
      if (_endDate != null && date.isAfter(_endDate!)) return false;

      // 3. Search Filter
      if (_searchQuery.isNotEmpty) {
        final bookingId = t.bookingId.toLowerCase();
        final orderId = t.orderId.toLowerCase();
        final booking = _bookingsMap[t.bookingId];
        final newBookingId = booking?.newBookingId?.toLowerCase() ?? '';

        if (!bookingId.contains(_searchQuery) &&
            !orderId.contains(_searchQuery) &&
            !newBookingId.contains(_searchQuery)) {
          return false;
        }
      }

      return true;
    }).toList();
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
        title: Text(
          AppLocalizations.of(context)!.manageTransactions,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        shape: Border.all(style: BorderStyle.none),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          child: Column(
            children: [
              // Stats Overview Section
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: StreamBuilder<List<TransactionModel>>(
                  stream: _transactionsStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final transactions = snapshot.data ?? [];
                      final filtered = _getFilteredTransactions(transactions);
                      final total = filtered.length;
                      final totalAmount = filtered.fold<double>(
                        0.0,
                        (sum, t) => sum + t.amount,
                      );

                      return Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context,
                              AppLocalizations.of(context)!.total,
                              total.toString(),
                              Icons.receipt_long_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              AppLocalizations.of(context)!.amount,
                              totalAmount.toStringAsFixed(2),
                              Icons.payments_outlined,
                            ),
                          ),
                        ],
                      );
                    }
                    return _buildStatsShimmer();
                  },
                ),
              ),

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
                          )!.searchByBookingId,
                          hintStyle: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 15,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: AppColors.primary,
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
                                  tooltip: AppLocalizations.of(context)!.clear,
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

              // Search Bar Section
              // Padding(
              //   padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              //   child: TextField(
              //     controller: _searchController,
              //     decoration: InputDecoration(
              //       hintText: AppLocalizations.of(context)!.searchByBookingId,
              //       hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              //       prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
              //       suffixIcon: _searchQuery.isNotEmpty
              //           ? IconButton(
              //               icon: Icon(Icons.clear, color: Colors.grey[600]),
              //               onPressed: () {
              //                 _searchController.clear();
              //               },
              //             )
              //           : null,
              //       filled: true,
              //       fillColor: Colors.white,
              //       border: OutlineInputBorder(
              //         borderRadius: BorderRadius.circular(12),
              //         borderSide: BorderSide(color: Colors.grey[300]!),
              //       ),
              //       enabledBorder: OutlineInputBorder(
              //         borderRadius: BorderRadius.circular(12),
              //         borderSide: BorderSide(color: Colors.grey[300]!),
              //       ),
              //       focusedBorder: OutlineInputBorder(
              //         borderRadius: BorderRadius.circular(12),
              //         borderSide: BorderSide(color: AppColors.primary, width: 2),
              //       ),
              //       contentPadding: const EdgeInsets.symmetric(
              //         horizontal: 16,
              //         vertical: 14,
              //       ),
              //     ),
              //   ),
              // ),

              // Filter Chips Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: SingleChildScrollView(
                  physics: ClampingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: [
                      _buildFilterChip(
                        context,
                        AppLocalizations.of(context)!.all,
                        'all',
                      ),
                      _buildFilterChip(
                        context,
                        AppLocalizations.of(context)?.inApp ?? 'In-App',
                        'inApp',
                      ),
                      _buildFilterChip(
                        context,
                        AppLocalizations.of(context)?.outsideApp ??
                            'Outside-App',
                        'outsideApp',
                      ),
                    ],
                  ),
                ),
              ),
              // Period Filter Card
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.05),
                        AppColors.primary.withOpacity(0.12),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => _showPeriodSelectorSheet(context),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              width: 1.0,
                              color: AppColors.primary,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.tune_rounded,
                                size: 22,
                                color: AppColors.primary,
                              ),
                              Text(
                                AppLocalizations.of(context)?.filter ??
                                    "Filter",
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      Spacer(),

                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            AppLocalizations.of(context)?.earningsPeriod ??
                                "Earnings Period",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _displayPeriodLabel,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              StreamBuilder<List<TransactionModel>>(
                stream: _transactionsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const ManageShimmerLoading();
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${AppLocalizations.of(context)!.error}: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final allTransactions = snapshot.data ?? [];
                  final filteredTransactions = _getFilteredTransactions(
                    allTransactions,
                  );

                  if (filteredTransactions.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(context)!.noTransactionsFound,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedFilter == 'all'
                                ? AppLocalizations.of(
                                    context,
                                  )!.noTransactionsYet
                                : '${AppLocalizations.of(context)!.no} ${_getFilterLabel(_selectedFilter)} ${AppLocalizations.of(context)!.transactions}',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredTransactions.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final transaction = filteredTransactions[index];
                      return TransactionTile(transaction: transaction);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'inApp':
        return AppLocalizations.of(context)?.inApp ?? 'In-App';
      case 'outsideApp':
        return AppLocalizations.of(context)?.outsideApp ?? 'Outside-App';
      default:
        return filter;
    }
  }

  // Shimmer for stats cards
  Widget _buildStatsShimmer() {
    return Row(
      children: [
        Expanded(child: _buildStatCardShimmer()),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCardShimmer()),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCardShimmer()),
      ],
    );
  }

  Widget _buildStatCardShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.1),
      highlightColor: Colors.white.withOpacity(0.3),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 60,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // // Shimmer for list items
  // Widget _buildListShimmer() {
  //   return ListView.separated(
  //     padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
  //     itemCount: 5,
  //     separatorBuilder: (context, index) => const SizedBox(height: 12),
  //     itemBuilder: (context, index) => _buildCardShimmer(),
  //   );
  // }

  // Widget _buildCardShimmer() {
  //   return Shimmer.fromColors(
  //     baseColor: Colors.grey.shade300,
  //     highlightColor: Colors.grey.shade100,
  //     child: Container(
  //       padding: const EdgeInsets.all(20),
  //       decoration: BoxDecoration(
  //         color: Colors.white,
  //         borderRadius: BorderRadius.circular(16),
  //         boxShadow: [
  //           BoxShadow(
  //             color: Colors.black.withOpacity(0.04),
  //             blurRadius: 10,
  //             offset: const Offset(0, 2),
  //           ),
  //         ],
  //       ),
  //       child: Row(
  //         children: [
  //           Container(
  //             width: 56,
  //             height: 56,
  //             decoration: BoxDecoration(
  //               color: Colors.white,
  //               borderRadius: BorderRadius.circular(16),
  //             ),
  //           ),
  //           const SizedBox(width: 16),
  //           Expanded(
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Container(
  //                   height: 12,
  //                   width: 120,
  //                   decoration: BoxDecoration(
  //                     color: Colors.white,
  //                     borderRadius: BorderRadius.circular(6),
  //                   ),
  //                 ),
  //                 const SizedBox(height: 8),
  //                 Container(
  //                   height: 14,
  //                   width: 80,
  //                   decoration: BoxDecoration(
  //                     color: Colors.white,
  //                     borderRadius: BorderRadius.circular(7),
  //                   ),
  //                 ),
  //                 const SizedBox(height: 8),
  //                 Container(
  //                   height: 12,
  //                   width: 100,
  //                   decoration: BoxDecoration(
  //                     color: Colors.white,
  //                     borderRadius: BorderRadius.circular(6),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //           const SizedBox(width: 16),
  //           Container(
  //             width: 70,
  //             height: 50,
  //             decoration: BoxDecoration(
  //               color: Colors.white,
  //               borderRadius: BorderRadius.circular(12),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, String value) {
    final isSelected = _selectedFilter == value;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Colors.black.withOpacity(0.08),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
