import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:study_buddy_app/Models/chatModel.dart';
import 'package:study_buddy_app/Models/studygroupModel.dart';
import 'package:study_buddy_app/providerService.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class GroupChatPage extends ConsumerStatefulWidget {
  final StudyGroup group;

  const GroupChatPage({super.key, required this.group});

  @override
  ConsumerState<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends ConsumerState<GroupChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _meetingLinkController = TextEditingController();
  bool _isLinkBannerVisible = true;

  @override
  void initState() {
    super.initState();
    // Mark messages as read when entering the chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markMessagesAsRead();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _meetingLinkController.dispose();
    super.dispose();
  }

  void _markMessagesAsRead() async {
    final userId = ref.read(firebaseServiceProvider).currentUserId;
    if (userId != null) {
      await ref
          .read(chatServiceProvider)
          .markMessagesAsRead(userId: userId, groupId: widget.group.groupId);
    }
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // Store context reference before async gap
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final userId = ref.read(firebaseServiceProvider).currentUserId;
    final user = await ref.read(currentUserDataProvider.future);

    if (userId != null && user != null) {
      _messageController.clear();

      try {
        await ref
            .read(chatServiceProvider)
            .sendMessage(
              senderId: userId,
              senderName: user.name,
              senderProfileUrl: user.profileImageUrl,
              groupId: widget.group.groupId,
              content: message,
              memberIds: widget.group.memberIds,
            );

        // Scroll to the bottom after sending a message
        if (mounted && _scrollController.hasClients) {
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted && _scrollController.hasClients) {
              _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }
      } catch (e) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error sending message: $e')),
          );
        }
      }
    }
  }

  Future<void> _launchMeetingLink(String url) async {
    // Store context reference before async gap
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final Uri uri = Uri.parse(url);

    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Could not launch $url')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showMeetingLinkDialog() {
    _meetingLinkController.text = widget.group.meetingLink ?? '';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Meeting Link'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _meetingLinkController,
                  decoration: const InputDecoration(
                    labelText: 'Enter meeting link',
                    hintText: 'https://meet.google.com/...',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Provide a link to your meeting room (Google Meet, Zoom, etc.)',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              if (widget.group.meetingLink != null)
                TextButton(
                  onPressed: () async {
                    // Store a reference to ScaffoldMessenger before any async operations
                    // and before navigation
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    final currentContext = context;

                    try {
                      // First update the meeting link
                      await ref
                          .read(studyGroupServiceProvider)
                          .updateMeetingLink(widget.group.groupId, null);

                      // Pop immediately to prevent context issues
                      Navigator.pop(currentContext);

                      // Prepare data for message
                      final userId =
                          ref.read(firebaseServiceProvider).currentUserId;
                      final user = await ref.read(
                        currentUserDataProvider.future,
                      );

                      // Refresh group data
                      final updatedGroup = await ref
                          .read(studyGroupServiceProvider)
                          .getStudyGroup(widget.group.groupId);

                      if (updatedGroup != null && mounted) {
                        // Use the stored scaffoldMessenger
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(content: Text('Meeting link removed')),
                        );

                        // Send a message to the group about the link removal
                        if (userId != null && user != null) {
                          await ref
                              .read(chatServiceProvider)
                              .sendMessage(
                                senderId: userId,
                                senderName: user.name,
                                senderProfileUrl: user.profileImageUrl,
                                groupId: widget.group.groupId,
                                content:
                                    '${user.name} removed the meeting link',
                                memberIds: widget.group.memberIds,
                              );
                        }

                        // Force rebuild with updated group data
                        if (mounted) {
                          setState(() {});
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        // Use the stored scaffoldMessenger
                        scaffoldMessenger.showSnackBar(
                          SnackBar(content: Text('Error removing link: $e')),
                        );
                      }
                    }
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Remove'),
                ),
              TextButton(
                onPressed: () async {
                  final link = _meetingLinkController.text.trim();
                  if (link.isEmpty) {
                    return;
                  }

                  // Store a reference to ScaffoldMessenger and context before any async operations
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  final currentContext = context;

                  try {
                    // First update the meeting link
                    await ref
                        .read(studyGroupServiceProvider)
                        .updateMeetingLink(widget.group.groupId, link);

                    // Pop immediately to prevent context issues
                    Navigator.pop(currentContext);

                    // Prepare data for message
                    final userId =
                        ref.read(firebaseServiceProvider).currentUserId;
                    final user = await ref.read(currentUserDataProvider.future);

                    // Refresh group data
                    final updatedGroup = await ref
                        .read(studyGroupServiceProvider)
                        .getStudyGroup(widget.group.groupId);

                    if (updatedGroup != null && mounted) {
                      // Use the stored scaffoldMessenger
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(content: Text('Meeting link updated')),
                      );

                      // Send a message to the group about the new link
                      if (userId != null && user != null) {
                        await ref
                            .read(chatServiceProvider)
                            .sendMessage(
                              senderId: userId,
                              senderName: user.name,
                              senderProfileUrl: user.profileImageUrl,
                              groupId: widget.group.groupId,
                              content:
                                  '${user.name} added a meeting link: $link',
                              memberIds: widget.group.memberIds,
                            );
                      }

                      // Force rebuild with updated group data if widget is still mounted
                      if (mounted) {
                        setState(() {});
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      // Use the stored scaffoldMessenger
                      scaffoldMessenger.showSnackBar(
                        SnackBar(content: Text('Error updating link: $e')),
                      );
                    }
                  }
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  // Check if a message contains a URL
  bool _isUrl(String text) {
    // Simple regex to check for URLs
    final urlRegExp = RegExp(
      r'(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9]+\.[^\s]{2,}|www\.[a-zA-Z0-9]+\.[^\s]{2,})',
      caseSensitive: false,
      multiLine: false,
    );
    return urlRegExp.hasMatch(text);
  }

  // Check if message is about adding a meeting link
  bool _isMeetingLinkMessage(String text) {
    final pattern = RegExp(
      r'added a meeting link: (https?:\/\/\S+)',
      caseSensitive: false,
    );
    return pattern.hasMatch(text);
  }

  // Extract URL from a meeting link message
  String _extractUrl(String text) {
    final pattern = RegExp(
      r'added a meeting link: (https?:\/\/\S+)',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(text);
    if (match != null && match.groupCount >= 1) {
      return match.group(1) ?? '';
    }
    return '';
  }

  // Build widget for different types of message content
  Widget _buildMessageContent(String content) {
    if (_isMeetingLinkMessage(content)) {
      final url = _extractUrl(content);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Meeting Link Added:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () => _launchMeetingLink(url),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.video_call,
                        size: 16,
                        color: Colors.deepPurple,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Join Meeting',
                          style: TextStyle(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    url,
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else if (content.contains('removed the meeting link')) {
      return Text(
        content,
        style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
      );
    } else if (_isUrl(content)) {
      return InkWell(
        onTap: () => _launchMeetingLink(content),
        child: Text(
          content,
          style: const TextStyle(
            color: Colors.blue,
            decoration: TextDecoration.underline,
          ),
        ),
      );
    } else {
      return Text(content);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(firebaseServiceProvider).currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.group.groupName),
            Text(
              '${widget.group.memberIds.length} members',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.link),
            tooltip: 'Set Meeting Link',
            onPressed: () => _showMeetingLinkDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Group Details',
            onPressed: () {
              // Navigate to group details
              // Use a direct navigation that doesn't rely on BuildContext after async operations
              Future.microtask(() => Navigator.of(context).pop());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Meeting link banner at the top (only shown when a meeting link exists)
          if (widget.group.meetingLink != null &&
              widget.group.meetingLink!.isNotEmpty &&
              _isLinkBannerVisible)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.deepPurple.shade200,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.video_call,
                    size: 20,
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap:
                          () => _launchMeetingLink(widget.group.meetingLink!),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Active Meeting',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            widget.group.meetingLink!,
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 11,
                              decoration: TextDecoration.underline,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed:
                        () => _launchMeetingLink(widget.group.meetingLink!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                      minimumSize: const Size(0, 30),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Join',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      setState(() {
                        _isLinkBannerVisible = false;
                      });
                    },
                    tooltip: 'Hide banner',
                  ),
                ],
              ),
            ),

          // Messages list
          Expanded(
            child:
                userId == null
                    ? const Center(
                      child: Text('Please log in to view messages'),
                    )
                    : StreamBuilder<List<ChatMessage>>(
                      stream: ref
                          .watch(chatServiceProvider)
                          .getChatMessages(widget.group.groupId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        }

                        final messages = snapshot.data ?? [];

                        if (messages.isEmpty) {
                          return const Center(
                            child: Text(
                              'No messages yet. Be the first to say hello!',
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 12,
                          ),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final isCurrentUser = message.senderId == userId;

                            return _buildMessageBubble(message, isCurrentUser);
                          },
                        );
                      },
                    ),
          ),

          // Message input field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  offset: const Offset(0, -1),
                  blurRadius: 3,
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Message input field
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  // Send button
                  Material(
                    color: Colors.deepPurple,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      onTap: _sendMessage,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isCurrentUser) {
    final time = DateFormat('h:mm a').format(message.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade200,
              backgroundImage:
                  message.senderProfileUrl != null
                      ? NetworkImage(message.senderProfileUrl!)
                      : null,
              child:
                  message.senderProfileUrl == null
                      ? Text(message.senderName[0].toUpperCase())
                      : null,
            ),
            const SizedBox(width: 8),
          ],

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color:
                    isCurrentUser
                        ? Colors.deepPurple.shade100
                        : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isCurrentUser)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        message.senderName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  _buildMessageContent(message.content),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 10,
                          color:
                              isCurrentUser
                                  ? Colors.deepPurple.shade700
                                  : Colors.grey.shade700,
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.readBy?.values.every((v) => v) ?? false
                              ? Icons.done_all
                              : Icons.done,
                          size: 12,
                          color:
                              message.readBy?.values.every((v) => v) ?? false
                                  ? Colors.deepPurple
                                  : Colors.grey,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (isCurrentUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}
