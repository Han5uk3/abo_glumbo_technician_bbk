import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/unified_payout.dart';
import 'package:aboglumbo_bbk_panel/services/unified_payout_services.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ManageUnifiedPayoutsPage extends StatefulWidget {
  const ManageUnifiedPayoutsPage({super.key});

  @override
  State<ManageUnifiedPayoutsPage> createState() =>
      _ManageUnifiedPayoutsPageState();
}

class _ManageUnifiedPayoutsPageState extends State<ManageUnifiedPayoutsPage> {
  String _selectedFilter =
      'P'; // P = Pending, A = Approved, R = Rejected, All = All
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
        title: Text(AppLocalizations.of(context)!.managePayouts),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildFilterChips(),
          _buildSearchBar(),
          Expanded(child: _buildPayoutsList()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: FutureBuilder<Map<String, dynamic>>(
        future: UnifiedPayoutServices.getPayoutStatistics(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SizedBox(
              height: 90,
              child: Center(child: Loader(color: Colors.white)),
            );
          }
          if (!snapshot.hasData) {
            return SizedBox(
              height: 90,
              child: Center(
                child: Text(
                  snapshot.error.toString(),
                  style: TextStyle(color: Colors.white),
                ),
              ),
            );
          }

          final stats = snapshot.data!;
          return Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  label: AppLocalizations.of(context)!.pending,
                  count: stats['pendingCount'].toString(),
                  icon: Icons.schedule,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  label: AppLocalizations.of(context)!.approved,
                  count: stats['approvedCount'].toString(),

                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildFilterChip(
              label: AppLocalizations.of(context)!.all,
              value: 'All',
              icon: Icons.list,
              color: Colors.blue,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: AppLocalizations.of(context)!.pending,
              value: 'P',
              icon: Icons.schedule,
              color: Colors.orange,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: AppLocalizations.of(context)!.approved,
              value: 'A',
              icon: Icons.check_circle,
              color: Colors.green,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: AppLocalizations.of(context)!.rejected,
              value: 'R',
              icon: Icons.cancel,
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      backgroundColor: AppColors.bgWhite,
      label: Row(mainAxisSize: MainAxisSize.min, children: [Text(label)]),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: color,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
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
                hintText: AppLocalizations.of(context)!.searchByTechnicianName,
                hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 15),
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
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );

    // return Padding(
    //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    //   child: TextField(
    //     controller: _searchController,
    //     decoration: InputDecoration(
    //       hintText: AppLocalizations.of(context)!.searchByWorkerName,
    //       prefixIcon: const Icon(Icons.search),
    //       suffixIcon: _searchQuery.isNotEmpty
    //           ? IconButton(
    //               icon: const Icon(Icons.clear),
    //               onPressed: () {
    //                 setState(() {
    //                   _searchController.clear();
    //                   _searchQuery = '';
    //                 });
    //               },
    //             )
    //           : null,
    //       border: OutlineInputBorder(
    //         borderRadius: BorderRadius.circular(12),
    //         borderSide: BorderSide(color: Colors.grey[300]!),
    //       ),
    //       filled: true,
    //       fillColor: Colors.white,
    //       contentPadding: const EdgeInsets.symmetric(
    //         horizontal: 16,
    //         vertical: 12,
    //       ),
    //     ),
    //     onChanged: (value) {
    //       setState(() {
    //         _searchQuery = value.toLowerCase();
    //       });
    //     },
    //   ),
    // );
  }

  Widget _buildPayoutsList() {
    return StreamBuilder<List<UnifiedPayoutRequestModel>>(
      stream: _selectedFilter == 'All'
          ? UnifiedPayoutServices.getAllPayoutRequests()
          : UnifiedPayoutServices.getAllPayoutRequests(status: _selectedFilter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: Loader(color: AppColors.primary));
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  '${AppLocalizations.of(context)!.error}: ${snapshot.error}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.noPayoutRequests,
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          );
        }

        var requests = snapshot.data!;

        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          requests = requests.where((request) {
            final workerName = request.workerName?.toLowerCase() ?? '';
            return workerName.contains(_searchQuery);
          }).toList();
        }

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.noResultsFound,
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
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
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final request = requests[index];
              return _buildPayoutRequestCard(request);
            },
          ),
        );
      },
    );
  }

  Widget _buildPayoutRequestCard(UnifiedPayoutRequestModel request) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (request.status) {
      case 'P':
        statusColor = Colors.orange;
        statusText = AppLocalizations.of(context)!.pending;
        statusIcon = Icons.schedule;
        break;
      case 'A':
        statusColor = Colors.green;
        statusText = AppLocalizations.of(context)!.approved;
        statusIcon = Icons.check_circle;
        break;
      case 'R':
        statusColor = Colors.red;
        statusText = AppLocalizations.of(context)!.rejected;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusText = AppLocalizations.of(context)!.unknown;
        statusIcon = Icons.help;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showPayoutDetails(request),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.workerName ??
                              AppLocalizations.of(context)!.unknown,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, yyyy HH:mm').format(
                            request.createdAt?.toDate() ?? DateTime.now(),
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.totalAmount,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${AppLocalizations.of(context)!.sar} ${(request.totalAmount ?? 0.0).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Expanded(
                  //   child: _buildAmountChip(
                  //     label: AppLocalizations.of(context)!.earnings,
                  //     amount: request.earningsAmount ?? 0.0,
                  //     color: Colors.purple,
                  //   ),
                  // ),
                  // const SizedBox(width: 8),
                  Expanded(
                    child: _buildAmountChip(
                      label: AppLocalizations.of(context)!.tips,
                      amount: request.tipsAmount ?? 0.0,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildAmountChip(
                      label: AppLocalizations.of(context)!.bonus,
                      amount: request.bonusAmount ?? 0.0,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              if (request.status == 'P') ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _rejectPayout(request),
                        icon: const Icon(Icons.close, size: 18),
                        label: Text(AppLocalizations.of(context)!.reject),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _approvePayout(request),
                        icon: const Icon(Icons.check, size: 18),
                        label: Text(AppLocalizations.of(context)!.approve),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountChip({
    required String label,
    required double amount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            amount.toStringAsFixed(0),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPayoutDetails(UnifiedPayoutRequestModel request) async {
    // Determine status properties
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (request.status) {
      case 'P':
        statusColor = Colors.orange;
        statusText = AppLocalizations.of(context)!.pending;
        statusIcon = Icons.schedule;
        break;
      case 'A':
        statusColor = Colors.green;
        statusText = AppLocalizations.of(context)!.approved;
        statusIcon = Icons.check_circle;
        break;
      case 'R':
        statusColor = Colors.red;
        statusText = AppLocalizations.of(context)!.rejected;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusText = AppLocalizations.of(context)!.unknown;
        statusIcon = Icons.help;
    }

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.bgWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with gradient background
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.payoutDetails,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 16, color: statusColor),
                              const SizedBox(width: 4),
                              Text(
                                statusText,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Worker name and date
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          color: Colors.white.withOpacity(0.9),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            request.workerName ??
                                AppLocalizations.of(context)!.unknown,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.95),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: Colors.white.withOpacity(0.7),
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('MMM dd, yyyy • HH:mm').format(
                            request.createdAt?.toDate() ?? DateTime.now(),
                          ),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Payout account section
                      if (request.payoutAccount != null) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.account_balance,
                                    color: Colors.blue[700],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppLocalizations.of(context)!.payoutAccount,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.blue[900],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                icon: Icons.business,
                                label: AppLocalizations.of(context)!.bankName,
                                value:
                                    request.payoutAccount!['bankName'] ?? 'N/A',
                                color: Colors.blue,
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                icon: Icons.credit_card,
                                label: AppLocalizations.of(
                                  context,
                                )!.accountNumber,
                                value:
                                    request.payoutAccount!['accountNumber'] ??
                                    'N/A',
                                color: Colors.blue,
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                icon: Icons.account_balance_wallet,
                                label: AppLocalizations.of(context)!.iban,
                                value:
                                    request.payoutAccount!['ifscCode'] ?? 'N/A',
                                color: Colors.blue,
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Transaction ID section
                      if (request.transactionId != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow(
                                icon: Icons.receipt_long,
                                label: AppLocalizations.of(
                                  context,
                                )!.transactionId,
                                value: request.transactionId!,
                                color: Colors.green,
                              ),
                              // Payment proof link
                              if (request.paymentProofUrl != null) ...[
                                const SizedBox(height: 12),
                                InkWell(
                                  onTap: () => _viewPaymentProof(
                                    request.paymentProofUrl!,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.green.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.attach_file,
                                          color: Colors.green[700],
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.uploadPaymentProof,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.green[800],
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          Icons.open_in_new,
                                          color: Colors.green[600],
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],

                      // Rejection reason section
                      if (request.rejectionReason != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red[700],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.rejectionReason,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.red[900],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                request.rejectionReason!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.red[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.close,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method for info rows
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color.withOpacity(0.8)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _approvePayout(UnifiedPayoutRequestModel request) async {
    final transactionIdController = TextEditingController();
    XFile? paymentProof;
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.approvePayout),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${AppLocalizations.of(context)!.amount}: ${AppLocalizations.of(context)!.sar} ${(request.totalAmount ?? 0.0).toStringAsFixed(2)} ',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: transactionIdController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.transactionId,
                        hintText: AppLocalizations.of(
                          context,
                        )!.enterTransactionId,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final image = await picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (image != null) {
                          setDialogState(() {
                            paymentProof = image;
                          });
                        }
                      },
                      icon: const Icon(Icons.upload_file),
                      label: Text(
                        paymentProof == null
                            ? AppLocalizations.of(context)!.uploadPaymentProof
                            : AppLocalizations.of(context)!.proofUploaded,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                ElevatedButton(
                  onPressed: isLoading || transactionIdController.text.isEmpty
                      ? null
                      : () async {
                          setDialogState(() => isLoading = true);
                          try {
                            await UnifiedPayoutServices.approvePayout(
                              requestId: request.id!,
                              transactionId: transactionIdController.text,
                              paymentProof: paymentProof,
                            );

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.payoutApproved,
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${AppLocalizations.of(context)!.error}: $e',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            if (dialogContext.mounted) {
                              setDialogState(() => isLoading = false);
                            }
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(AppLocalizations.of(context)!.approve),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _rejectPayout(UnifiedPayoutRequestModel request) async {
    final reasonController = TextEditingController();
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.rejectPayout),
              content: TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.rejectionReason,
                  hintText: AppLocalizations.of(context)!.enterReason,
                  border: const OutlineInputBorder(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                ElevatedButton(
                  onPressed: isLoading || reasonController.text.isEmpty
                      ? null
                      : () async {
                          setDialogState(() => isLoading = true);
                          try {
                            await UnifiedPayoutServices.rejectPayout(
                              requestId: request.id!,
                              reason: reasonController.text,
                            );

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.payoutRejected,
                                  ),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          } catch (e) {
                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${AppLocalizations.of(context)!.error}: $e',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            if (dialogContext.mounted) {
                              setDialogState(() => isLoading = false);
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(AppLocalizations.of(context)!.reject),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Opens the payment proof document in an external viewer
  Future<void> _viewPaymentProof(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${AppLocalizations.of(context)!.error}: Could not open document',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
