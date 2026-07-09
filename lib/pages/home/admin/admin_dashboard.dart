import 'package:aboglumbo_bbk_panel/models/admin_dashboard_data.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/pages/notifications/notifications_page.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:aboglumbo_bbk_panel/common_widget/dashboard_stat_card.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/customers/manage_customers.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/agents/manage_agents.dart';
import 'package:shimmer/shimmer.dart';

class AdminDashboardPage extends StatefulWidget {
  final Function(int tabIndex, {String? bookingStatus})? onNavigate;

  const AdminDashboardPage({super.key, this.onNavigate});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      body: StreamBuilder<AdminDashboardData>(
        stream: AppServices.getAdminDashboardStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerLoader(l10n);
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                AppLocalizations.of(
                      context,
                    )?.errorOccurred(snapshot.error.toString()) ??
                    'Error: ${snapshot.error}',
              ),
            );
          }
          if (!snapshot.hasData) {
            return Center(
              child: Text(
                AppLocalizations.of(context)?.noDataAvailable ??
                    'No data available',
              ),
            );
          }

          final data = snapshot.data!;
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverHeader(l10n.dashboard),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildStatsGrid(data, l10n),
                    _buildRevenueChart(data, l10n),
                    const SizedBox(height: 16),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverHeader(String title) {
    return SliverAppBar(
      expandedHeight: 85,
      backgroundColor: AppColors.primarytwo,
      automaticallyImplyLeading: false,
      elevation: 0,
      pinned: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/appbarbg.png',
                fit: BoxFit.fitHeight,
                repeat: ImageRepeat.repeat,
                color: Colors.white.withOpacity(0.3),
                colorBlendMode: BlendMode.dstIn,
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      StreamBuilder<int>(
                        stream: AppServices.getUnreadNotificationsCountStream(),
                        builder: (context, snapshot) {
                          final unreadCount = snapshot.data ?? 0;
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                              child: Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.25),
                                    width: 1,
                                  ),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.notifications_none_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const NewNotificationsPage(),
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
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              unreadCount > 9
                                                  ? '9+'
                                                  : unreadCount.toString(),
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
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(AdminDashboardData data, AppLocalizations l10n) {
    return GridView.count(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        DashboardStatCard(
          label: l10n.pending,
          value: data.pendingCount.toString(),
          icon: Icons.hourglass_empty,
          color: Colors.orange,
          onTap: () => widget.onNavigate?.call(1, bookingStatus: 'P'),
        ),
        DashboardStatCard(
          label: l10n.accepted,
          value: data.assignedCount.toString(),
          icon: Icons.assignment_ind_outlined,
          color: Colors.blue,
          onTap: () => widget.onNavigate?.call(1, bookingStatus: 'A'),
        ),
        DashboardStatCard(
          label: l10n.completed,
          value: data.completedCount.toString(),
          icon: Icons.check_circle_outline,
          color: Colors.green,
          onTap: () => widget.onNavigate?.call(1, bookingStatus: 'C'),
        ),
        DashboardStatCard(
          label: l10n.warrantyClaims,
          value: data.warrantyClaimsCount.toString(),
          icon: Icons.verified_user_outlined,
          color: Colors.purple,
          onTap: () => widget.onNavigate?.call(3),
        ),
        DashboardStatCard(
          label: l10n.customers,
          value: data.customerCount.toString(),
          icon: Icons.people_outline,
          color: Colors.teal,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ManageCustomersPage(),
              ),
            );
          },
        ),
        DashboardStatCard(
          label: l10n.technicians,
          value: data.technicianCount.toString(),
          icon: Icons.engineering_outlined,
          color: Colors.indigo,
          onTap: () {
            final adminData = LocalStore.getCachedAdminData();
            final isCoreAdmin = adminData?.isCoreAdmin ?? false;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ManageAgents(isMainAdmin: isCoreAdmin),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRevenueChart(AdminDashboardData data, AppLocalizations l10n) {
    final spots = <FlSpot>[];
    final labels = data.monthlyRevenue.keys.toList();
    final values = data.monthlyRevenue.values.toList();

    for (int i = 0; i < values.length; i++) {
      spots.add(FlSpot(i.toDouble(), values[i]));
    }

    double maxRevenue = values.isNotEmpty
        ? values.reduce((a, b) => a > b ? a : b)
        : 0;
    if (maxRevenue == 0) maxRevenue = 1000;

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.monthlyRevenue,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: Colors.grey[200]!, strokeWidth: 1);
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < labels.length) {
                          String label = labels[index];
                          String monthLabel;
                          try {
                            final date = DateFormat('MMM yyyy').parse(label);
                            monthLabel = DateFormat.MMM(
                              l10n.localeName,
                            ).format(date);
                          } catch (e) {
                            monthLabel = label.split(' ')[0];
                          }
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              monthLabel,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: maxRevenue > 0 ? maxRevenue / 4 : 250,
                      reservedSize: 45,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        String formattedValue;
                        if (value >= 1000) {
                          formattedValue =
                              '${(value / 1000).toStringAsFixed(1)}k';
                        } else {
                          formattedValue = value.toInt().toString();
                        }

                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            formattedValue,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (labels.length - 1).toDouble(),
                minY: 0,
                maxY: maxRevenue * 1.2,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.3),
                          AppColors.secondary.withOpacity(0.1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoader(AppLocalizations l10n) {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        _buildSliverHeader(l10n.dashboard),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Column(
                  children: [
                    GridView.count(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2.2,
                      children: List.generate(6, (index) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ]),
          ),
        ),
      ],
    );
  }
}
