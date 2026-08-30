import 'dart:convert';
import 'package:aboglumbo_bbk_panel/pages/chat_screen.dart';
import 'package:aboglumbo_bbk_panel/pages/home/home.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io' show Platform;
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'app_services.dart';
import '../main.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📨 Background message received: ${message.messageId}');
  final data = message.data;
  if (message.notification == null && (data['type'] == 'custom' || data.containsKey('titleEn'))) {
    try {
      String title = data['titleEn'] ?? data['title'] ?? 'Notification';
      String body = data['bodyEn'] ?? data['body'] ?? '';
      
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings();
      const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid, iOS: initializationSettingsDarwin);
      await flutterLocalNotificationsPlugin.initialize(initializationSettings);
      
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'abo_glumbo_channel', 'Abo Glumbo Notifications',
        channelDescription: 'Notifications related to Abo Glumbo tasks and updates',
        importance: Importance.max, priority: Priority.high,
      );
      const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails();
      const NotificationDetails platformDetails = NotificationDetails(android: androidDetails, iOS: iOSDetails);
      
      await flutterLocalNotificationsPlugin.show(
        message.hashCode, title, body, platformDetails,
        payload: json.encode(data),
      );
    } catch (e) {
      debugPrint('❌ Error showing background data notification: $e');
    }
  }
  // Note: Notification is already stored by backend in sendAndStoreNotification
  // No need to store it again here to avoid duplicates
}

class NotificationServices {
  static bool _isInitialized = false;
  static bool _tokenRefreshListenerSet = false;
  static bool _isRequestingPermission =
      false; // NEW: Prevent duplicate requests

  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin
  _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Track the current active chat to suppress notifications when user is inside the chat
  static String? currentActiveChatId;

  /// Set the current active chat ID
  static void setActiveChatId(String? chatId) {
    currentActiveChatId = chatId;
    debugPrint('🔔 Active chat set to: $chatId');
  }

  /// Clear the current active chat ID safely to prevent race conditions
  static void clearActiveChatId(String? chatId) {
    if (chatId == null || currentActiveChatId == chatId) {
      currentActiveChatId = null;
      debugPrint('🔔 Active chat cleared for: $chatId');
    } else {
      debugPrint(
        '🔔 Ignoring clearActiveChatId for $chatId (current active is: $currentActiveChatId)',
      );
    }
  }

  /// Check if the user is currently actively viewing the given chat
  static bool isChatActive(String? chatId) {
    if (currentActiveChatId == null) return false;
    // If the incoming notification has no chatId, we can't confirm it belongs
    // to the active conversation — let it through so it's never silently lost.
    if (chatId == null || chatId.isEmpty) return false;
    return currentActiveChatId == chatId;
  }

  /// Initialize local notifications
  static Future<void> initializeNotifications() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsDarwin,
          );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('👆 Notification tapped: ${response.payload}');
          _handleNotificationTap(response.payload);
        },
      );

      // Android 8+ drops any notification posted to a channel that does not
      // exist yet. The backend targets 'abo_glumbo_channel' by name, so create
      // it up front instead of relying on the first foreground notification to
      // bring it into existence.
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              'abo_glumbo_channel',
              'Abo Glumbo Notifications',
              description:
                  'Notifications related to Abo Glumbo tasks and updates',
              importance: Importance.max,
            ),
          );

      // Request notification permissions explicitly on both iOS and Android
      if (Platform.isIOS) {
        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
      } else if (Platform.isAndroid) {
        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
      }

      debugPrint('✅ Local notifications initialized with permissions');
    } catch (e) {
      debugPrint('❌ Error initializing local notifications: $e');
    }
  }

  /// Setup FCM listeners with duplicate request prevention
  static Future<void> setupFCMListeners() async {
    // Prevent duplicate permission requests
    if (_isRequestingPermission) {
      debugPrint('⚠️ Permission request already in progress, skipping...');
      return;
    }

    if (_isInitialized) {
      debugPrint('⚠️ FCM already initialized, skipping...');
      return;
    }

    try {
      _isRequestingPermission = true;

      // Set foreground notification options
      // Disable alert presentation so iOS doesn't automatically show APNs banner
      // in foreground, allowing onMessage to suppress or display via local notifications.
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: false,
            badge: false,
            sound: false,
          );

      // Request permission
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(alert: true, badge: true, sound: true);

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('✅ FCM permission granted');

        // Get FCM token
        await _getFCMTokenAndUpdate();

        // Setup token refresh listener
        _setupTokenRefreshListener();

        // Setup message handlers
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint('📨 Foreground message received: ${message.messageId}');

          final data = message.data;
          final String? incomingChatId = data['chatId']?.toString();
          final String? type = data['type']?.toString();

          // ONLY chat notifications can ever be suppressed when user is in chat screen
          final bool isChatNotification =
              type == 'chat' || (incomingChatId != null && incomingChatId.isNotEmpty);

          if (isChatNotification && isChatActive(incomingChatId)) {
            debugPrint(
              '🤫 Suppressing chat push notification because user is inside active chat: $incomingChatId (currentActiveChatId: $currentActiveChatId)',
            );
            return;
          }

          // ALL OTHER NOTIFICATIONS (job_offer, booking, warranty, custom, etc.)
          // MUST appear as a push notification, even if user is currently inside chatscreen!
          debugPrint(
            '🔔 Showing push notification for foreground message (type: $type, chatId: $incomingChatId)',
          );

          RemoteNotification? notification = message.notification;
          String? title = notification?.title ?? data['title'];
          String? body = notification?.body ?? data['body'];

          if (title == null || body == null || title.isEmpty) {
            String lang = 'en';
            try {
              lang = LocalStore.getUserlanguage();
            } catch (e) {
              lang = 'en';
            }
            String capLang = lang.isNotEmpty
                ? lang.substring(0, 1).toUpperCase() + lang.substring(1)
                : 'En';
            title ??= data['title$capLang'] ?? data['titleEn'] ?? 'Notification';
            body ??= data['body$capLang'] ?? data['bodyEn'] ?? '';
          }

          showNotification(
            id: (notification?.hashCode ?? message.hashCode) & 0x7FFFFFFF,
            title: title ?? 'Notification',
            body: body ?? '',
            payload: json.encode(message.data),
          );
        });

        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          debugPrint('👆 Message opened from background: ${message.messageId}');
          if (message.notification != null) {
            _handleGenericNotificationTap(message);
          }
        });

        _isInitialized = true;
        debugPrint('✅ FCM listeners setup complete');
      } else {
        debugPrint('❌ FCM permission denied');
      }
    } catch (e) {
      debugPrint('❌ Error setting up FCM: $e');

      // Handle "already running" error gracefully
      if (e.toString().contains('already running')) {
        debugPrint(
          '⚠️ Permission request already running - marking as initialized',
        );
        _isInitialized = true;
      }
    } finally {
      _isRequestingPermission = false;
    }
  }

  /// Get FCM token and update in Firestore
  static Future<void> _getFCMTokenAndUpdate() async {
    try {
      String? token;

      if (Platform.isIOS) {
        // Wait for APNS token with timeout on iOS
        await _waitForAPNSToken();
        token = await _firebaseMessaging.getToken();
      } else {
        token = await _firebaseMessaging.getToken();
      }

      if (token != null && token.isNotEmpty) {
        await AppServices.updateFCMToken(token);
      } else {
        debugPrint('⚠️ No FCM token available');
      }
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
    }
  }

  /// Wait for APNS token on iOS
  static Future<void> _waitForAPNSToken() async {
    try {
      String? apnsToken = await _firebaseMessaging.getAPNSToken();
      int attempts = 0;

      while (apnsToken == null && attempts < 20) {
        await Future.delayed(const Duration(milliseconds: 500));
        apnsToken = await _firebaseMessaging.getAPNSToken();
        attempts++;
      }

      if (apnsToken != null) {
        debugPrint('✅ APNS token obtained');
      } else {
        debugPrint('⚠️ APNS token not available after 10 seconds');
      }
    } catch (e) {
      debugPrint('❌ Error waiting for APNS token: $e');
    }
  }

  /// Setup token refresh listener
  static void _setupTokenRefreshListener() {
    if (_tokenRefreshListenerSet) {
      debugPrint('⚠️ Token refresh listener already set');
      return;
    }

    _firebaseMessaging.onTokenRefresh.listen(
      (fcmToken) {
        if (fcmToken.isNotEmpty) {
          debugPrint('🔄 FCM Token refreshed: ${fcmToken.substring(0, 20)}...');
          AppServices.updateFCMToken(fcmToken)
              .then((_) {
                debugPrint('✅ Refreshed FCM Token updated successfully');
              })
              .catchError((error) {
                debugPrint('❌ Error updating refreshed FCM token: $error');
              });
        }
      },
      onError: (error) {
        debugPrint('❌ Error in token refresh listener: $error');
      },
    );

    _tokenRefreshListenerSet = true;
    debugPrint('✅ Token refresh listener set up');
  }

  /// Manually refresh FCM token (use sparingly)
  static Future<void> refreshFCMToken() async {
    if (_isRequestingPermission) {
      debugPrint('⚠️ Cannot refresh token - permission request in progress');
      return;
    }

    try {
      debugPrint('🔄 Manually refreshing FCM token...');
      await _firebaseMessaging.deleteToken();
      await Future.delayed(const Duration(milliseconds: 500));
      await _getFCMTokenAndUpdate();
    } catch (e) {
      debugPrint('❌ Error manually refreshing FCM token: $e');
    }
  }

  /// Get current FCM token
  static Future<String?> getCurrentFCMToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        debugPrint('🔑 Current FCM Token: ${token.substring(0, 20)}...');
      } else {
        debugPrint('❌ No FCM token available');
      }
      return token;
    } catch (e) {
      debugPrint('❌ Error getting current FCM token: $e');
      return null;
    }
  }

  /// Delete FCM token
  static Future<void> deleteFCMToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      debugPrint('🗑️ FCM token deleted successfully');
    } catch (e) {
      debugPrint('❌ Error deleting FCM token: $e');
    }
  }

  /// Debug FCM status
  static Future<void> debugFCMStatus() async {
    try {
      debugPrint('🔍 FCM Debug Status:');
      debugPrint('   - Initialized: $_isInitialized');
      debugPrint('   - Token refresh listener set: $_tokenRefreshListenerSet');
      debugPrint('   - Requesting permission: $_isRequestingPermission');

      String? token = await getCurrentFCMToken();
      if (token != null) {
        debugPrint('   - Current token available: Yes');
        debugPrint('   - Token length: ${token.length}');
      } else {
        debugPrint('   - Current token available: No');
      }

      if (Platform.isIOS) {
        String? apnsToken = await _firebaseMessaging.getAPNSToken();
        debugPrint(
          '   - APNS Token available: ${apnsToken != null ? "Yes" : "No"}',
        );
      }

      NotificationSettings settings = await _firebaseMessaging
          .getNotificationSettings();
      debugPrint('   - Permission status: ${settings.authorizationStatus}');
    } catch (e) {
      debugPrint('❌ Error getting FCM debug status: $e');
    }
  }

  /// Show local notification
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'abo_glumbo_channel',
          'Abo Glumbo Notifications',
          channelDescription:
              'Notifications related to Abo Glumbo tasks and updates',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          enableVibration: true,
          playSound: true,
          visibility: NotificationVisibility.public,
          enableLights: true,
          icon: '@mipmap/ic_launcher',
        );

    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  /// Check for initial message (app opened from terminated state)
  static Future<void> checkForInitialMessage() async {
    try {
      RemoteMessage? initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();

      if (initialMessage != null) {
        debugPrint('📬 Initial message found: ${initialMessage.messageId}');
        if (initialMessage.notification != null) {
          _handleGenericNotificationTap(initialMessage);
        }
      }

      // Note: onMessageOpenedApp listener is already set up in setupFCMListeners()
      // No need to add it here again to avoid duplicate navigation
    } catch (e) {
      debugPrint('❌ Error checking initial message: $e');
    }
  }

  /// Handle notification tap and navigate accordingly
  static void _handleNotificationTap(String? payload) {
    if (payload == null || payload.isEmpty) {
      debugPrint('⚠️ No payload in notification');
      return;
    }

    try {
      final data = json.decode(payload) as Map<String, dynamic>;
      debugPrint('📱 Full notification payload: $data');

      final type = data['type'] as String?;
      final chatId = data['chatId'] as String?;

      debugPrint('📱 Notification type: $type, chatId: $chatId');

      // Check if this is a chat notification (either by type or presence of chatId)
      if (type == 'chat' || (chatId != null && chatId.isNotEmpty)) {
        // Extract chat data from payload
        final participantName =
            data['participantName'] as String? ?? 'Customer';
        final participantId = data['participantId'] as String? ?? '';
        final participantPhoto = data['participantPhoto'] as String? ?? '';
        final isAdmin = data['isAdmin'] == 'true';
        final technicianName = data['technicianName'] as String? ?? '';
        final technicianPhoto = data['technicianPhoto'] as String? ?? '';

        debugPrint('💬 Chat notification detected!');
        debugPrint('   chatId: $chatId');
        debugPrint('   participantName: $participantName');
        debugPrint('   participantId: $participantId');

        if (chatId != null && chatId.isNotEmpty) {
          debugPrint('🚀 Starting navigation to chat screen...');

          // Use the global navigator key to navigate
          if (navigatorKey?.currentState != null) {
            debugPrint('✅ Navigator is available');

            // Clear stack and set up: Home -> ChatScreen
            // This ensures back button from chat goes directly to home
            navigatorKey!.currentState!.pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const Home()),
              (route) => false,
            );

            // Immediately push chat screen on top of home
            navigatorKey!.currentState!
                .push(
                  MaterialPageRoute(
                    builder: (context) => TechnicianChatScreen(
                      chatId: chatId,
                      participantName: participantName,
                      participantId: participantId,
                      participantPhoto: participantPhoto,
                      isAdmin: isAdmin,
                      technicianName: technicianName,
                      technicianPhoto: technicianPhoto,
                    ),
                  ),
                )
                .then((_) {
                  debugPrint('✅ Chat screen navigation completed');
                })
                .catchError((error) {
                  debugPrint('❌ Error pushing chat screen: $error');
                });
          } else {
            debugPrint('⚠️ Navigator key is null, cannot navigate');
          }
        } else {
          debugPrint('⚠️ Chat ID is missing in notification payload');
        }
      }
      // Check if this is a job offer notification
      else if (type == 'job_offer' || data['category'] == 'job_offer') {
        debugPrint('📋 Job offer notification detected!');
        if (navigatorKey?.currentState != null) {
          navigatorKey!.currentState!.pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const Home(
                newIndex: 1, // Orders tab
                selectedFilter: 'P', // Pending filter (which shows job offers)
              ),
            ),
            (route) => false,
          );
        }
      }
      // Check if this is a booking notification
      else if (type == 'booking' || data['category'] == 'booking') {
        debugPrint('📋 Booking notification detected!');
        if (navigatorKey?.currentState != null) {
          final isAdmin = data['isAdmin'] == 'true';
          navigatorKey!.currentState!.pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => Home(
                newIndex: 1, // Orders tab
                selectedFilter: isAdmin
                    ? 'P'
                    : 'A', // Pending for admin, Accepted for technician
              ),
            ),
            (route) => false,
          );
        }
      } else {
        debugPrint('ℹ️ Not a recognized notification type, ignoring');
      }
    } catch (e) {
      debugPrint('❌ Error handling notification tap: $e');
    }
  }

  /// Handle chat notification tap (extracted for reuse)
  static void _handleChatNotificationTap(RemoteMessage message) {
    try {
      final data = message.data;
      debugPrint('📱 Chat notification data: $data');

      final chatId = data['chatId'] as String?;
      final participantName = data['participantName'] as String? ?? 'Customer';
      final participantId = data['participantId'] as String? ?? '';
      final participantPhoto = data['participantPhoto'] as String? ?? '';
      final isAdmin = data['isAdmin'] == 'true';
      final technicianName = data['technicianName'] as String? ?? '';
      final technicianPhoto = data['technicianPhoto'] as String? ?? '';

      debugPrint('💬 Navigating to chat screen...');
      debugPrint('   chatId: $chatId');
      debugPrint('   participantName: $participantName');
      debugPrint('   participantId: $participantId');

      if (chatId != null && chatId.isNotEmpty) {
        // Use the global navigator key to navigate
        if (navigatorKey?.currentState != null) {
          debugPrint('✅ Navigator is available');

          // Clear stack and set up: Home -> ChatScreen
          // This ensures back button from chat goes directly to home
          navigatorKey!.currentState!.pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const Home()),
            (route) => false,
          );

          // Immediately push chat screen on top of home
          navigatorKey!.currentState!
              .push(
                MaterialPageRoute(
                  builder: (context) => TechnicianChatScreen(
                    chatId: chatId,
                    participantName: participantName,
                    participantId: participantId,
                    participantPhoto: participantPhoto,
                    isAdmin: isAdmin,
                    technicianName: technicianName,
                    technicianPhoto: technicianPhoto,
                  ),
                ),
              )
              .then((_) {
                debugPrint('✅ Chat screen navigation completed');
              })
              .catchError((error) {
                debugPrint('❌ Error pushing chat screen: $error');
              });
        } else {
          debugPrint('⚠️ Navigator key is null, cannot navigate');
        }
      } else {
        debugPrint('⚠️ Chat ID is missing in notification payload');
      }
    } catch (e) {
      debugPrint('❌ Error handling chat notification tap: $e');
    }
  }

  /// Handle generic notification tap from background (extracted for reuse)
  static void _handleGenericNotificationTap(RemoteMessage message) {
    try {
      final data = message.data;
      final type = data['type'] as String?;
      final category = data['category'] as String?;

      if (type == 'chat' || data['chatId'] != null) {
        _handleChatNotificationTap(message);
      } else if (type == 'job_offer' || category == 'job_offer') {
        debugPrint('📋 Job offer notification detected from background!');
        if (navigatorKey?.currentState != null) {
          navigatorKey!.currentState!.pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const Home(
                newIndex: 1,
                selectedFilter: 'P', // Pending filter
              ),
            ),
            (route) => false,
          );
        }
      } else if (type == 'booking' || category == 'booking') {
        debugPrint('📋 Booking notification detected from background!');
        if (navigatorKey?.currentState != null) {
          final isAdmin = data['isAdmin'] == 'true';
          navigatorKey!.currentState!.pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => Home(
                newIndex: 1, // Orders tab
                selectedFilter: isAdmin
                    ? 'P'
                    : 'A', // Pending for admin, Accepted for technician
              ),
            ),
            (route) => false,
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error handling background notification tap: $e');
    }
  }

  /// Initialize FCM (legacy method - keeping for compatibility)
  static Future<void> initializeFCM() async {
    try {
      await setupFCMListeners();
    } catch (e) {
      debugPrint('❌ Error initializing FCM: $e');
    }
  }
}
