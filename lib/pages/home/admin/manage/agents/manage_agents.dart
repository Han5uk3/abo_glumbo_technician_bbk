import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/common_widget/elevated_button.dart';
import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/agents/agent_info.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/bloc/manage_app_bloc.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/models/transaction.dart';
import 'package:intl/intl.dart' hide TextDirection;

class ManageAgents extends StatefulWidget {
  final bool isMainAdmin;
  const ManageAgents({super.key, required this.isMainAdmin});

  @override
  State<ManageAgents> createState() => _ManageAgentsState();
}

class _ManageAgentsState extends State<ManageAgents>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedFilter = 0;
  DateTime? _startDate;
  DateTime? _endDate;
  String _periodLabel = 'All Time';

  String get _displayPeriodLabel {
    if (_startDate == null && _endDate == null) {
      return AppLocalizations.of(context)?.allTime ?? 'All Time';
    }
    return _periodLabel;
  }

  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  late Stream<Map<String, dynamic>> _agentsTransactionsStream;

  @override
  void initState() {
    super.initState();
    _agentsTransactionsStream = Rx.combineLatest2(
      AppServices.getAllAgentsStream(),
      AppServices.getAllTransactionsStream(),
      (List<UserModel> agents, List<TransactionModel> transactions) {
        return {'agents': agents, 'transactions': transactions};
      },
    );
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
    required bool isApproval,
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
                          colors: isApproval
                              ? [Colors.green.shade400, Colors.green.shade600]
                              : [Colors.red.shade400, Colors.red.shade600],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (isApproval ? Colors.green : Colors.red)
                                .withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        isApproval
                            ? Icons.check_circle_rounded
                            : Icons.block_rounded,
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
                    onPressed: () => Navigator.of(context).pop(false),
                    text: AppLocalizations.of(context)!.cancel,
                    context: context,
                    textColor: Colors.black,
                    backgroundColor: AppColors.bgWhite,
                  ),
                  eButton(
                    text: AppLocalizations.of(context)!.confirm,
                    onPressed: () => Navigator.of(context).pop(true),
                    context: context,
                    textColor: Colors.white,
                    backgroundColor: isApproval
                        ? Colors.green.shade600
                        : Colors.red.shade600,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
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

  Future<void> _selectMonth(BuildContext context) async {
    final now = DateTime.now();
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
          content: Container(
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
                  final now = DateTime.now();
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
                  _selectMonth(context);
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<ManageAppBloc, ManageAppState>(
      listener: (context, state) {
        if (state is AgentApproved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    state.isApproved
                        ? Icons.check_circle_rounded
                        : Icons.block_rounded,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      state.isApproved
                          ? AppLocalizations.of(context)!.agentApproved
                          : AppLocalizations.of(context)!.agentDisapproved,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: state.isApproved
                  ? Colors.green.shade600
                  : Colors.red.shade600,
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
            AppLocalizations.of(context)!.manageTechnicians,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          shape: Border.all(style: BorderStyle.none),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.black),
              onPressed: () {
                setState(() {});
              },
              tooltip: AppLocalizations.of(context)!.refresh,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
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
                      )!.searchByTechnicianName,
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

              // Filter Chips Section
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: [
                      _buildFilterChip(
                        context,
                        AppLocalizations.of(context)!.all,
                        0,
                      ),
                      _buildFilterChip(
                        context,
                        AppLocalizations.of(context)!.verified,
                        1,
                      ),
                      _buildFilterChip(
                        context,
                        AppLocalizations.of(context)!.pending,
                        2,
                      ),
                    ],
                  ),
                ),
              ),

              // Agents List & Period Filter
              StreamBuilder<Map<String, dynamic>>(
                stream: _agentsTransactionsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: Loader());
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

                  if (!snapshot.hasData || snapshot.data!['agents'] == null) {
                    return _buildEmptyState(
                      context: context,
                      icon: Icons.engineering_rounded,
                      title: AppLocalizations.of(context)!.noAgentsFound,
                      subtitle: AppLocalizations.of(context)!.noAgentsAvailable,
                      color: AppColors.primary,
                    );
                  }

                  final allUsers = snapshot.data!['agents'] as List<UserModel>;
                  final allTransactions =
                      snapshot.data!['transactions']
                          as List<TransactionModel>? ??
                      [];
                  final agents = allUsers
                      .where((user) => user.isAdmin != true)
                      .toList();

                  final filteredAgents = agents.where((agent) {
                    bool matchesSearch = true;
                    if (_searchQuery.isNotEmpty) {
                      final name = (agent.name ?? '').toLowerCase();
                      final email = (agent.email ?? '').toLowerCase();
                      final phone = (agent.phone ?? '').toLowerCase();
                      matchesSearch =
                          name.contains(_searchQuery) ||
                          email.contains(_searchQuery) ||
                          phone.contains(_searchQuery);
                    }

                    bool matchesVerification = true;
                    final isVerified = agent.isVerified ?? false;
                    if (_selectedFilter == 1) {
                      matchesVerification = isVerified;
                    } else if (_selectedFilter == 2) {
                      matchesVerification = !isVerified;
                    }
                    return matchesSearch && matchesVerification;
                  }).toList();

                  // Calculate combined totals for the selected period
                  double combinedInApp = 0.0;
                  double combinedOutside = 0.0;
                  for (var t in allTransactions) {
                    final isCompleted =
                        t.paymentStatus.toLowerCase() == 'completed' ||
                        t.paymentStatus.toLowerCase() == 'paid';
                    if (!isCompleted) continue;

                    final date = t.createdAt.toDate();
                    if (_startDate != null && date.isBefore(_startDate!))
                      continue;
                    if (_endDate != null && date.isAfter(_endDate!)) continue;

                    final isOutside =
                        t.paymentMethod.toLowerCase().contains('outside') ||
                        t.paymentMethod.toLowerCase().contains('cash') ||
                        t.paymentMethod.toLowerCase().contains('hand');
                    if (isOutside) {
                      combinedOutside += t.amount;
                    } else {
                      combinedInApp += t.amount;
                    }
                  }

                  return Column(
                    children: [
                      // Earnings Period Filter Card
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
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    AppLocalizations.of(
                                          context,
                                        )?.earningsPeriod ??
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

                      if (filteredAgents.isEmpty)
                        _buildEmptyState(
                          context: context,
                          icon: Icons.search_off_rounded,
                          title: AppLocalizations.of(
                            context,
                          )!.noTechniciansMatchYourFilters,
                          subtitle: AppLocalizations.of(
                            context,
                          )!.tryAdjustingYourSearchCriteria,
                          color: AppColors.primary,
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(
                            top: 4,
                            bottom: 100,
                            left: 16,
                            right: 16,
                          ),
                          itemCount: filteredAgents.length,
                          itemBuilder: (context, index) {
                            final agent = filteredAgents[index];

                            // Calculate earnings for this specific agent
                            double inApp = 0.0;
                            double outside = 0.0;
                            for (var t in allTransactions) {
                              if (t.workerId != agent.uid) continue;
                              final isCompleted =
                                  t.paymentStatus.toLowerCase() ==
                                      'completed' ||
                                  t.paymentStatus.toLowerCase() == 'paid';
                              if (!isCompleted) continue;

                              final date = t.createdAt.toDate();
                              if (_startDate != null &&
                                  date.isBefore(_startDate!))
                                continue;
                              if (_endDate != null && date.isAfter(_endDate!))
                                continue;

                              final isOutside =
                                  t.paymentMethod.toLowerCase().contains(
                                    'outside',
                                  ) ||
                                  t.paymentMethod.toLowerCase().contains(
                                    'cash',
                                  ) ||
                                  t.paymentMethod.toLowerCase().contains(
                                    'hand',
                                  );
                              if (isOutside) {
                                outside += t.amount;
                              } else {
                                inApp += t.amount;
                              }
                            }

                            return _buildAgentCard(
                              context: context,
                              agent: agent,
                              index: index,
                              inAppEarnings: inApp,
                              outsideAppEarnings: outside,
                            );
                          },
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              _searchController.clear();
              _searchQuery = '';
              _selectedFilter = 0;
            });
          },
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.refresh_rounded, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, int value) {
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

  Widget _buildAgentCard({
    required BuildContext context,
    required agent,
    required int index,
    required double inAppEarnings,
    required double outsideAppEarnings,
  }) {
    final isVerified = agent.isVerified ?? false;

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
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AgentInfo(
              agent: agent,
              isMainAdmin: widget.isMainAdmin,
              startDate: _startDate,
              endDate: _endDate,
              initialInAppEarnings: inAppEarnings,
              initialOutsideAppEarnings: outsideAppEarnings,
            ),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                agent.name ?? 'Unknown',
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
                                color:
                                    (isVerified ? Colors.green : Colors.orange)
                                        .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                (() {
                                  if (isVerified) {
                                    return AppLocalizations.of(
                                      context,
                                    )!.verified;
                                  }
                                  if (agent.rejectionReason != null &&
                                      agent.rejectionReason!.isNotEmpty &&
                                      agent.isDocsPendingReview != true) {
                                    return "REJECTED";
                                  }
                                  if (agent.isDocsPendingReview == true) {
                                    return "PENDING REVIEW";
                                  }
                                  return AppLocalizations.of(context)!.pending;
                                })().toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isVerified
                                      ? Colors.green
                                      : (agent.rejectionReason != null &&
                                                agent
                                                    .rejectionReason!
                                                    .isNotEmpty &&
                                                agent.isDocsPendingReview !=
                                                    true
                                            ? Colors.red
                                            : Colors.orange),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (agent.email != null && agent.email!.isNotEmpty)
                          _buildInfoRow(
                            context: context,
                            icon: Icons.email_outlined,
                            text: agent.email!,
                          ),
                        if (agent.phone != null && agent.phone!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: _buildInfoRow(
                              isPhone: true,
                              context: context,
                              icon: Icons.phone_outlined,
                              text: agent.phone!,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (agent.uid != null &&
                      (LocalStore.getCachedAdminData()?.hasFullAccess ?? true))
                    IconButton(
                      onPressed: () async {
                        if (!isVerified) {
                          final confirmed = await _showConfirmationDialog(
                            context: context,
                            title: AppLocalizations.of(context)!.approveAgent,
                            message: AppLocalizations.of(
                              context,
                            )!.areYouSureYouWantToApproveThisAgent,
                            isApproval: true,
                          );

                          if (confirmed == true && context.mounted) {
                            context.read<ManageAppBloc>().add(
                              ApproveRejectAgentEvent(agent.uid!, true),
                            );
                          }
                        } else {
                          final isCurrentlyBlocked = agent.isBlocked ?? false;
                          final l10n = AppLocalizations.of(context)!;
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(
                                isCurrentlyBlocked
                                    ? l10n.unblockAccount
                                    : l10n.suspendAccount,
                              ),
                              content: Text(
                                isCurrentlyBlocked
                                    ? l10n.areYouSureYouWantToUnblockThisAccount
                                    : l10n.areYouSureYouWantToSuspendThisAccount,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: Text(l10n.cancel),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text(
                                    isCurrentlyBlocked
                                        ? l10n.unblock
                                        : l10n.suspendAccount,
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true && context.mounted) {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) =>
                                  const Center(child: Loader()),
                            );
                            try {
                              final success =
                                  await AppServices.blockOrUnblockAgent(
                                    agent.uid!,
                                    !isCurrentlyBlocked,
                                  );
                              if (context.mounted) {
                                Navigator.pop(context); // close loader
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        !isCurrentlyBlocked
                                            ? l10n.accountSuspended
                                            : l10n.accountUnblocked,
                                      ),
                                      backgroundColor: !isCurrentlyBlocked
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              if (context.mounted) {
                                Navigator.pop(context); // close loader
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        }
                      },
                      icon: Icon(
                        !isVerified
                            ? Icons.check_circle_outline
                            : (agent.isBlocked == true
                                  ? Icons.lock_open_rounded
                                  : Icons.block_rounded),
                        color: !isVerified
                            ? Colors.green
                            : (agent.isBlocked == true
                                  ? Colors.green
                                  : Colors.red),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Dynamic Period Earnings Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black.withOpacity(0.04)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)?.totalEarnings ??
                              "Total Earnings",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          "${(inAppEarnings + outsideAppEarnings).toStringAsFixed(2)} ${AppLocalizations.of(context)?.sar ?? "SAR"}",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16, thickness: 1),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)?.inApp ?? "In-App",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "${inAppEarnings.toStringAsFixed(2)} ${AppLocalizations.of(context)?.sar ?? "SAR"}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 24,
                          width: 1,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)?.outsideApp ??
                                    "Outside-App",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "${outsideAppEarnings.toStringAsFixed(2)} ${AppLocalizations.of(context)?.sar ?? "SAR"}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
