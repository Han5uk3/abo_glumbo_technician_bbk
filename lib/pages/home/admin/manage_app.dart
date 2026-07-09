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
import 'package:aboglumbo_bbk_panel/styles/app_color.dart';
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

    // Check if user is main/core admin (level 0 or isCoreAdmin flag)
    _isCoreAdmin =
        (adminData?.isCoreAdmin ?? false) || (adminData?.accessLevel == 0);

    // Check if user is customer service (restricted access)
    _isCustomerService = !(adminData?.hasFullAccess ?? true);

    List<_TileInfo> allTiles = [
      // Only show Manage Admins to core admin
      if (_isCoreAdmin)
        _TileInfo(
          key: 'manage_admins',
          labelFallback: AppLocalizations.of(context)!.admins,
          icon: Icons.admin_panel_settings_rounded,
          onTap: () => _navigateToPage('Manage Admins'),
        ),
      _TileInfo(
        key: 'manage_users',
        labelFallback:
            AppLocalizations.of(context)?.categories ?? "Manage Categories",
        icon: Icons.category,
        onTap: () => _navigateToPage('Manage Categories'),
      ),
      _TileInfo(
        key: 'manage_services',
        labelFallback:
            AppLocalizations.of(context)?.services ?? "Manage Services",
        icon: Icons.settings,
        onTap: () => _navigateToPage('Manage Services'),
      ),
      _TileInfo(
        key: 'view_logs',
        labelFallback:
            AppLocalizations.of(context)?.highlightedServices ??
            "Manage Highlighted Services",
        icon: Icons.history,
        onTap: () => _navigateToPage('Manage Highlighted Services'),
      ),
      _TileInfo(
        key: 'manage_banners',
        labelFallback:
            AppLocalizations.of(context)?.banners ?? "Manage Banners",
        icon: Icons.ads_click,
        onTap: () => _navigateToPage('Manage Banners'),
      ),
      _TileInfo(
        key: 'manage_agents',
        labelFallback:
            AppLocalizations.of(context)?.technicians ?? "Manage Workers",
        icon: Icons.engineering_outlined,
        onTap: () => _navigateToPage('Manage Workers'),
      ),
      _TileInfo(
        key: 'manage_customers',
        labelFallback:
            AppLocalizations.of(context)?.customers ?? "Manage Customers",
        icon: Icons.group,
        onTap: () => _navigateToPage('Manage Customers'),
      ),

      _TileInfo(
        key: 'manage_payouts',
        labelFallback:
            AppLocalizations.of(context)?.payouts ?? "Manage Payouts",
        icon: Icons.wallet,
        onTap: () => _navigateToPage('Manage Payouts'),
      ),
      _TileInfo(
        key: 'manage_faq',
        labelFallback: AppLocalizations.of(context)?.faqs ?? "Manage FAQs",
        icon: Icons.help,
        onTap: () => _navigateToPage('Manage FAQ'),
      ),
      _TileInfo(
        key: 'manage_customer_support',
        labelFallback:
            AppLocalizations.of(context)?.customerSupport ??
            "Manage Customer Support",
        icon: Icons.support_agent_outlined,
        onTap: () => _navigateToPage('Manage Customer Support'),
      ),
      _TileInfo(
        key: 'send_notifications',
        labelFallback: AppLocalizations.of(context)!.notifications,
        icon: Icons.notifications,
        onTap: () => _navigateToPage('Manage Notification Alerts'),
      ),
      _TileInfo(
        key: 'manage_transactions',
        labelFallback: AppLocalizations.of(context)!.transactions,
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
            tile.key == 'manage_transactions' ||
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          AppLocalizations.of(context)?.manage ?? "Manage",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        shape: Border.all(style: BorderStyle.none),
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16.0),
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
        children: tiles.map((tile) => _buildTile(tile)).toList(),
      ),
    );
  }

  Widget _buildTile(_TileInfo tile) {
    final Color primary = AppColors.primary;

    return GestureDetector(
      onTap: tile.onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: Icon(tile.icon, size: 32, color: primary),
            ),
            const SizedBox(height: 8),
            Text(
              tile.labelFallback,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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
