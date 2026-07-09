import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SendNotificationPage extends StatefulWidget {
  const SendNotificationPage({super.key});

  @override
  State<SendNotificationPage> createState() => _SendNotificationPageState();
}

class _SendNotificationPageState extends State<SendNotificationPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _titleEnController = TextEditingController();
  final TextEditingController _bodyEnController = TextEditingController();
  final TextEditingController _titleArController = TextEditingController();
  final TextEditingController _bodyArController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = [];
  Set<String> selectedRecipientIds = {};
  bool _isLoading = false;
  bool _isSending = false;
  String _searchQuery = '';
  String _previewLanguage = 'en'; // 'en' or 'ar' - only for preview
  String _recipientType = 'technician'; // 'technician' or 'customer'

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _titleEnController.dispose();
    _bodyEnController.dispose();
    _titleArController.dispose();
    _bodyArController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      QuerySnapshot snapshot;
      if (_recipientType == 'technician') {
        snapshot = await _firestore
            .collection('users')
            .where('isAdmin', isEqualTo: false)
            .get();
      } else {
        snapshot = await _firestore.collection('customers').get();
      }

      setState(() {
        _allUsers = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          // Ensure role is set correctly for local filtering/logic if needed
          if (_recipientType == 'customer') {
            data['role'] = 'customer';
          }
          return UserModel.fromJson({...data, 'uid': doc.id});
        }).toList();

        _filterUsers();
      });
    } catch (e) {
      if (kDebugMode) print('Error loading $_recipientType: $e');
      _showSnackBar('Error loading $_recipientType');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterUsers() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filteredUsers = _allUsers.where((user) {
        // No longer need to filter by role here as _allUsers is already scoped
        final matchesSearch =
            (user.name?.toLowerCase().contains(_searchQuery) ?? false) ||
            (user.email?.toLowerCase().contains(_searchQuery) ?? false) ||
            (user.phone?.contains(_searchQuery) ?? false);
        return matchesSearch;
      }).toList();
    });
  }

  _showSnackBar(String message, [bool issuccess = false]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: issuccess ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  bool _validateNotifications() {
    final titleEnEmpty = _titleEnController.text.isEmpty;
    final bodyEnEmpty = _bodyEnController.text.isEmpty;
    final titleArEmpty = _titleArController.text.isEmpty;
    final bodyArEmpty = _bodyArController.text.isEmpty;

    if (titleEnEmpty || bodyEnEmpty || titleArEmpty || bodyArEmpty) {
      _showSnackBar(
        AppLocalizations.of(context)!.fillInBothEnglishAndArabicMessageContent,
      );
      return false;
    }

    return true;
  }

  Future<void> _sendNotifications() async {
    if (selectedRecipientIds.isEmpty) {
      _showSnackBar(
        AppLocalizations.of(context)!.pleaseSelectAtLeastOneRecipient,
      );
      return;
    }

    if (!_validateNotifications()) {
      return;
    }

    setState(() => _isSending = true);

    try {
      final batch = _firestore.batch();
      final timestamp = Timestamp.now();

      for (String recipientId in selectedRecipientIds) {
        try {
          // Determine collection based on recipient type
          final String collectionName = _recipientType == 'customer'
              ? 'customers'
              : 'users';

          // Store notification in Firestore with both languages
          final notificationRef = _firestore
              .collection(collectionName)
              .doc(recipientId)
              .collection('notifications')
              .doc();

          batch.set(notificationRef, {
            'titleEn': _titleEnController.text,
            'bodyEn': _bodyEnController.text,
            'titleAr': _titleArController.text,
            'bodyAr': _bodyArController.text,
            'createdAt': timestamp,
            'read': false,
            'data': {'type': 'custom'},
          });

          // Create queue document to trigger Cloud Function
          final queueRef = _firestore.collection('notification_queue').doc();

          batch.set(queueRef, {
            'recipientId': recipientId,
            'recipientCollection': collectionName, // Added to help backend
            'titleEn': _titleEnController.text,
            'bodyEn': _bodyEnController.text,
            'titleAr': _titleArController.text,
            'bodyAr': _bodyArController.text,
            'createdAt': timestamp,
            'processed': false,
          });
        } catch (e) {
          if (kDebugMode) {
            print('Error processing recipient $recipientId: $e');
          }
        }
      }

      await batch.commit();

      if (mounted) {
        _showSnackBar(
          AppLocalizations.of(
            context,
          )!.notificationSenttoTechnicians(selectedRecipientIds.length),
          true,
        );

        // Reset form
        _titleEnController.clear();
        _bodyEnController.clear();
        _titleArController.clear();
        _bodyArController.clear();
        selectedRecipientIds.clear();
        _searchController.clear();
      }
    } catch (e) {
      if (kDebugMode) print('Error sending notifications: $e');
      _showSnackBar(AppLocalizations.of(context)!.errorSendingNotifications);
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _showRecipientBottomSheet() {
    _searchController.clear();
    _filterUsers();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Material(
                                elevation: 1,
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.people,
                                    color: Colors.black,
                                    size: 24,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.selectRecipients,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    if (selectedRecipientIds.isNotEmpty)
                                      Text(
                                        '${selectedRecipientIds.length} ${AppLocalizations.of(context)!.selected}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Search Bar
                          TextField(
                            controller: _searchController,
                            onChanged: (_) =>
                                setModalState(() => _filterUsers()),
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(
                                context,
                              )!.searchByNameEmailOrPhone,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        setModalState(() => _filterUsers());
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Technicians List
                    Expanded(
                      child: _filteredUsers.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 48,
                                    color: Colors.grey[300],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _searchQuery.isEmpty
                                        ? AppLocalizations.of(
                                            context,
                                          )!.noAgentsAvailable
                                        : AppLocalizations.of(
                                            context,
                                          )!.noAgentsAvailable,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              itemCount: _filteredUsers.length,
                              separatorBuilder: (_, __) =>
                                  Divider(height: 1, color: Colors.grey[200]),
                              itemBuilder: (context, index) {
                                final user = _filteredUsers[index];
                                final isSelected = selectedRecipientIds
                                    .contains(user.uid);

                                return CheckboxListTile(
                                  activeColor: AppColors.primary,
                                  value: isSelected,
                                  onChanged: (value) {
                                    setModalState(() {
                                      if (value == true) {
                                        selectedRecipientIds.add(
                                          user.uid ?? '',
                                        );
                                      } else {
                                        selectedRecipientIds.remove(user.uid);
                                      }
                                    });
                                    setState(() {});
                                  },
                                  title: Text(user.name ?? 'Unknown'),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (user.email?.isNotEmpty == true)
                                        Text(
                                          user.email!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      if (user.phone?.isNotEmpty == true)
                                        Text(
                                          user.phone!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      if (user.fcmToken == null ||
                                          user.fcmToken!.isEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4.0,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.warning,
                                                size: 12,
                                                color: Colors.orange,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                AppLocalizations.of(
                                                  context,
                                                )!.noFcmTokenAvailable,
                                                style: TextStyle(
                                                  color: Colors.orange,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  secondary: CircleAvatar(
                                    backgroundColor: isSelected
                                        ? AppColors.primary
                                        : Colors.grey[300],
                                    child: Text(
                                      user.name?.isNotEmpty == true
                                          ? user.name![0].toUpperCase()
                                          : 'T',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    // Footer with Select All / Deselect All
                    if (_filteredUsers.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.grey[300]!, width: 1),
                          ),
                        ),
                        child: Row(
                          children: [
                            if (selectedRecipientIds.isNotEmpty)
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadiusGeometry.circular(8),
                                    ),
                                    backgroundColor: AppColors.bgWhite,
                                  ),
                                  onPressed: () {
                                    setModalState(() {
                                      selectedRecipientIds.clear();
                                    });
                                    setState(() {});
                                  },
                                  child: Text(
                                    AppLocalizations.of(context)!.removeAll,
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ),
                              )
                            else
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    setModalState(() {
                                      for (var user in _filteredUsers) {
                                        selectedRecipientIds.add(
                                          user.uid ?? '',
                                        );
                                      }
                                    });
                                    setState(() {});
                                  },
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadiusGeometry.circular(8),
                                    ),
                                    backgroundColor: AppColors.primary,
                                  ),
                                  child: Text(
                                    AppLocalizations.of(context)!.selectAll,
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadiusGeometry.circular(
                                      8,
                                    ),
                                  ),
                                  backgroundColor: AppColors.primary,
                                ),
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  AppLocalizations.of(context)!.done,
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
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
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
        ),
        title: Text(
          AppLocalizations.of(context)!.manageNotificationAlerts,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        shape: Border.all(style: BorderStyle.none),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLanguageTabs(),
                  const SizedBox(height: 16),
                  _buildPreviewCard(),
                  const SizedBox(height: 16),
                  _buildMessageCompositionCard(),
                  const SizedBox(height: 16),
                  _buildRecipientTypeSelector(),
                  const SizedBox(height: 16),
                  _buildSelectedRecipientsCard(),
                  const SizedBox(height: 24),
                  _buildSendButton(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipientTypeSelector() {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Material(
                  elevation: 1,
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.translate, color: Colors.black, size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.selectRecipientType,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: Material(
                    elevation: 1,
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    child: GestureDetector(
                      onTap: () {
                        if (_recipientType != 'technician') {
                          setState(() {
                            _recipientType = 'technician';
                            selectedRecipientIds.clear();
                          });
                          _loadUsers();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _recipientType == 'technician'
                              ? AppColors.primary
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            AppLocalizations.of(context)!.technician,
                            style: TextStyle(
                              color: _recipientType == 'technician'
                                  ? Colors.white
                                  : Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Material(
                    elevation: 1,
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    child: GestureDetector(
                      onTap: () {
                        if (_recipientType != 'customer') {
                          setState(() {
                            _recipientType = 'customer';
                            selectedRecipientIds.clear();
                          });
                          _loadUsers();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _recipientType == 'customer'
                              ? AppColors.primary
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            AppLocalizations.of(context)!.customer,
                            style: TextStyle(
                              color: _recipientType == 'customer'
                                  ? Colors.white
                                  : Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageTabs() {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Material(
                  elevation: 1,
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.translate, color: Colors.black, size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.previewLanguage,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Material(
                    elevation: 1,
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    child: GestureDetector(
                      onTap: () => setState(() => _previewLanguage = 'en'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _previewLanguage == 'en'
                              ? AppColors.primary
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.english,
                              style: TextStyle(
                                color: _previewLanguage == 'en'
                                    ? Colors.white
                                    : AppColors.black1,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Material(
                    elevation: 1,
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    child: GestureDetector(
                      onTap: () => setState(() => _previewLanguage = 'ar'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _previewLanguage == 'ar'
                              ? AppColors.primary
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.arabic,
                              style: TextStyle(
                                color: _previewLanguage == 'ar'
                                    ? Colors.white
                                    : AppColors.black1,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageCompositionCard() {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Material(
                  elevation: 1,
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.edit, color: Colors.black, size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.composeMessage,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // English Section
            _buildLanguageSection(
              language: AppLocalizations.of(context)!.english,
              languageFlag: '🇬🇧',
              titleController: _titleEnController,
              bodyController: _bodyEnController,
              isArabic: false,
            ),
            const SizedBox(height: 24),
            Divider(color: Colors.grey[300], thickness: 1),
            const SizedBox(height: 24),
            // Arabic Section
            _buildLanguageSection(
              language: AppLocalizations.of(context)!.arabic,
              languageFlag: '🇸🇦',
              titleController: _titleArController,
              bodyController: _bodyArController,
              isArabic: Directionality.of(context) == TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSection({
    required String language,
    required String languageFlag,
    required TextEditingController titleController,
    required TextEditingController bodyController,
    required bool isArabic,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Language Header
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Text(languageFlag, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                language,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        // Title Field
        TextField(
          cursorColor: Colors.black,
          controller: titleController,
          maxLength: 80,
          maxLines: 1,
          onChanged: (_) => setState(() {}),
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.notificationTitle,
            labelText: AppLocalizations.of(context)!.title,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.black),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.black),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.black),
            ),
            prefixIcon: isArabic ? null : const Icon(Icons.subject),
            suffixIcon: isArabic ? const Icon(Icons.subject) : null,
            counterText: '${titleController.text.length}/80',
          ),
        ),
        const SizedBox(height: 12),
        // Body Field
        TextField(
          cursorColor: Colors.black,
          controller: bodyController,
          maxLength: 500,
          maxLines: 4,
          onChanged: (_) => setState(() {}),
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(
              context,
            )!.enterYourNotificationMessageHere,
            labelText: AppLocalizations.of(context)!.message,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.black),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.black),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.black),
            ),
            alignLabelWithHint: true,
            prefixIcon: isArabic ? null : const Icon(Icons.message),
            suffixIcon: isArabic ? const Icon(Icons.message) : null,
            counterText: '${bodyController.text.length}/500',
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewCard() {
    final isEnglish = _previewLanguage == 'en';
    final titleText = isEnglish
        ? _titleEnController.text
        : _titleArController.text;
    final bodyText = isEnglish
        ? _bodyEnController.text
        : _bodyArController.text;
    final hasContent = titleText.isNotEmpty || bodyText.isNotEmpty;

    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Material(
                  elevation: 1,
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.visibility,
                      color: Colors.black,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.preview,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Notification Preview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status bar simulation
                  !isEnglish
                      ? Row(
                          children: [
                            ...isEnglish
                                ? [
                                    const Icon(
                                      Icons.signal_cellular_alt,
                                      size: 14,
                                      color: Colors.white70,
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.wifi,
                                      size: 14,
                                      color: Colors.white70,
                                    ),
                                  ]
                                : [
                                    const Icon(
                                      Icons.wifi,
                                      size: 14,
                                      color: Colors.white70,
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.signal_cellular_alt,
                                      size: 14,
                                      color: Colors.white70,
                                    ),
                                  ],
                            const Spacer(),
                            Text(
                              '9:41',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Text(
                              '9:41',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[400],
                              ),
                            ),
                            const Spacer(),
                            ...isEnglish
                                ? [
                                    const Icon(
                                      Icons.signal_cellular_alt,
                                      size: 14,
                                      color: Colors.white70,
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.wifi,
                                      size: 14,
                                      color: Colors.white70,
                                    ),
                                  ]
                                : [
                                    const Icon(
                                      Icons.wifi,
                                      size: 14,
                                      color: Colors.white70,
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.signal_cellular_alt,
                                      size: 14,
                                      color: Colors.white70,
                                    ),
                                  ],
                          ],
                        ),
                  const SizedBox(height: 16),
                  // Notification Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[700]!, width: 1),
                    ),
                    child: Directionality(
                      textDirection: isEnglish
                          ? TextDirection.ltr
                          : TextDirection.rtl,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.notifications,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _recipientType == "technician"
                                      ? "Abo Glumbo - Technician"
                                      : "Abo Glumbo - Customer",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[200],
                                  ),
                                ),
                              ),
                              Text(
                                isEnglish ? 'now' : 'الان',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (titleText.isNotEmpty)
                            Text(
                              titleText,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textDirection: isEnglish
                                  ? TextDirection.ltr
                                  : TextDirection.rtl,
                            )
                          else
                            Text(
                              isEnglish
                                  ? 'Notification Title'
                                  : 'عنوان الإشعار',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[500],
                              ),
                            ),
                          if (titleText.isNotEmpty) const SizedBox(height: 4),
                          if (bodyText.isNotEmpty)
                            Text(
                              bodyText,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[300],
                                height: 1.4,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              textDirection: isEnglish
                                  ? TextDirection.ltr
                                  : TextDirection.rtl,
                            )
                          else if (hasContent)
                            Text(
                              isEnglish
                                  ? 'Your message will appear here'
                                  : 'ستظهر رسالتك هنا',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[500],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedRecipientsCard() {
    final selectedUsers = _allUsers
        .where((user) => selectedRecipientIds.contains(user.uid))
        .toList();

    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Material(
                  elevation: 1,
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.people, color: Colors.black, size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.recipients,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        '${selectedRecipientIds.length} ${AppLocalizations.of(context)!.recipientsSelected}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selectedRecipientIds.isNotEmpty) ...{
                  IconButton(
                    onPressed: _showRecipientBottomSheet,
                    icon: const Icon(Icons.edit),
                  ),
                },
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(child: SizedBox(height: 48, child: Loader())),
              )
            else if (selectedUsers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _showRecipientBottomSheet,
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: Text(
                          AppLocalizations.of(context)!.addRecipients,
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSending ? null : _sendNotifications,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSending
            ? SizedBox(height: 24, width: 24, child: Loader(size: 20))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.sendNotification,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
