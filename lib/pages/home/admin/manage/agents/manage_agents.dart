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
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            icon:
                const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
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
        body: Column(
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
                    hintText:
                        AppLocalizations.of(context)!.searchByTechnicianName,
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

            // Filter Chips
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      context: context,
                      label: AppLocalizations.of(context)!.all,
                      icon: Icons.apps_rounded,
                      isSelected: _selectedFilter == 0,
                      onTap: () => setState(() => _selectedFilter = 0),
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      context: context,
                      label: AppLocalizations.of(context)!.verified,
                      icon: Icons.verified_rounded,
                      isSelected: _selectedFilter == 1,
                      onTap: () => setState(() => _selectedFilter = 1),
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      context: context,
                      label: AppLocalizations.of(context)!.pending,
                      icon: Icons.pending_rounded,
                      isSelected: _selectedFilter == 2,
                      onTap: () => setState(() => _selectedFilter = 2),
                      color: Colors.orange,
                    ),
                  ],
                ),
              ),
            ),

            // Agents List
            Expanded(
              child: StreamBuilder(
                stream: AppServices.getAllAgentsStream(),
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

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState(
                      context: context,
                      icon: Icons.engineering_rounded,
                      title: AppLocalizations.of(context)!.noAgentsFound,
                      subtitle: AppLocalizations.of(context)!.noAgentsAvailable,
                      color: AppColors.primary,
                    );
                  }

                  final allUsers = snapshot.data!;
                  final agents =
                      allUsers.where((user) => user.isAdmin != true).toList();

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

                  if (filteredAgents.isEmpty) {
                    return _buildEmptyState(
                      context: context,
                      icon: Icons.search_off_rounded,
                      title: AppLocalizations.of(context)!
                          .noTechniciansMatchYourFilters,
                      subtitle: AppLocalizations.of(context)!
                          .tryAdjustingYourSearchCriteria,
                      color: AppColors.primary,
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(
                      top: 4,
                      bottom: 100,
                      left: 16,
                      right: 16,
                    ),
                    itemCount: filteredAgents.length,
                    itemBuilder: (context, index) {
                      return _buildAgentCard(
                        context: context,
                        agent: filteredAgents[index],
                        index: index,
                      );
                    },
                  );
                },
              ),
            ),
          ],
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

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.black.withOpacity(0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? color : Colors.grey),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentCard({
    required BuildContext context,
    required agent,
    required int index,
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
            builder: (context) =>
                AgentInfo(agent: agent, isMainAdmin: widget.isMainAdmin),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
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
                            color: (isVerified ? Colors.green : Colors.orange)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            (isVerified
                                    ? AppLocalizations.of(context)!.verified
                                    : AppLocalizations.of(context)!.pending)
                                .toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isVerified ? Colors.green : Colors.orange,
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
                  (LocalStore.getCachedAdminData()?.accessLevel != 1))
                IconButton(
                  onPressed: () async {
                    final confirmed = await _showConfirmationDialog(
                      context: context,
                      title: isVerified
                          ? AppLocalizations.of(context)!.disapproveAgent
                          : AppLocalizations.of(context)!.approveAgent,
                      message: isVerified
                          ? AppLocalizations.of(context)!
                              .areYouSureYouWantToDisapproveAgent
                          : AppLocalizations.of(context)!
                              .areYouSureYouWantToApproveThisAgent,
                      isApproval: !isVerified,
                    );

                    if (confirmed == true && context.mounted) {
                      context.read<ManageAppBloc>().add(
                            ApproveRejectAgentEvent(
                              agent.uid!,
                              !isVerified,
                            ),
                          );
                    }
                  },
                  icon: Icon(
                    isVerified
                        ? Icons.block_rounded
                        : Icons.check_circle_outline,
                    color: isVerified ? Colors.red : Colors.green,
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
