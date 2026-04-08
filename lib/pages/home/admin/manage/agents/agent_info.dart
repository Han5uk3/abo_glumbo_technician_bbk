import 'dart:io';
import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class AgentInfo extends StatefulWidget {
  final UserModel agent;
  final bool isMainAdmin;
  const AgentInfo({super.key, required this.agent, required this.isMainAdmin});

  @override
  State<AgentInfo> createState() => _AgentInfoState();
}

class _AgentInfoState extends State<AgentInfo> {
  UserModel get agent => widget.agent;

  static Color primary = AppColors.primary;
  static Color secondary = AppColors.secondary;
  static Color cardBackground = AppColors.bgWhite;

  Map<String, Map<String, String>> jobCategories = {};
  bool isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _fetchJobCategories();
  }

  Future<void> _fetchJobCategories() async {
    try {
      final categories = await AppServices.fetchJobCategories();
      if (mounted) {
        setState(() {
          jobCategories = categories;
          isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching job categories: $e');
      }
      if (mounted) {
        setState(() {
          isLoadingCategories = false;
        });
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        throw 'Could not launch $launchUri';
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error launching phone call: $e');
      }
    }
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
  }

  Future<void> _showAdminAccessDialog(BuildContext context) async {
    // Check if current user is main admin
    final currentUserDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(LocalStore.getUID())
        .get();

    if (!currentUserDoc.exists) return;

    final currentUserData = currentUserDoc.data();
    final currentUserPhone = currentUserData?['phone'] as String?;

    // Only main admin can grant/revoke admin access
    if (currentUserPhone != '111111111' &&
        currentUserPhone != '+966111111111') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.onlyMainAdminCanManageAdminAccess,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Don't allow granting admin to main admin account
    if (agent.phone == '111111111' || agent.phone == '+966111111111') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.cannotModifyMainAdminAccount,
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    int? selectedLevel = agent.adminAccessLevel ?? 1;

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.bgWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.blue.shade600],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.adminAccess,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${AppLocalizations.of(context)!.selectAdminAccessLevelFor} ${agent.name}:',
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 20),

                  // Full Admin Option
                  InkWell(
                    onTap: () => setState(() => selectedLevel = 1),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: selectedLevel == 1
                            ? Colors.green.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selectedLevel == 1
                              ? Colors.green
                              : Colors.grey.shade300,
                          width: selectedLevel == 1 ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selectedLevel == 1
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: selectedLevel == 1
                                ? Colors.green
                                : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.fullAdmin,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.accessToAllAdminFeaturesExceptManagingOtherAdmins,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Customer Service Option
                  InkWell(
                    onTap: () => setState(() => selectedLevel = 2),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: selectedLevel == 2
                            ? Colors.orange.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selectedLevel == 2
                              ? Colors.orange
                              : Colors.grey.shade300,
                          width: selectedLevel == 2 ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selectedLevel == 2
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: selectedLevel == 2
                                ? Colors.orange
                                : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.customerService,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.viewOnlyAccessToCustomersTechniciansAndSupport,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    _grantAdminAccess(selectedLevel!);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(AppLocalizations.of(context)!.grantAccess),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _grantAdminAccess(int accessLevel) async {
    try {
      // Show loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 20, child: Loader(color: AppColors.primary)),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.grantingAdminAccess,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(agent.uid)
          .update({
            'isAdmin': true,
            'isGrantedAdminByMain': true,
            'adminAccessLevel': accessLevel,
            'grantedAdminAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${AppLocalizations.of(context)!.adminAccessGrantedTo} ${agent.name}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green.shade600,
            elevation: 6,
          ),
        );

        // Go back to refresh the list
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${AppLocalizations.of(context)!.error}: ${e.toString()}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red.shade600,
            elevation: 6,
          ),
        );
      }
    }
  }

  Future<void> _revokeAdminAccess() async {
    // Check if current user is main admin
    final currentUserDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(LocalStore.getUID())
        .get();

    if (!currentUserDoc.exists) return;

    final currentUserData = currentUserDoc.data();
    final currentUserPhone = currentUserData?['phone'] as String?;

    // Only main admin can revoke admin access
    if (currentUserPhone != '111111111' &&
        currentUserPhone != '+966111111111') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              )!.onlyTheMainAdminCanRevokeAdminAccess,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.bgWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade400, Colors.red.shade600],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.remove_moderator_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.revokeAdminAccess,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: Text(
            '${AppLocalizations.of(context)!.areYouSureYouWantToRevokeAdminAccessFor} ${agent.name}?',
            style: const TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              child: Text(AppLocalizations.of(context)!.revoke),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      // Show loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 20, child: Loader(color: AppColors.primary)),
                  const SizedBox(height: 16),
                  Text(
                    '${AppLocalizations.of(context)!.revokingAdminAccess}...',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(agent.uid)
          .update({
            'isAdmin': false,
            'isGrantedAdminByMain': false,
            'adminAccessLevel': FieldValue.delete(),
            'grantedAdminAt': FieldValue.delete(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${AppLocalizations.of(context)!.adminAccessRevokedFor} ${agent.name}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green.shade600,
            elevation: 6,
          ),
        );

        // Go back to refresh the list
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${AppLocalizations.of(context)!.error}: ${e.toString()}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red.shade600,
            elevation: 6,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cardBackground,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuickActionsCard(context),
                  const SizedBox(height: 16),
                  _buildPersonalInfoCard(context),
                  const SizedBox(height: 16),
                  if (agent.docUrl != null && agent.docUrl!.isNotEmpty)
                    _buildIqamaCard(context),
                  if (agent.docUrl != null && agent.docUrl!.isNotEmpty)
                    const SizedBox(height: 16),
                  if (agent.certifications != null &&
                      agent.certifications!.isNotEmpty)
                    _buildCertificationsCard(context),
                  if (agent.certifications != null &&
                      agent.certifications!.isNotEmpty)
                    const SizedBox(height: 16),
                  _buildBankDetailsCard(context),
                  const SizedBox(height: 16),
                  if (agent.jobRoles != null && agent.jobRoles!.isNotEmpty)
                    _buildJobRolesCard(context),
                  if (agent.jobRoles != null && agent.jobRoles!.isNotEmpty)
                    const SizedBox(height: 16),
                  _buildSystemInfoCard(context),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIqamaCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.only(
                    left: 10,
                    right: 10,
                    top: 10,
                    bottom: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.contact_page_outlined,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    maxLines: 2,
                    AppLocalizations.of(context)!.idDocument,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.only(top: 30),
              child: GestureDetector(
                onTap: () =>
                    _showFullScreenImage(widget.agent.docUrl!, context),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.green)),
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.contact_page,
                          color: Colors.green,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.idDocument,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppLocalizations.of(context)!.tapToView,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.open_in_new,
                        color: Colors.green.withOpacity(0.6),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _showFullScreenImage(
    String imageUrl,
    BuildContext context,
  ) async {
    // Detect file type from URL
    final ext = imageUrl.split('.').last.split('?').first.toLowerCase();
    final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);

    if (isImage) {
      // Show image in full screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: AppColors.primary,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(
                AppLocalizations.of(context)!.issueImage,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            body: Center(
              child: InteractiveViewer(
                panEnabled: true,
                boundaryMargin: EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => Center(
                    child: SizedBox(
                      width: 24,
                      child: Loader(size: 14, color: Colors.white),
                    ),
                  ),
                  errorWidget: (context, url, error) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          size: 100,
                          color: Colors.white,
                        ),
                        SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.failedToLoadImage,
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      // Handle documents (PDF, DOC, DOCX, etc.)
      await _openDocument(imageUrl, context);
    }
  }

  Future<void> _openDocument(String url, BuildContext context) async {
    try {
      // Show loading indicator
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 24,
                      child: Loader(color: AppColors.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.loading,
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      // Download the file
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // Get temporary directory
        final dir = await getTemporaryDirectory();
        final fileName = url.split('/').last.split('?').first;
        final file = File('${dir.path}/$fileName');

        // Write file
        await file.writeAsBytes(response.bodyBytes);

        // Close loading dialog
        if (context.mounted) {
          Navigator.of(context).pop();
        }

        // Open file
        final result = await OpenFilex.open(file.path);

        if (result.type != ResultType.done && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.failedToLoadImage),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Close loading dialog
        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.failedToLoadImage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error opening document: $e');
      }

      // Close loading dialog if still open
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToLoadImage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildCertificationsCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.only(
                    left: 10,
                    right: 10,
                    top: 10,
                    bottom: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.workspace_premium,
                    color: Colors.purple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    maxLines: 2,
                    AppLocalizations.of(
                      context,
                    )!.certificationsrelevantExperienceDocuments,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                ),
              ],
            ),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: agent.certifications!.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final certUrl = agent.certifications![index];
                final fileName = _getFileNameFromUrl(certUrl);

                return InkWell(
                  onTap: () => _launchCertificationUrl(certUrl),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.purple.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.picture_as_pdf,
                            color: Colors.purple,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fileName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppLocalizations.of(context)!.tapToView,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.open_in_new,
                          color: Colors.purple.withOpacity(0.6),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchCertificationUrl(String url) async {
    // Use the same logic as _showFullScreenImage to handle both images and documents
    await _showFullScreenImage(url, context);
  }

  String _getFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        String fileName = segments.last;
        // Decode URL-encoded characters
        fileName = Uri.decodeComponent(fileName);
        // If filename is too long, truncate it
        if (fileName.length > 40) {
          final extension = fileName.split('/').last;
          fileName = extension;
        }
        return fileName;
      }
      return 'Certification Document ${url.hashCode.abs() % 1000}';
    } catch (e) {
      return 'Certification Document';
    }
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      title: Text(AppLocalizations.of(context)!.agentInfo),
      expandedHeight: 300,
      floating: false,
      pinned: true,
      backgroundColor: primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primary, secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Hero(
                  tag: 'agent_${agent.uid}',
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: AppColors.bgWhite,
                      backgroundImage: agent.profileUrl != null
                          ? NetworkImage(agent.profileUrl!)
                          : null,
                      child: agent.profileUrl == null
                          ? Text(
                              agent.name?.isNotEmpty == true
                                  ? agent.name![0].toUpperCase()
                                  : 'A',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: primary,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  agent.name ?? 'Unknown Agent',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (agent.isVerified == true)
                      _buildBadge(
                        AppLocalizations.of(context)!.verified,
                        Icons.verified,
                        Colors.green,
                      ),
                    if (agent.isVerified == true && agent.isAdmin == true)
                      const SizedBox(width: 10),
                    if (agent.isAdmin == true)
                      _buildBadge(
                        AppLocalizations.of(context)!.admin,
                        Icons.admin_panel_settings,
                        Colors.orange,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context) {
    final hasAdminAccess = agent.isGrantedAdminByMain == true;
    final accessLevel = agent.adminAccessLevel;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  AppLocalizations.of(context)!.quickActions,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
                const Spacer(),
                // Show admin access level badge if applicable
                if (hasAdminAccess && accessLevel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: accessLevel == 1
                            ? [Colors.green.shade400, Colors.green.shade600]
                            : [Colors.orange.shade400, Colors.orange.shade600],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          accessLevel == 1
                              ? Icons.admin_panel_settings_rounded
                              : Icons.support_agent_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          accessLevel == 1 ? 'Full Admin' : 'Customer Service',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (agent.phone != null && agent.phone!.isNotEmpty)
                  _buildQuickActionButton(
                    context,
                    Icons.phone,
                    AppLocalizations.of(context)!.call,
                    Colors.green,
                    () => _makePhoneCall(agent.phone!),
                  ),
                if (agent.email != null && agent.email!.isNotEmpty)
                  _buildQuickActionButton(
                    context,
                    Icons.email,
                    AppLocalizations.of(context)!.email,
                    Colors.blue,
                    () async {
                      final Uri emailUri = Uri(
                        scheme: 'mailto',
                        path: agent.email!,
                      );
                      try {
                        await launchUrl(
                          emailUri,
                          mode: LaunchMode.platformDefault,
                        );
                      } catch (e) {
                        if (kDebugMode) {
                          print('Error launching email: $e');
                        }
                      }
                    },
                  ),
                _buildQuickActionButton(
                  context,
                  Icons.copy,
                  AppLocalizations.of(context)!.copyId,
                  Colors.purple,
                  () => _copyToClipboard(context, agent.uid ?? '', 'User ID'),
                ),
              ],
            ),

            // Admin Access Management Section (only for main admin and not for main admin account)
            if (widget.isMainAdmin) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.adminAccessManagement,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
              ),
              const SizedBox(height: 12),
              if (hasAdminAccess)
                // Revoke Admin Access Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _revokeAdminAccess(),
                    icon: const Icon(Icons.remove_moderator_rounded),
                    label: Text(
                      AppLocalizations.of(context)!.revokeAdminAccess,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                )
              else
                // Grant Admin Access Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showAdminAccessDialog(context),
                    icon: const Icon(Icons.admin_panel_settings_rounded),
                    label: Text(AppLocalizations.of(context)!.grantAdminAccess),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.person, color: primary, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.personalInformation,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildModernInfoRow(
              false,
              context,
              Icons.badge_outlined,
              AppLocalizations.of(context)!.name,
              agent.name,
            ),
            _buildDivider(),
            _buildModernInfoRow(
              false,
              context,
              Icons.email_outlined,
              AppLocalizations.of(context)!.email,
              agent.email,
            ),
            _buildDivider(),
            _buildModernInfoRow(
              true,
              context,
              Icons.phone_outlined,
              AppLocalizations.of(context)!.phone,
              agent.phone,
            ),
            _buildDivider(),
            _buildModernInfoRow(
              false,
              context,
              Icons.location_city_outlined,
              AppLocalizations.of(context)!.location,
              agent.location?.fullAddress ?? "-",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankDetailsCard(BuildContext context) {
    // Handle null or empty payoutAccounts
    if (agent.payoutAccounts == null || agent.payoutAccounts!.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance,
                      color: Colors.grey,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)!.bankAccountDetails,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  AppLocalizations.of(context)!.noBankAccountDetailsAvailable,
                  style: TextStyle(color: Colors.grey[600], fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Try to find primary account, otherwise use the first account
    final account = agent.payoutAccounts!.firstWhere(
      (element) => element.isPrimary == true,
      orElse: () => agent.payoutAccounts!.first,
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [primary.withOpacity(0.05), secondary.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance,
                      color: Colors.green,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)!.bankAccountDetails,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildBankInfoRow(
                context,
                Icons.business,
                AppLocalizations.of(context)!.bankName,
                account.bankName ?? 'Not provided',
              ),
              _buildDivider(),
              _buildBankInfoRow(
                context,
                Icons.person_outline,
                AppLocalizations.of(context)!.accountHolderName,
                account.accountHolderName ?? 'Not provided',
              ),
              _buildDivider(),
              _buildBankInfoRow(
                context,
                Icons.credit_card,
                AppLocalizations.of(context)!.accountNumber,
                account.accountNumber ?? 'Not provided',
                canCopy: true,
              ),
              _buildDivider(),
              _buildBankInfoRow(
                context,
                Icons.account_balance_wallet,
                AppLocalizations.of(context)!.iban,
                account.ifscCode ?? 'Not provided',
                canCopy: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBankInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String? value, {
    bool canCopy = false,
  }) {
    final displayValue = value ?? 'Not provided';
    final hasValue =
        value != null && value.isNotEmpty && value != 'Not provided';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayValue,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                    color: hasValue ? Colors.black87 : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          if (canCopy && hasValue)
            IconButton(
              icon: Icon(Icons.copy, color: secondary, size: 18),
              onPressed: () => _copyToClipboard(context, displayValue, label),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildJobRolesCard(BuildContext context) {
    final currentLocale = Localizations.localeOf(context).languageCode;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.work, color: Colors.orange, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.jobRoles,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isLoadingCategories)
              Center(child: SizedBox(height: 24, child: Loader()))
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: agent.jobRoles!
                    .map(
                      (role) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [secondary.withOpacity(0.8), secondary],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: secondary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_user,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getLocalizedJobCategory(role, currentLocale),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemInfoCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: Colors.grey[700],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.systemInformation,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildModernInfoRow(
              false,
              context,
              Icons.fingerprint,
              AppLocalizations.of(context)!.userId,
              agent.uid,
              trailing: IconButton(
                icon: Icon(Icons.copy, color: secondary, size: 18),
                onPressed: () =>
                    _copyToClipboard(context, agent.uid ?? '', 'User ID'),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
            _buildDivider(),
            _buildModernInfoRow(
              false,
              context,
              Icons.calendar_today,
              AppLocalizations.of(context)!.createdAt,
              _formatTimestamp(agent.createdAt),
            ),
            _buildDivider(),
            _buildModernInfoRow(
              false,
              context,
              Icons.update,
              AppLocalizations.of(context)!.updatedAt,
              _formatTimestamp(agent.updatedAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernInfoRow(
    bool noChange,
    BuildContext context,
    IconData icon,
    String label,
    String? value, {
    Widget? trailing,
  }) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(color: Colors.grey[300], height: 1, thickness: 1);
  }

  String? _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return null;
    final date = timestamp.toDate();
    final locale = Localizations.localeOf(context).languageCode;
    return DateFormat('dd/MM/yyyy hh:mm a', locale).format(date);
  }

  String _getLocalizedJobCategory(String jobKey, String locale) {
    // Try exact match first
    if (jobCategories.containsKey(jobKey)) {
      return jobCategories[jobKey]![locale] ?? jobKey;
    }
    // Try lowercase match
    if (jobCategories.containsKey(jobKey.toLowerCase())) {
      return jobCategories[jobKey.toLowerCase()]![locale] ?? jobKey;
    }
    // Try finding by value (reverse lookup) if needed, or just return key
    // Sometimes the key stored in user profile might be the English name instead of ID
    for (var entry in jobCategories.entries) {
      if (entry.value['en'] == jobKey || entry.value['ar'] == jobKey) {
        return entry.value[locale] ?? jobKey;
      }
    }

    return jobKey;
  }
}
