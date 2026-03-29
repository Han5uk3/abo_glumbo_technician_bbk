import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/admins/manage_admins.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/agents/manage_agents.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/banners/banners.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/categories/manage_categories.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/customer_support/manage_customer_support.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/customers/manage_customers.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/faq/manage_faq.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/highlighted_services/highlighted_services.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/notification_alerts/notification_alert_sending_page.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/payouts/manage_unified_payouts.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/services/manage_services.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/transactions/manage_transactions.dart';
import 'package:flutter/material.dart';

class ManageApp extends StatefulWidget {
  final UserModel userData;
  const ManageApp({super.key, required this.userData});

  @override
  State<ManageApp> createState() => _ManageAppState();
}

class _ManageAppState extends State<ManageApp> {
  late List<_TileInfo> tiles;
  bool _isCoreAdmin = false;
  bool _isCustomerService = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get admin data from cache
    final adminData = LocalStore.getCachedAdminData();

    // Check if user is main/core admin
    _isCoreAdmin = adminData?.isCoreAdmin ?? false;

    // Check if user is customer service (Level 1)
    _isCustomerService = adminData?.accessLevel == 1;

    List<_TileInfo> allTiles = [
      // Only show Manage Admins to core admin
      if (_isCoreAdmin)
        _TileInfo(
          key: 'manage_admins',
          labelFallback: 'Manage Admins',
          icon: Icons.admin_panel_settings_rounded,
          onTap: () => _navigateToPage('Manage Admins'),
        ),
      _TileInfo(
        key: 'manage_users',
        labelFallback:
            AppLocalizations.of(context)?.manageCategories ??
            "Manage Categories",
        icon: Icons.category,
        onTap: () => _navigateToPage('Manage Categories'),
      ),
      _TileInfo(
        key: 'manage_services',
        labelFallback:
            AppLocalizations.of(context)?.manageServices ?? "Manage Services",
        icon: Icons.settings,
        onTap: () => _navigateToPage('Manage Services'),
      ),
      _TileInfo(
        key: 'view_logs',
        labelFallback:
            AppLocalizations.of(context)?.manageHighlightedServices ??
            "Manage Highlighted Services",
        icon: Icons.history,
        onTap: () => _navigateToPage('Manage Highlighted Services'),
      ),
      _TileInfo(
        key: 'manage_banners',
        labelFallback:
            AppLocalizations.of(context)?.manageBanners ?? "Manage Banners",
        icon: Icons.ads_click,
        onTap: () => _navigateToPage('Manage Banners'),
      ),
      _TileInfo(
        key: 'manage_agents',
        labelFallback:
            AppLocalizations.of(context)?.manageTechnicians ?? "Manage Workers",
        icon: Icons.engineering_outlined,
        onTap: () => _navigateToPage('Manage Workers'),
      ),
      _TileInfo(
        key: 'manage_customers',
        labelFallback:
            AppLocalizations.of(context)?.manageCustomers ?? "Manage Customers",
        icon: Icons.group,
        onTap: () => _navigateToPage('Manage Customers'),
      ),

      _TileInfo(
        key: 'manage_payouts',
        labelFallback:
            AppLocalizations.of(context)?.managePayouts ?? "Manage Payouts",
        icon: Icons.wallet,
        onTap: () => _navigateToPage('Manage Payouts'),
      ),
      _TileInfo(
        key: 'manage_faq',
        labelFallback:
            AppLocalizations.of(context)?.manageFaqs ?? "Manage FAQs",
        icon: Icons.help,
        onTap: () => _navigateToPage('Manage FAQ'),
      ),
      _TileInfo(
        key: 'manage_customer_support',
        labelFallback:
            AppLocalizations.of(context)?.manageCustomerSupport ??
            "Manage Customer Support",
        icon: Icons.support_agent_outlined,
        onTap: () => _navigateToPage('Manage Customer Support'),
      ),
      _TileInfo(
        key: 'send_notifications',
        labelFallback: AppLocalizations.of(context)!.manageNotificationAlerts,
        icon: Icons.notifications,
        onTap: () => _navigateToPage('Manage Notification Alerts'),
      ),
      _TileInfo(
        key: 'manage_transactions',
        labelFallback: AppLocalizations.of(context)!.manageTransactions,
        icon: Icons.payment,
        onTap: () => _navigateToPage('Manage Transactions'),
      ),
    ];

    // Filter tiles based on access level
    if (_isCustomerService) {
      // Customer service only sees: customers, technicians, customer support, payouts
      tiles = allTiles.where((tile) {
        return tile.key == 'manage_customers' ||
            tile.key == 'manage_agents' ||
            tile.key == 'manage_customer_support' ||
            tile.key == 'manage_payouts';
      }).toList();
    } else {
      // Main admin and full admins see all tiles
      tiles = allTiles;
    }
  }

  void _navigateToPage(String pageName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          switch (pageName) {
            case 'Manage Admins':
              return const ManageAdmins();
            case 'Manage Categories':
              return const ManageCategories();
            case 'Manage Services':
              return const ManageServices();
            case 'Manage Highlighted Services':
              return const HighlightedServices();
            case 'Manage Banners':
              return const ManageBanners();
            case 'Manage Workers':
              return ManageAgents(isMainAdmin: _isCoreAdmin);
            case 'Manage Customers':
              return const ManageCustomersPage();

            case 'Manage FAQ':
              return const ManageFaq();
            case 'Manage Payouts':
              return const ManageUnifiedPayoutsPage();
            case 'Manage Customer Support':
              return const ManageCustomerSupport();
            case 'Manage Notification Alerts':
              return const SendNotificationPage();
            case 'Manage Transactions':
              return const ManageTransactionsPage();
            default:
              return const Placeholder();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.manage ?? "Manage"),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: tiles.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final tile = tiles[index];
          return _buildTile(tile);
        },
      ),
    );
  }

  Widget _buildTile(_TileInfo tile) {
    const Color primary = Color(0xFF0A2463);
    const Color secondary = Color(0xFF0081FA);

    return Card(
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: tile.onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primary.withOpacity(0.1), secondary.withOpacity(0.05)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(tile.icon, size: 24, color: primary),
        ),
        title: Text(
          tile.labelFallback,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: secondary.withOpacity(0.7),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}

class _TileInfo {
  final String key;
  final String labelFallback;
  final IconData icon;
  final VoidCallback onTap;

  _TileInfo({
    required this.key,
    required this.labelFallback,
    required this.icon,
    required this.onTap,
  });
}
