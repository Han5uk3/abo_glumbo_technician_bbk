import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/services/chat_services.dart';
import 'package:aboglumbo_bbk_panel/services/notification_services.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' show DateFormat;

class TechnicianChatScreen extends StatefulWidget {
  final String chatId;
  final String participantName;
  final String participantId;
  final String participantPhoto;
  final bool isAdmin;
  final String technicianName;
  final String technicianPhoto;

  const TechnicianChatScreen({
    super.key,
    required this.chatId,
    required this.participantName,
    required this.participantId,
    required this.participantPhoto,
    required this.isAdmin,
    required this.technicianName,
    required this.technicianPhoto,
  });

  @override
  State<TechnicianChatScreen> createState() => _TechnicianChatScreenState();
}

class _TechnicianChatScreenState extends State<TechnicianChatScreen> {
  final TechnicianChatService _chatService = TechnicianChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  int _lastMessageCount = 0;
  bool _shouldScrollToBottom = true;

  // Optimistic message handling
  final List<Map<String, dynamic>> _pendingMessages = [];
  final Set<String> _failedMessageIds = {};

  double _previousKeyboardHeight = 0;

  @override
  void initState() {
    super.initState();
    _chatService.markAsRead(widget.chatId);
    _chatService.setActiveChat(widget.chatId);

    // Set active chat for notification suppression
    NotificationServices.setActiveChatId(widget.chatId);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    // Listen to scroll position to determine if user is viewing older messages
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Listen for keyboard changes
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    if (keyboardHeight != _previousKeyboardHeight) {
      _previousKeyboardHeight = keyboardHeight;

      // If keyboard is opening (height > 0), scroll to bottom
      if (keyboardHeight > 0) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _scrollToBottom(force: true);
          }
        });
      }
    }
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      // If user is within 100 pixels of bottom, auto-scroll on new messages
      final shouldScroll = (maxScroll - currentScroll) < 100;

      // Only update state if the value actually changed
      if (_shouldScrollToBottom != shouldScroll) {
        _shouldScrollToBottom = shouldScroll;
      }
    }
  }

  void _scrollToBottom({bool force = false}) {
    if (!_scrollController.hasClients) return;
    if (!force && !_shouldScrollToBottom) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();

    if (messageText.isEmpty || _isLoading) return;

    // Clear input immediately for better UX
    _messageController.clear();

    // Create optimistic message
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMessage = {
      'id': tempId,
      'text': messageText,
      'senderId': _chatService.currentUserId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'status': 'sending',
      'isOptimistic': true,
    };

    setState(() {
      _isLoading = true;
      _pendingMessages.add(optimisticMessage);
    });

    // Scroll to show the new message with delay for keyboard animation
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _scrollToBottom(force: true);
      }
    });

    try {
      final senderType = widget.isAdmin ? "admin" : "technician";

      await _chatService.sendMessage(
        widget.chatId,
        messageText,
        senderType,
        widget.participantId,
        widget.technicianName,
        widget.technicianPhoto,
      );

      // Remove optimistic message after successful send
      if (mounted) {
        setState(() {
          _pendingMessages.removeWhere((msg) => msg['id'] == tempId);
        });
      }

      // Scroll to bottom after message is sent with delay for rendering
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _scrollToBottom(force: true);
        }
      });
    } catch (e) {
      // Mark message as failed
      if (mounted) {
        setState(() {
          _failedMessageIds.add(tempId);
          final msgIndex = _pendingMessages.indexWhere(
            (msg) => msg['id'] == tempId,
          );
          if (msgIndex != -1) {
            _pendingMessages[msgIndex]['status'] = 'failed';
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.failedToSendMessage(e.toString()) ?? 'Failed to send message: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _retryMessage(tempId, messageText),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _retryMessage(String tempId, String messageText) async {
    setState(() {
      _failedMessageIds.remove(tempId);
      final msgIndex = _pendingMessages.indexWhere(
        (msg) => msg['id'] == tempId,
      );
      if (msgIndex != -1) {
        _pendingMessages[msgIndex]['status'] = 'sending';
      }
    });

    try {
      final senderType = widget.isAdmin ? "admin" : "technician";

      await _chatService.sendMessage(
        widget.chatId,
        messageText,
        senderType,
        widget.participantId,
        widget.technicianName,
        widget.technicianPhoto,
      );

      if (mounted) {
        setState(() {
          _pendingMessages.removeWhere((msg) => msg['id'] == tempId);
        });
      }

      _scrollToBottom(force: true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _failedMessageIds.add(tempId);
          final msgIndex = _pendingMessages.indexWhere(
            (msg) => msg['id'] == tempId,
          );
          if (msgIndex != -1) {
            _pendingMessages[msgIndex]['status'] = 'failed';
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.failedToRetryMessage(e.toString()) ?? 'Failed to retry message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              backgroundImage: widget.participantPhoto.isNotEmpty
                  ? NetworkImage(widget.participantPhoto)
                  : null,
              child: widget.participantPhoto.isEmpty
                  ? Text(
                      widget.participantName.isNotEmpty
                          ? widget.participantName[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.participantName,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    localization.customer,
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                stream: _chatService.getMessagesStream(widget.chatId),
                builder: (context, snapshot) {
                  // Only show loading on initial load, not on reconnections
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return Center(child: SizedBox(height: 26, child: Loader()));
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            localization.errorLoadingMessages,
                            style: GoogleFonts.dmSans(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Parse real messages from Firebase
                  List<Map<String, dynamic>> realMessages = [];
                  if (snapshot.hasData &&
                      snapshot.data!.snapshot.value != null) {
                    final messagesMap = snapshot.data!.snapshot.value as Map;
                    realMessages = messagesMap.entries.map((entry) {
                      final message = Map<String, dynamic>.from(
                        entry.value as Map,
                      );
                      message['id'] = entry.key;
                      message['isOptimistic'] = false;
                      return message;
                    }).toList();
                  }

                  // Filter out optimistic messages that match real messages
                  // to prevent duplicates
                  final List<String> messagesToRemove = [];
                  final filteredPendingMessages = _pendingMessages.where((
                    pending,
                  ) {
                    final pendingText = pending['text'] as String;
                    final pendingTimestamp = pending['timestamp'] as int;
                    final pendingId = pending['id'] as String;

                    // Check if a real message with similar content exists
                    // (within 5 seconds of the optimistic message)
                    final hasDuplicate = realMessages.any((real) {
                      final realText = real['text'] as String? ?? '';
                      final realTimestamp = real['timestamp'] as int? ?? 0;
                      final timeDiff = (realTimestamp - pendingTimestamp).abs();

                      return realText == pendingText && timeDiff < 5000;
                    });

                    // Mark for removal if duplicate found
                    if (hasDuplicate && pending['status'] != 'failed') {
                      messagesToRemove.add(pendingId);
                    }

                    return !hasDuplicate;
                  }).toList();

                  // Clean up successfully sent messages from pending list
                  if (messagesToRemove.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _pendingMessages.removeWhere(
                            (msg) => messagesToRemove.contains(msg['id']),
                          );
                        });
                      }
                    });
                  }

                  // Combine real messages with filtered pending optimistic messages
                  final allMessages = [
                    ...realMessages,
                    ...filteredPendingMessages,
                  ];
                  allMessages.sort(
                    (a, b) =>
                        (a['timestamp'] ?? 0).compareTo(b['timestamp'] ?? 0),
                  );

                  // Auto-scroll only when message count increases
                  final currentMessageCount = allMessages.length;
                  if (currentMessageCount > _lastMessageCount &&
                      _shouldScrollToBottom) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToBottom();
                    });
                  }
                  // Update count directly without setState to avoid rebuild loop
                  _lastMessageCount = currentMessageCount;

                  if (allMessages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            localization.noMessages,
                            style: GoogleFonts.dmSans(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            localization.startConversationWithCustomer,
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                      bottom: 16,
                    ),
                    itemCount: allMessages.length,
                    itemBuilder: (context, index) {
                      final message = allMessages[index];

                      final senderId = message['senderId'] as String? ?? '';

                      String text = message['text'] as String? ?? '';
                      if (text.isEmpty) {
                        text = message['message'] as String? ?? '';
                      }
                      if (text.isEmpty) {
                        final mediaUrl = message['mediaUrl'] as String?;
                        if (mediaUrl != null && mediaUrl.isNotEmpty) {
                          final mediaType =
                              message['mediaType'] as String? ?? '';
                          text = mediaType == 'image'
                              ? '📷 Photo'
                              : (mediaType == 'video' ? '🎥 Video' : '[Media]');
                        } else {
                          text = '[Empty message]';
                        }
                      }

                      final timestamp = message['timestamp'] as int? ?? 0;
                      final isMe = senderId == _chatService.currentUserId;
                      final status = message['status'] as String? ?? 'sent';
                      final isOptimistic =
                          message['isOptimistic'] as bool? ?? false;

                      bool showDateSeparator = false;
                      if (index == 0) {
                        showDateSeparator = true;
                      } else {
                        final prevMessage = allMessages[index - 1];
                        final prevTimestamp =
                            prevMessage['timestamp'] as int? ?? 0;
                        if (!_isSameDay(timestamp, prevTimestamp)) {
                          showDateSeparator = true;
                        }
                      }

                      return Column(
                        children: [
                          if (showDateSeparator)
                            _buildDateSeparator(timestamp, localization),
                          _buildMessageBubble(
                            message: text,
                            isMe: isMe,
                            timestamp: timestamp,
                            status: status,
                            isOptimistic: isOptimistic,
                            messageId: message['id'] as String,
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            _buildMessageInput(localization),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSeparator(int timestamp, AppLocalizations localization) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    String dateText;
    if (messageDate == today) {
      dateText = localization.today;
    } else if (messageDate == yesterday) {
      dateText = localization.yesterday;
    } else {
      dateText = DateFormat('MMM dd, yyyy').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              dateText,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[300])),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required String message,
    required bool isMe,
    required int timestamp,
    required String status,
    required bool isOptimistic,
    required String messageId,
  }) {
    Widget statusIcon = const SizedBox.shrink();

    if (isMe) {
      if (status == 'sending') {
        statusIcon = const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
          ),
        );
      } else if (status == 'failed') {
        statusIcon = const Icon(
          Icons.error_outline,
          size: 14,
          color: Colors.red,
        );
      } else {
        statusIcon = Icon(
          Icons.check,
          size: 14,
          color: isMe ? Colors.white70 : Colors.grey[600],
        );
      }
    }

    return GestureDetector(
      onTap: status == 'failed'
          ? () {
              // Extract message text and retry
              _retryMessage(messageId, message);
            }
          : null,
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: status == 'failed'
                ? Colors.red[50]
                : (isMe ? AppColors.blue1 : Colors.white),
            border: status == 'failed'
                ? Border.all(color: Colors.red[300]!, width: 1)
                : null,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  color: status == 'failed'
                      ? Colors.red[900]
                      : (isMe ? Colors.white : Colors.black87),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      _formatTime(timestamp),
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: status == 'failed'
                            ? Colors.red[700]
                            : (isMe
                                  ? Colors.white.withOpacity(0.8)
                                  : Colors.grey[600]),
                      ),
                    ),
                  ),
                  if (isMe) ...[const SizedBox(width: 4), statusIcon],
                  if (status == 'failed') ...[
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.tapToRetry,
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: Colors.red[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput(AppLocalizations localization) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                textInputAction: TextInputAction.send,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                onSubmitted: (_) => _sendMessage(),
                style: GoogleFonts.dmSans(fontSize: 15),
                decoration: InputDecoration(
                  hintText: localization.typeMessageToCustomer,
                  hintStyle: GoogleFonts.dmSans(
                    fontSize: 15,
                    color: Colors.grey[500],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: _isLoading ? Colors.grey[400] : AppColors.blue1,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: _isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: Loader(size: 16, color: Colors.white),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
              onPressed: _isLoading ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(int timestamp1, int timestamp2) {
    final date1 = DateTime.fromMillisecondsSinceEpoch(timestamp1);
    final date2 = DateTime.fromMillisecondsSinceEpoch(timestamp2);
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatTime(int timestamp) {
    if (timestamp == 0) return '';
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    if (dateTime.day == now.day &&
        dateTime.month == now.month &&
        dateTime.year == now.year) {
      return DateFormat.jm().format(dateTime);
    }
    return DateFormat('MMM d, h:mm a').format(dateTime);
  }

  @override
  void dispose() {
    _chatService.clearActiveChat(widget.chatId);
    // Clear active chat for notification suppression
    NotificationServices.setActiveChatId(null);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
