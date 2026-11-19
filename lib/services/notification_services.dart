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
        'abo_glumbo_channel', 'Aboglumbo Technician Notifications',
        channelDescription: 'Notifications related to Aboglumbo Technician tasks and updates',
        importance: Importance.max, priority: Priority.high,
      );
      const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails();
      const NotificationDetails platformDetails = NotificationDetails(android: androidDetails, iOS: iOSDetails);
      
      await flutterLocalNotificationsPlugin.show(
        message.hashCode, title, body, platformDetails,
        payload: json.encode(data),
      );
    } catch (_) {
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

  /// Probes that report which chat is genuinely in front of the user, asked
  /// at the moment a message arrives rather than recorded when the screen
  /// opens.
  ///
  /// A stored "user is viewing chat X" flag is only ever as trustworthy as the
  /// event that clears it, and the two events that matter most - the app being
  /// swiped away and the app being backgrounded - are exactly the ones the
  /// process may not survive long enough to deliver. There is nothing to go
  /// stale here because there is no transition to miss: if the screen is gone
  /// so is its probe, and if the whole process is gone the push is rendered by
  /// the system tray with no client involvement at all.
  ///
  /// A list rather than a single slot so that stacked chat screens unwind
  /// correctly - each probe answers only for itself, and a screen buried under
  /// another route reports null on its own.
  static final List<String? Function()> _activeChatProbes = [];

  /// Called by a chat screen while it is on screen. Pass the same function
  /// object to [unregisterActiveChatProbe] when the screen is disposed.
  static void registerActiveChatProbe(String? Function() probe) {
    if (!_activeChatProbes.contains(probe)) {
      _activeChatProbes.add(probe);
    }
  }

  static void unregisterActiveChatProbe(String? Function() probe) {
    _activeChatProbes.remove(probe);
  }

  /// The chat the user is looking at right now, or null if none is.
  static String? get currentActiveChatId {
    for (final probe in _activeChatProbes) {
      try {
        final chatId = probe();
        if (chatId != null && chatId.isNotEmpty) return chatId;
      } catch (e) {
        // A probe that throws must never cost the user a notification.
      }
    }
    return null;
  }

  /// Check if the user is currently actively viewing the given chat
  static bool isChatActive(String? chatId) {
    // If the incoming notification has no chatId, we can't confirm it belongs
    // to the active conversation - let it through so it's never silently lost.
    if (chatId == null || chatId.isEmpty) return false;
    return currentActiveChatId == chatId;
  }

  /// Notification taps that have already been navigated for, keyed by the
  /// FCM message id.
  ///
  /// One tap can be reported twice. Handling the launch intent, the Android
  /// plugin BOTH emits `onMessageOpenedApp` and stores the message for
  /// `getInitialMessage()` - and that getter's fast path hands the stored copy
  /// back without consulting the plugin's own consumed-message set:
  ///
  ///     if (initialMessage != null) { ...setResult(...); initialMessage = null; }
  ///
  /// Navigating from the tap rebuilds Home, whose init calls
  /// `checkForInitialMessage()` again once its startup location fix resolves,
  /// and that replay opened a second copy of the chat screen on top of the
  /// first - which is why the chat appeared to reload a few seconds in.
  static final Set<String> _handledTapIds = <String>{};

  /// Claims [id] for this tap, returning false if it has already been handled.
  static bool _claimTapId(String? id) {
    if (id == null || id.isEmpty) return true; // nothing to key on, let it run

    if (_handledTapIds.contains(id)) {
      return false;
    }

    // Claim it only once there is a navigator to act on, so a tap arriving
    // before the app has a route stack is retried rather than swallowed.
    if (navigatorKey?.currentState == null) return true;

    _handledTapIds.add(id);
    if (_handledTapIds.length > 50) {
      _handledTapIds.remove(_handledTapIds.first);
    }
    return true;
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
              'Aboglumbo Technician Notifications',
              description:
                  'Notifications related to Aboglumbo Technician tasks and updates',
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

    } catch (_) {
    }
  }

  /// Setup FCM listeners with duplicate request prevention
  static Future<void> setupFCMListeners() async {
    // Prevent duplicate permission requests
    if (_isRequestingPermission) {
      return;
    }

    if (_isInitialized) {
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
        // Get FCM token
        await _getFCMTokenAndUpdate();

        // Setup token refresh listener
        _setupTokenRefreshListener();

        // Setup message handlers
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          final data = message.data;
          final String? incomingChatId = data['chatId']?.toString();
          final String? type = data['type']?.toString();

          // ONLY chat notifications can ever be suppressed when user is in chat screen
          final bool isChatNotification =
              type == 'chat' || (incomingChatId != null && incomingChatId.isNotEmpty);

          if (isChatNotification && isChatActive(incomingChatId)) {
            return;
          }

          // ALL OTHER NOTIFICATIONS (job_offer, booking, warranty, custom, etc.)
          // MUST appear as a push notification, even if user is currently inside chatscreen!

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
          if (message.notification != null) {
            _handleGenericNotificationTap(message);
          }
        });

        _isInitialized = true;
      }
    } catch (e) {
      // Handle "already running" error gracefully
      if (e.toString().contains('already running')) {
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
      }
    } catch (_) {
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
    } catch (_) {
    }
  }

  /// Setup token refresh listener
  static void _setupTokenRefreshListener() {
    if (_tokenRefreshListenerSet) {
      return;
    }

    _firebaseMessaging.onTokenRefresh.listen(
      (fcmToken) {
        if (fcmToken.isNotEmpty) {
          AppServices.updateFCMToken(fcmToken)
              .then((_) {
              })
              .catchError((error) {
              });
        }
      },
      onError: (error) {
      },
    );

    _tokenRefreshListenerSet = true;
  }

  /// Manually refresh FCM token (use sparingly)
  static Future<void> refreshFCMToken() async {
    if (_isRequestingPermission) {
      return;
    }

    try {
      await _firebaseMessaging.deleteToken();
      await Future.delayed(const Duration(milliseconds: 500));
      await _getFCMTokenAndUpdate();
    } catch (_) {
    }
  }

  /// Get current FCM token
  static Future<String?> getCurrentFCMToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      return null;
    }
  }

  /// Delete FCM token
  static Future<void> deleteFCMToken() async {
    try {
      await _firebaseMessaging.deleteToken();
    } catch (_) {
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
          'Aboglumbo Technician Notifications',
          channelDescription:
              'Notifications related to Aboglumbo Technician tasks and updates',
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
        if (initialMessage.notification != null) {
          _handleGenericNotificationTap(initialMessage);
        }
      }

      // Note: onMessageOpenedApp listener is already set up in setupFCMListeners()
      // No need to add it here again to avoid duplicate navigation
    } catch (_) {
    }
  }

  /// Brings the app to Home and hands back the navigator, or null when there
  /// is no navigator to act on.
  ///
  /// When a plain Home is already on the stack this pops down to it rather than
  /// rebuilding one, so its startup work - the location fix, the user-data
  /// refresh, the FCM setup - is not re-run just to open a screen on top of it.
  /// A tap that needs a particular tab or filter still builds a fresh Home,
  /// because that configuration is constructor-level; those paths behave
  /// exactly as they did before.
  static NavigatorState? _resetToHome({int? index, String? filter}) {
    final navigator = navigatorKey?.currentState;
    if (navigator == null) {
      return null;
    }

    final homeRoute = Home.activeRoute;
    if (homeRoute != null && index == null && filter == null) {
      navigator.popUntil((route) => identical(route, homeRoute));
      return navigator;
    }

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => Home(newIndex: index, selectedFilter: filter),
      ),
      (route) => false,
    );
    return navigator;
  }

  /// Opens [chatId] with Home beneath it, so back from the chat lands home.
  static void _openChatFromNotification({
    required String chatId,
    required String participantName,
    required String participantId,
    required String participantPhoto,
    required bool isAdmin,
    required String technicianName,
    required String technicianPhoto,
  }) {
    final navigator = _resetToHome();
    if (navigator == null) return;

    navigator
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
        })
        .catchError((error) {
        });
  }

  /// Handle notification tap and navigate accordingly
  static void _handleNotificationTap(String? payload) {
    if (payload == null || payload.isEmpty) {
      return;
    }

    try {
      final data = json.decode(payload) as Map<String, dynamic>;

      // Shares the id space with the remote-tap path above, so a local
      // notification and a replayed RemoteMessage for the same push cannot
      // both navigate.
      if (!_claimTapId(data['messageId']?.toString())) return;

      final type = data['type'] as String?;
      final chatId = data['chatId'] as String?;

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


        if (chatId != null && chatId.isNotEmpty) {
          _openChatFromNotification(
            chatId: chatId,
            participantName: participantName,
            participantId: participantId,
            participantPhoto: participantPhoto,
            isAdmin: isAdmin,
            technicianName: technicianName,
            technicianPhoto: technicianPhoto,
          );
        }
      }
      // Check if this is a job offer notification
      else if (type == 'job_offer' || data['category'] == 'job_offer') {
        _resetToHome(
          index: 1, // Orders tab
          filter: 'P', // Pending filter (which shows job offers)
        );
      }
      // Check if this is a booking notification
      else if (type == 'booking' || data['category'] == 'booking') {
        final isAdmin = data['isAdmin'] == 'true';
        _resetToHome(
          index: 1, // Orders tab
          // Pending for admin, Accepted for technician
          filter: isAdmin ? 'P' : 'A',
        );
      }
    } catch (_) {
    }
  }

  /// Handle chat notification tap (extracted for reuse)
  static void _handleChatNotificationTap(RemoteMessage message) {
    try {
      final data = message.data;

      final chatId = data['chatId'] as String?;
      final participantName = data['participantName'] as String? ?? 'Customer';
      final participantId = data['participantId'] as String? ?? '';
      final participantPhoto = data['participantPhoto'] as String? ?? '';
      final isAdmin = data['isAdmin'] == 'true';
      final technicianName = data['technicianName'] as String? ?? '';
      final technicianPhoto = data['technicianPhoto'] as String? ?? '';


      if (chatId != null && chatId.isNotEmpty) {
        _openChatFromNotification(
          chatId: chatId,
          participantName: participantName,
          participantId: participantId,
          participantPhoto: participantPhoto,
          isAdmin: isAdmin,
          technicianName: technicianName,
          technicianPhoto: technicianPhoto,
        );
      }
    } catch (_) {
    }
  }

  /// Handle generic notification tap from background (extracted for reuse)
  static void _handleGenericNotificationTap(RemoteMessage message) {
    try {
      if (!_claimTapId(
        message.messageId ?? message.data['messageId']?.toString(),
      )) {
        return;
      }

      final data = message.data;
      final type = data['type'] as String?;
      final category = data['category'] as String?;

      if (type == 'chat' || data['chatId'] != null) {
        _handleChatNotificationTap(message);
      } else if (type == 'job_offer' || category == 'job_offer') {
        _resetToHome(index: 1, filter: 'P'); // Orders tab, Pending filter
      } else if (type == 'booking' || category == 'booking') {
        final isAdmin = data['isAdmin'] == 'true';
        _resetToHome(
          index: 1, // Orders tab
          // Pending for admin, Accepted for technician
          filter: isAdmin ? 'P' : 'A',
        );
      }
    } catch (_) {
    }
  }

  /// Initialize FCM (legacy method - keeping for compatibility)
  static Future<void> initializeFCM() async {
    try {
      await setupFCMListeners();
    } catch (_) {
    }
  }
}
