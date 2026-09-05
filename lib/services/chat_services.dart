import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';

class TechnicianChatService {
  late final DatabaseReference _rtdb;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  TechnicianChatService() {
    _rtdb = FirebaseDatabase.instance.ref();
  }

  String get currentUserId =>
      _auth.currentUser?.uid ?? LocalStore.getUID() ?? '';

  String generateChatId(String bookingId, String userId1, String userId2) {
    List<String> ids = [userId1, userId2]..sort();
    return '${bookingId}_${ids[0]}_${ids[1]}';
  }

  Future<String> initiateChat({
    required String bookingId,
    required String customerId,
    required String customerName,
    required String customerPhoto,
    required String technicianName,
    required String technicianPhoto,
  }) async {
    debugPrint('[log] 🔄 Initiating new chat...');
    debugPrint('[log] 📋 Booking ID: $bookingId');
    debugPrint('[log] 👤 Technician ID: $currentUserId');
    debugPrint('[log] 👤 Customer ID: $customerId');

    final chatId = generateChatId(bookingId, currentUserId, customerId);
    debugPrint('[log] 💬 Generated Chat ID: $chatId');

    try {
      final chatRef = _rtdb.child('chats/$chatId');
      debugPrint('[log] 🔍 Checking if chat exists...');

      DataSnapshot? snapshot;
      bool hasCorruptedData = false;

      try {
        snapshot = await chatRef.get();
        debugPrint('[log] ✅ Chat exists check complete: ${snapshot.exists}');

        // Validate the data structure if chat exists
        if (snapshot.exists) {
          debugPrint(
            '[log] 🔍 Snapshot value type: ${snapshot.value.runtimeType}',
          );

          // Check if the value is a String (corrupted data)
          if (snapshot.value is String) {
            debugPrint(
              '[log] ⚠️ CORRUPTED DATA DETECTED: Chat node contains String instead of Map',
            );
            debugPrint('[log] 📝 Corrupted value: ${snapshot.value}');
            hasCorruptedData = true;
          } else if (snapshot.value is! Map) {
            debugPrint(
              '[log] ⚠️ CORRUPTED DATA DETECTED: Chat node contains ${snapshot.value.runtimeType} instead of Map',
            );
            hasCorruptedData = true;
          }
        }
      } catch (e) {
        // This error occurs when Firebase tries to parse corrupted data
        if (e.toString().contains('String') && e.toString().contains('Map')) {
          debugPrint('[log] ⚠️ CORRUPTED DATA DETECTED from exception: $e');
          hasCorruptedData = true;
          // Set snapshot to null so we treat it as non-existent
          snapshot = null;
        } else {
          debugPrint('[log] ❌ Error getting chat snapshot: $e');
          rethrow;
        }
      }

      // If data is corrupted, delete it and recreate
      if (hasCorruptedData) {
        debugPrint('[log] 🗑️ Attempting to clean corrupted chat data...');
        try {
          // Try to delete the corrupted chat node
          await chatRef.remove();
          debugPrint('[log] ✅ Corrupted chat node deleted');

          // Delete any corrupted userChats entries
          await _rtdb.child('userChats/$currentUserId/$chatId').remove();
          await _rtdb.child('userChats/$customerId/$chatId').remove();
          debugPrint('[log] ✅ Corrupted userChats entries deleted');
        } catch (deleteError) {
          debugPrint(
            '[log] ⚠️ Delete failed (likely permission denied): $deleteError',
          );
          debugPrint('[log] 💡 Will overwrite corrupted data instead');
          // Don't throw - we'll just overwrite the data below
        }

        // Clear or update the chatroomId in booking
        try {
          await _firestore.collection('bookings').doc(bookingId).update({
            'chatroomId': chatId, // Keep the same chatId
          });
          debugPrint('[log] ✅ Updated chatroomId in booking');
        } catch (firestoreError) {
          debugPrint('[log] ⚠️ Could not update booking: $firestoreError');
        }

        // Force snapshot to null to trigger recreation/overwrite
        snapshot = null;
      }

      if (snapshot == null || !snapshot.exists || hasCorruptedData) {
        debugPrint('[log] 🆕 Creating new chat...');

        final chatData = {
          'bookingId': bookingId,
          'participants': {'technician': currentUserId, 'customer': customerId},
          'createdAt': ServerValue.timestamp,
          'lastMessage': '',
          'lastMessageTime': ServerValue.timestamp,
          'lastMessageBy': '',
          'customerUnreadCount': 0,
          'technicianUnreadCount': 0,
        };

        debugPrint('[log] 📝 Chat data prepared: $chatData');
        debugPrint('[log] 💾 Setting main chat document...');
        await chatRef.set(chatData);
        debugPrint('[log] ✅ Main chat document created');

        debugPrint('[log] 👤 Creating userChats for technician...');
        await _rtdb.child('userChats/$currentUserId/$chatId').set({
          'participantId': customerId,
          'participantName': customerName,
          'participantPhoto': customerPhoto,
          'participantType': 'customer',
          'bookingId': bookingId,
          'lastMessage': '',
          'lastMessageTime': ServerValue.timestamp,
          'unreadCount': 0,
        });
        debugPrint('[log] ✅ Technician chat entry created');

        debugPrint('[log] 👥 Creating userChats for customer...');
        await _rtdb.child('userChats/$customerId/$chatId').set({
          'participantId': currentUserId,
          'participantName': technicianName,
          'participantPhoto': technicianPhoto,
          'participantType': 'technician',
          'bookingId': bookingId,
          'lastMessage': '',
          'lastMessageTime': ServerValue.timestamp,
          'unreadCount': 0,
        });
        debugPrint('[log] ✅ Customer chat entry created');

        debugPrint('[log] 📚 Updating booking with chatroom ID...');
        await _firestore.collection('bookings').doc(bookingId).update({
          'chatroomId': chatId,
        });
        debugPrint('[log] ✅ Booking updated with chatroom ID');
      } else {
        debugPrint(
          '[log] ♻️ Chat already exists with valid data, ensuring userChats entries...',
        );

        debugPrint('[log] 🔍 Checking technician chat entry...');
        try {
          final techUserChatSnapshot = await _rtdb
              .child('userChats/$currentUserId/$chatId')
              .get();
          debugPrint(
            '[log] ✅ Technician chat entry exists: ${techUserChatSnapshot.exists}',
          );

          if (!techUserChatSnapshot.exists) {
            debugPrint('[log] 🆕 Creating missing technician chat entry...');
            await _rtdb.child('userChats/$currentUserId/$chatId').set({
              'participantId': customerId,
              'participantName': customerName,
              'participantPhoto': customerPhoto,
              'participantType': 'customer',
              'bookingId': bookingId,
              'lastMessage': '',
              'lastMessageTime': ServerValue.timestamp,
              'unreadCount': 0,
            });
            debugPrint('[log] ✅ Technician chat entry created');
          }
        } catch (e) {
          if (e.toString().contains('String') && e.toString().contains('Map')) {
            debugPrint(
              '[log] ⚠️ Corrupted technician userChat detected, recreating...',
            );
            await _rtdb.child('userChats/$currentUserId/$chatId').set({
              'participantId': customerId,
              'participantName': customerName,
              'participantPhoto': customerPhoto,
              'participantType': 'customer',
              'bookingId': bookingId,
              'lastMessage': '',
              'lastMessageTime': ServerValue.timestamp,
              'unreadCount': 0,
            });
            debugPrint('[log] ✅ Technician chat entry recreated');
          } else {
            rethrow;
          }
        }

        debugPrint('[log] 🔍 Checking customer chat entry...');
        try {
          final custUserChatSnapshot = await _rtdb
              .child('userChats/$customerId/$chatId')
              .get();
          debugPrint(
            '[log] ✅ Customer chat entry exists: ${custUserChatSnapshot.exists}',
          );

          if (!custUserChatSnapshot.exists) {
            debugPrint('[log] 🆕 Creating missing customer chat entry...');
            await _rtdb.child('userChats/$customerId/$chatId').set({
              'participantId': currentUserId,
              'participantName': technicianName,
              'participantPhoto': technicianPhoto,
              'participantType': 'technician',
              'bookingId': bookingId,
              'lastMessage': '',
              'lastMessageTime': ServerValue.timestamp,
              'unreadCount': 0,
            });
            debugPrint('[log] ✅ Customer chat entry created');
          }
        } catch (e) {
          if (e.toString().contains('String') && e.toString().contains('Map')) {
            debugPrint(
              '[log] ⚠️ Corrupted customer userChat detected, recreating...',
            );
            await _rtdb.child('userChats/$customerId/$chatId').set({
              'participantId': currentUserId,
              'participantName': technicianName,
              'participantPhoto': technicianPhoto,
              'participantType': 'technician',
              'bookingId': bookingId,
              'lastMessage': '',
              'lastMessageTime': ServerValue.timestamp,
              'unreadCount': 0,
            });
            debugPrint('[log] ✅ Customer chat entry recreated');
          } else {
            rethrow;
          }
        }

        debugPrint('[log] 📚 Checking booking document...');
        final bookingDoc = await _firestore
            .collection('bookings')
            .doc(bookingId)
            .get();
        if (bookingDoc.exists) {
          final existingChatRoomId = bookingDoc.data()?['chatroomId'];
          debugPrint(
            '[log] 📝 Existing chatroom ID in booking: $existingChatRoomId',
          );
          if (existingChatRoomId == null || existingChatRoomId != chatId) {
            debugPrint('[log] 🔄 Updating booking with correct chatroom ID...');
            await _firestore.collection('bookings').doc(bookingId).update({
              'chatroomId': chatId,
            });
            debugPrint('[log] ✅ Booking updated');
          }
        }
      }

      debugPrint('[log] ✅ Chat initialization complete!');
      return chatId;
    } catch (e, stackTrace) {
      debugPrint('[log] ❌ Chat error: Exception: $e');
      debugPrint('[log] 📚 Stack trace: $stackTrace');
      throw Exception('Failed to initiate chat: $e');
    }
  }

  Future<void> sendMessage(
    String chatId,
    String message,
    String senderType,
    String receiverId,
    String senderName,
    String senderPhoto,
  ) async {
    final messageRef = _rtdb.child('messages/$chatId').push();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    try {
      final messageData = {
        'senderId': currentUserId,
        'senderType': senderType,
        'text': message,
        'timestamp': timestamp,
        'status': 'sent',
      };
      await messageRef.set(messageData);

      await _rtdb.child('chats/$chatId').update({
        'lastMessage': message,
        'lastMessageTime': timestamp,
        'lastMessageBy': currentUserId,
      });

      String unreadField = (senderType == 'technician' || senderType == 'admin')
          ? 'customerUnreadCount'
          : 'technicianUnreadCount';
      await _rtdb
          .child('chats/$chatId/$unreadField')
          .set(ServerValue.increment(1));

      await _rtdb.child('userChats/$currentUserId/$chatId').update({
        'lastMessage': message,
        'lastMessageTime': timestamp,
      });
    } catch (e) {
      debugPrint('⚠️ Error sending message or updating sender metadata: $e');
      // We don't throw here if the message was already sent (metadata is best-effort)
    }

    final receiverChatRef = _rtdb.child('userChats/$receiverId/$chatId');

    // Update receiver's entry directly without reading first to avoid permission errors
    try {
      await receiverChatRef.update({
        'participantId': currentUserId,
        'participantName': senderName,
        'participantPhoto': senderPhoto,
        'participantType': senderType,
        'lastMessage': message,
        'lastMessageTime': timestamp,
        'unreadCount': ServerValue.increment(1),
      });
    } catch (e) {
      if (e.toString().contains('permission-denied') ||
          e.toString().contains('String') ||
          e.toString().contains('Map')) {
        // If update fails due to permissions or missing node, try set/recreate
        try {
          // Get bookingId from the chat to ensure entry is complete
          String bookingId = '';
          final chatSnapshot = await _rtdb.child('chats/$chatId').get();
          if (chatSnapshot.exists && chatSnapshot.value is Map) {
            final chatData = Map<String, dynamic>.from(
              chatSnapshot.value as Map,
            );
            bookingId = chatData['bookingId'] ?? '';
          }

          await receiverChatRef.set({
            'participantId': currentUserId,
            'participantName': senderName,
            'participantPhoto': senderPhoto,
            'participantType': senderType,
            'bookingId': bookingId,
            'lastMessage': message,
            'lastMessageTime': timestamp,
            'unreadCount': 1,
          });
        } catch (e2) {
          debugPrint('⚠️ Failed to create receiver chat entry: $e2');
        }
      } else {
        debugPrint('⚠️ Unexpected error updating receiver chat entry: $e');
      }
    }
  }

  Stream<DatabaseEvent> getMessagesStream(String chatId) {
    return _rtdb.child('messages/$chatId').orderByChild('timestamp').onValue;
  }

  Future<void> markAsRead(String chatId) async {
    try {
      await _rtdb.child('chats/$chatId/technicianUnreadCount').set(0);
      await _rtdb.child('userChats/$currentUserId/$chatId/unreadCount').set(0);
    } catch (e) {
      debugPrint('❌ Error marking as read: $e');
    }
  }

  Stream<DatabaseEvent> getChatListStream() {
    return _rtdb
        .child('userChats/$currentUserId')
        .orderByChild('lastMessageTime')
        .onValue;
  }

  /// The roles a chat participant can hold.
  ///
  /// `participants` is keyed by ROLE, not by uid, and that is load-bearing.
  /// Both apps authenticate against the same Firebase project with phone auth,
  /// so a Firebase uid identifies a person, not a person-in-a-role: someone who
  /// is both a customer and a technician has exactly ONE uid. Keying the map by
  /// uid silently collapsed those two entries into one, leaving a chat that
  /// named nobody to notify. A chat has exactly one participant per role, so
  /// role is a key that cannot collide.
  static const List<String> chatRoles = ['customer', 'technician', 'admin'];

  /// The uids in a `participants` map, accepting either shape: the current
  /// role -> uid map, or the legacy uid -> role map still on older chats.
  static Set<String> participantUids(Object? participants) {
    if (participants is! Map) return {};
    final uids = <String>{};
    participants.forEach((key, value) {
      final k = key.toString();
      final v = value?.toString() ?? '';
      if (chatRoles.contains(k)) {
        if (v.isNotEmpty) uids.add(v);
      } else if (k.isNotEmpty) {
        uids.add(k);
      }
    });
    return uids;
  }

  /// Whether [chatId] can be reused as-is.
  ///
  /// Deliberately not a plain existence check. `markAsRead` writes
  /// `chats/<id>/<unreadCount>`, which in RTDB *creates* the node when it is
  /// missing - so a chat that was cleaned up and then merely opened comes back
  /// as a stub holding a counter and nothing else. It exists, but it names
  /// nobody, and notifyOnNewChatMessage cannot work out who to notify from it.
  Future<bool> isChatUsable(String chatId) async {
    try {
      final snapshot = await _rtdb.child('chats/$chatId/participants').get();
      if (!snapshot.exists) return false;
      final value = snapshot.value;
      if (value is! Map) return false;

      final namedRoles = value.entries
          .where((e) => chatRoles.contains(e.key.toString()))
          .where((e) => (e.value?.toString() ?? '').isNotEmpty)
          .length;
      if (namedRoles >= 2) return true;

      // Legacy uid -> role chats stay usable while they still name two people.
      // One that named the same person twice already collapsed to a single
      // entry, and recreating it in the role-keyed shape is the repair.
      return namedRoles == 0 && value.length >= 2;
    } catch (e) {
      debugPrint('⚠️ Could not verify chat $chatId: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getChatDetails(String chatId) async {
    final snapshot = await _rtdb.child('chats/$chatId').get();
    if (snapshot.exists) {
      return Map<String, dynamic>.from(snapshot.value as Map);
    }
    return null;
  }

  Future<String?> getChatIdByBookingId(String bookingId) async {
    try {
      final bookingDoc = await _firestore
          .collection('bookings')
          .doc(bookingId)
          .get();
      if (bookingDoc.exists) {
        return bookingDoc.data()?['chatroomId'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting chat by booking ID: $e');
      return null;
    }
  }

  Future<void> deleteMessage(String chatId, String messageId) async {
    await _rtdb.child('messages/$chatId/$messageId').remove();
  }

  Future<void> updateMessageStatus(
    String chatId,
    String messageId,
    String status,
  ) async {
    await _rtdb.child('messages/$chatId/$messageId').update({'status': status});
  }

  Future<int> getUnreadCount() async {
    final snapshot = await _rtdb.child('userChats/$currentUserId').get();
    if (!snapshot.exists) return 0;

    int totalUnread = 0;
    final chatsMap = Map<String, dynamic>.from(snapshot.value as Map);

    chatsMap.forEach((key, value) {
      final chat = Map<String, dynamic>.from(value);
      totalUnread += (chat['unreadCount'] as int? ?? 0);
    });

    return totalUnread;
  }

  Future<List<Map<String, dynamic>>> getAllChats() async {
    final snapshot = await _rtdb.child('userChats/$currentUserId').get();
    if (!snapshot.exists) return [];

    final chatsMap = Map<String, dynamic>.from(snapshot.value as Map);
    List<Map<String, dynamic>> chatsList = [];

    chatsMap.forEach((chatId, chatData) {
      final chat = Map<String, dynamic>.from(chatData);
      chat['chatId'] = chatId;
      chatsList.add(chat);
    });

    chatsList.sort((a, b) {
      final aTime = a['lastMessageTime'] ?? 0;
      final bTime = b['lastMessageTime'] ?? 0;
      return bTime.compareTo(aTime);
    });

    return chatsList;
  }

  Future<void> sendMediaMessage(
    String chatId,
    String mediaUrl,
    String mediaType,
    String receiverId,
    String senderName,
    String senderPhoto, {
    String? caption,
  }) async {
    final messageRef = _rtdb.child('messages/$chatId').push();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    await messageRef.set({
      'senderId': currentUserId,
      'senderType': 'technician',
      'text': caption ?? '',
      'timestamp': timestamp,
      'status': 'sent',
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
    });

    final lastMessage = mediaType == 'image'
        ? '📷 Photo'
        : (mediaType == 'video' ? '🎥 Video' : caption ?? '');

    await _rtdb.child('chats/$chatId').update({
      'lastMessage': lastMessage,
      'lastMessageTime': timestamp,
      'lastMessageBy': currentUserId,
    });

    await _rtdb
        .child('chats/$chatId/customerUnreadCount')
        .set(ServerValue.increment(1));

    await _rtdb.child('userChats/$currentUserId/$chatId').update({
      'lastMessage': lastMessage,
      'lastMessageTime': timestamp,
    });

    final receiverChatRef = _rtdb.child('userChats/$receiverId/$chatId');
    final receiverSnapshot = await receiverChatRef.get();

    if (receiverSnapshot.exists) {
      await receiverChatRef.update({
        'lastMessage': lastMessage,
        'lastMessageTime': timestamp,
        'unreadCount': ServerValue.increment(1),
      });
    } else {
      final chatSnapshot = await _rtdb.child('chats/$chatId').get();
      String bookingId = '';
      if (chatSnapshot.exists) {
        final chatData = Map<String, dynamic>.from(chatSnapshot.value as Map);
        bookingId = chatData['bookingId'] ?? '';
      }

      await receiverChatRef.set({
        'participantId': currentUserId,
        'participantName': senderName,
        'participantPhoto': senderPhoto,
        'participantType': 'technician',
        'bookingId': bookingId,
        'lastMessage': lastMessage,
        'lastMessageTime': timestamp,
        'unreadCount': 1,
      });
    }
  }

  Future<void> deleteChat(String chatId) async {
    try {
      final chatSnapshot = await _rtdb.child('chats/$chatId').get();
      if (chatSnapshot.exists) {
        final chatData = Map<String, dynamic>.from(chatSnapshot.value as Map);
        final participants = Map<String, dynamic>.from(
          chatData['participants'] ?? {},
        );

        await _rtdb.child('messages/$chatId').remove();

        // Delete userChats entries BEFORE deleting the main chat so participant rules still pass
        for (final userId in participantUids(participants)) {
          await _rtdb.child('userChats/$userId/$chatId').remove();
        }

        await _rtdb.child('chats/$chatId').remove();

        if (chatData['bookingId'] != null) {
          await _firestore
              .collection('bookings')
              .doc(chatData['bookingId'])
              .update({'chatroomId': FieldValue.delete()});
        }
      }
    } catch (e) {
      throw Exception('Failed to delete chat: $e');
    }
  }

  Future<void> markAllChatsAsRead() async {
    final snapshot = await _rtdb.child('userChats/$currentUserId').get();
    if (!snapshot.exists) return;

    final chatsMap = Map<String, dynamic>.from(snapshot.value as Map);

    for (String chatId in chatsMap.keys) {
      await _rtdb.child('chats/$chatId/technicianUnreadCount').set(0);
      await _rtdb.child('userChats/$currentUserId/$chatId/unreadCount').set(0);
    }
  }

  Future<List<Map<String, dynamic>>> searchMessages(
    String chatId,
    String query,
  ) async {
    final snapshot = await _rtdb.child('messages/$chatId').get();
    if (!snapshot.exists) return [];

    final messagesMap = Map<String, dynamic>.from(snapshot.value as Map);
    List<Map<String, dynamic>> matchingMessages = [];

    messagesMap.forEach((messageId, messageData) {
      final message = Map<String, dynamic>.from(messageData);
      final text = (message['text'] as String? ?? '').toLowerCase();

      if (text.contains(query.toLowerCase())) {
        message['messageId'] = messageId;
        matchingMessages.add(message);
      }
    });

    matchingMessages.sort((a, b) {
      final aTime = a['timestamp'] ?? 0;
      final bTime = b['timestamp'] ?? 0;
      return aTime.compareTo(bTime);
    });

    return matchingMessages;
  }

  Future<Map<String, dynamic>?> getParticipantInfo(String chatId) async {
    final snapshot = await _rtdb
        .child('userChats/$currentUserId/$chatId')
        .get();
    if (snapshot.exists) {
      return Map<String, dynamic>.from(snapshot.value as Map);
    }
    return null;
  }

  Future<void> setTypingStatus(String chatId, bool isTyping) async {
    await _rtdb.child('chats/$chatId/typing/$currentUserId').set(isTyping);
  }

  Stream<bool> getTypingStatus(String chatId, String otherUserId) {
    return _rtdb.child('chats/$chatId/typing/$otherUserId').onValue.map((
      event,
    ) {
      if (event.snapshot.exists) {
        return event.snapshot.value as bool? ?? false;
      }
      return false;
    });
  }
}
