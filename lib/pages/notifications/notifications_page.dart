import 'package:aboglumbo_bbk_panel/common_widget/elevated_button.dart';
import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/notification_model.dart';
import 'package:aboglumbo_bbk_panel/pages/chat_screen.dart';
import 'package:aboglumbo_bbk_panel/pages/home/home.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NewNotificationsPage extends StatefulWidget {
  const NewNotificationsPage({super.key});

  @override
  State<NewNotificationsPage> createState() => _NewNotificationsPageState();
}

class _NewNotificationsPageState extends State<NewNotificationsPage> {
  final ScrollController _scrollController = ScrollController();
  final int _itemsPerPage = 30;
  int _currentlyDisplayed = 30;
  bool _isLoadingMore = false;

  // Cache the notifications list
  List<NotificationModel> _cachedNotifications = [];

  late Stream<List<NotificationModel>> _notificationsStream;

  @override
  void initState() {
    super.initState();
    _notificationsStream = AppServices.getNotificationsStream();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _loadMore() {
    if (!_isLoadingMore && _cachedNotifications.length > _currentlyDisplayed) {
      setState(() {
        _isLoadingMore = true;
      });

      // Simulate a small delay for smooth UX
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _currentlyDisplayed += _itemsPerPage;
            _isLoadingMore = false;
          });
        }
      });
    }
  }

  String _getRelativeTime(DateTime dateTime, String lanCode) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    final isAr = lanCode == 'ar';
    final isUr = lanCode == 'ur';

    if (difference.inSeconds < 60) {
      return isAr
          ? 'الآن'
          : isUr
          ? 'ابھی'
          : 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return isAr
          ? 'منذ $minutes دقيقة'
          : isUr
          ? '$minutes منٹ پہلے'
          : '$minutes min ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return isAr
          ? 'منذ $hours ساعة'
          : isUr
          ? '$hours گھنٹے پہلے'
          : '$hours hr ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return isAr
          ? 'منذ $days يوم'
          : isUr
          ? '$days دن پہلے'
          : '$days day${days > 1 ? 's' : ''} ago';
    } else {
      return DateFormat('MMM d, h:mm a').format(dateTime);
    }
  }

  IconData _getNotificationIcon(NotificationModel notification) {
    final type = notification.data['type'] as String?;

    switch (type) {
      case 'booking':
        return Icons.calendar_today_rounded;
      case 'warranty':
        return Icons.verified_user_rounded;
      case 'chat':
        return Icons.chat_bubble_rounded;
      case 'payment':
        return Icons.payment_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getNotificationColor(NotificationModel notification) {
    final type = notification.data['type'] as String?;

    switch (type) {
      case 'booking':
        return Colors.blue;
      case 'warranty':
        return Colors.green;
      case 'chat':
        return Colors.purple;
      case 'payment':
        return Colors.orange;
      default:
        return Colors.indigo;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lanCode = LocalStore.getUserlanguage();
    final isAr = lanCode == 'ar';
    final isUr = lanCode == 'ur';

    return StreamBuilder<List<NotificationModel>>(
      stream: _notificationsStream,
      builder: (context, asyncSnapshot) {
        if (asyncSnapshot.hasData) {
          _cachedNotifications = asyncSnapshot.data!;
        }
        return Scaffold(
          backgroundColor: AppColors.bgWhite,
          appBar: AppBar(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.white,
            title: Text(
              AppLocalizations.of(context)?.notifications ?? 'Notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            actions: [
              if (_cachedNotifications.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep_rounded),
                  tooltip: isAr
                      ? 'حذف الكل'
                      : isUr
                      ? 'سب حذف کریں'
                      : 'Delete All',
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        actionsAlignment: MainAxisAlignment.start,

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        // constraints: const BoxConstraints(maxWidth: 320),
                        backgroundColor: AppColors.bgWhite,
                        title: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              isAr
                                  ? 'حذف الكل'
                                  : isUr
                                  ? 'سب حذف کریں'
                                  : 'Delete All',
                              style: const TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                        content: Text(
                          isAr
                              ? 'هل أنت متأكد أنك تريد حذف جميع الإشعارات؟'
                              : isUr
                              ? 'کیا آپ واقعی تمام اطلاعات حذف کرنا چاہتے ہیں؟'
                              : 'Are you sure you want to delete all notifications?',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 15,
                          ),
                        ),
                        actions: [
                          eButton(
                            context: context,
                            backgroundColor: AppColors.bgWhite,
                            onPressed: () => Navigator.pop(context, false),
                            widget: Text(
                              AppLocalizations.of(context)?.cancel ?? 'Cancel',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                          eButton(
                            onPressed: () => Navigator.pop(context, true),
                            context: context,
                            backgroundColor: Colors.red,
                            text:
                                AppLocalizations.of(context)?.delete ??
                                'Delete',
                            textColor: Colors.white,
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return const Center(child: Loader(size: 40));
                        },
                      );

                      await AppServices.deleteAllFirestoreNotifications();

                      if (context.mounted) {
                        Navigator.pop(context); // Close the loading dialog
                        setState(() {
                          _cachedNotifications.clear();
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            content: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  isAr
                                      ? 'تم حذف جميع الإشعارات'
                                      : isUr
                                      ? 'تمام اطلاعات حذف کر دی گئیں'
                                      : 'All notifications deleted',
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    }
                  },
                ),
            ],
          ),
          body: Builder(
            builder: (context) {
              if (asyncSnapshot.connectionState == ConnectionState.waiting &&
                  _cachedNotifications.isEmpty) {
                return Center(child: SizedBox(height: 24, child: Loader()));
              }

              if (asyncSnapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${asyncSnapshot.error}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              // Update cached notifications when new data arrives
              if (asyncSnapshot.hasData) {
                _cachedNotifications = asyncSnapshot.data!;
              }

              if (_cachedNotifications.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off_outlined,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isAr
                            ? 'لا توجد إشعارات'
                            : isUr
                            ? 'کوئی اطلاع نہیں'
                            : 'No notifications',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isAr
                            ? 'سيتم عرض إشعاراتك هنا'
                            : isUr
                            ? 'آپ کی اطلاعات یہاں ظاہر ہوں گی'
                            : 'Your notifications will appear here',
                        style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                );
              }

              // Get the notifications to display (limited by pagination)
              final displayedNotifications = _cachedNotifications
                  .take(_currentlyDisplayed)
                  .toList();
              final hasMore = _cachedNotifications.length > _currentlyDisplayed;

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: displayedNotifications.length + (hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  // Show loading indicator at the bottom
                  if (index == displayedNotifications.length) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      alignment: Alignment.center,
                      child: _isLoadingMore
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const SizedBox.shrink(),
                    );
                  }

                  final notification = displayedNotifications[index];
                  final isArOrUr = isAr || isUr;

                  // Use fallback if specific language content is missing
                  final title = isArOrUr
                      ? (notification.titleAr.isNotEmpty
                            ? notification.titleAr
                            : notification.titleEn)
                      : (notification.titleEn.isNotEmpty
                            ? notification.titleEn
                            : notification.titleAr);

                  final body = isArOrUr
                      ? (notification.bodyAr.isNotEmpty
                            ? notification.bodyAr
                            : notification.bodyEn)
                      : (notification.bodyEn.isNotEmpty
                            ? notification.bodyEn
                            : notification.bodyAr);

                  final relativeTime = _getRelativeTime(
                    notification.createdAt,
                    lanCode,
                  );
                  final icon = _getNotificationIcon(notification);
                  final iconColor = _getNotificationColor(notification);

                  return Dismissible(
                    key: Key(notification.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: isArOrUr
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.delete_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    onDismissed: (direction) {
                      AppServices.deleteFirestoreNotification(notification.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.grey[800],
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          content: Text(
                            isAr
                                ? 'تم حذف الإشعار'
                                : isUr
                                ? 'اطلاع حذف کر دی گئی'
                                : 'Notification deleted',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: notification.read
                            ? null
                            : Border.all(
                                color: iconColor.withOpacity(0.3),
                                width: 1.5,
                              ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            if (!notification.read) {
                              AppServices.markFirestoreNotificationAsRead(
                                notification.id,
                              );
                            }
                            // Handle navigation based on notification type
                            final type = notification.data['type'] as String?;
                            if (type == 'chat') {
                              // Extract chat data
                              final chatId =
                                  notification.data['chatId'] as String?;
                              final participantName =
                                  notification.data['participantName']
                                      as String? ??
                                  'Customer';
                              final participantId =
                                  notification.data['participantId']
                                      as String? ??
                                  '';
                              final participantPhoto =
                                  notification.data['participantPhoto']
                                      as String? ??
                                  '';
                              final isAdmin =
                                  notification.data['isAdmin'] == 'true';
                              final technicianName =
                                  notification.data['technicianName']
                                      as String? ??
                                  '';
                              final technicianPhoto =
                                  notification.data['technicianPhoto']
                                      as String? ??
                                  '';

                              if (chatId != null && chatId.isNotEmpty) {
                                // Navigate to chat screen
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const Home(),
                                  ),
                                  (route) => false,
                                ).then((_) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          TechnicianChatScreen(
                                            chatId: chatId,
                                            participantName: participantName,
                                            participantId: participantId,
                                            participantPhoto: participantPhoto,
                                            isAdmin: isAdmin,
                                            technicianName: technicianName,
                                            technicianPhoto: technicianPhoto,
                                          ),
                                    ),
                                  );
                                });
                              }
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: notification.read
                                  ? null
                                  : LinearGradient(
                                      begin: isArOrUr
                                          ? Alignment.centerRight
                                          : Alignment.centerLeft,
                                      end: isArOrUr
                                          ? Alignment.centerLeft
                                          : Alignment.centerRight,
                                      colors: [
                                        iconColor.withOpacity(0.03),
                                        Colors.transparent,
                                      ],
                                    ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Icon Container
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: iconColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(icon, color: iconColor, size: 24),
                                ),
                                const SizedBox(width: 12),
                                // Content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              title,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: notification.read
                                                    ? FontWeight.w600
                                                    : FontWeight.bold,
                                                color: Colors.black87,
                                                height: 1.3,
                                              ),
                                            ),
                                          ),
                                          if (!notification.read)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              margin: EdgeInsets.only(
                                                left: isArOrUr ? 0 : 8,
                                                right: isArOrUr ? 8 : 0,
                                              ),
                                              decoration: BoxDecoration(
                                                color: iconColor,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        body,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                          height: 1.4,
                                        ),
                                        maxLines: 10,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time_rounded,
                                            size: 14,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            relativeTime,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[500],
                                              fontWeight: FontWeight.w500,
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
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
