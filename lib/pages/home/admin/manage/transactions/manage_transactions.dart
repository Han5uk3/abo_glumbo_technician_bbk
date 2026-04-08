import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/widgets/transaction_tile.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ManageTransactionsPage extends StatefulWidget {
  const ManageTransactionsPage({super.key});

  @override
  State<ManageTransactionsPage> createState() => _ManageTransactionsPageState();
}

class _ManageTransactionsPageState extends State<ManageTransactionsPage> {
  String _selectedFilter = 'all'; // all, cash, card
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.manageTransactions,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Stats Overview Section
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: StreamBuilder(
                stream: AppServices.getAllTransactionsStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final transactions = snapshot.data ?? [];
                    final total = transactions.length;
                    final totalAmount = transactions.fold<double>(
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
                      hintText: AppLocalizations.of(context)!.searchByBookingId,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildFilterChip(
                  context,
                  AppLocalizations.of(context)!.all,
                  'all',
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  AppLocalizations.of(context)!.cashInHand,
                  'cash',
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  AppLocalizations.of(context)!.card,
                  'card',
                ),
              ],
            ),
          ),

          // Transactions List
          Expanded(
            child: StreamBuilder(
              stream: AppServices.getAllTransactionsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: SizedBox(height: 24, child: Loader()));
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

                // Apply payment method filter
                var filteredTransactions = _selectedFilter == 'all'
                    ? allTransactions
                    : allTransactions.where((t) {
                        final method = t.paymentMethod.toLowerCase();
                        if (_selectedFilter == 'cash') {
                          return method.contains('cash');
                        } else if (_selectedFilter == 'card') {
                          return method.contains('card');
                        }
                        return true;
                      }).toList();

                // Apply search filter
                if (_searchQuery.isNotEmpty) {
                  filteredTransactions = filteredTransactions.where((t) {
                    final bookingId = t.bookingId.toLowerCase();
                    final orderId = t.orderId.toLowerCase();
                    return bookingId.contains(_searchQuery) ||
                        orderId.contains(_searchQuery);
                  }).toList();
                }

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
                              ? AppLocalizations.of(context)!.noTransactionsYet
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

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  child: ListView.separated(
                    itemCount: filteredTransactions.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final transaction = filteredTransactions[index];
                      return TransactionTile(transaction: transaction);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'cash':
        return AppLocalizations.of(context)!.cashInHand;
      case 'card':
        return AppLocalizations.of(context)!.card;
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
      height: 125,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: value.length > 5
                  ? 16
                  : value.length > 7
                  ? 14
                  : 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
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
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: AppColors.bgWhite,
      selectedColor: AppColors.primary,
      checkmarkColor: AppColors.bgWhite,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.primary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.grey[300]!,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      elevation: 0,
      pressElevation: 2,
    );
  }
}
