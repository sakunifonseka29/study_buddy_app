import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:study_buddy_app/config/api_keys.dart';
import 'package:study_buddy_app/Util/rate_limiter.dart';

class Message {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  Message({required this.content, required this.isUser, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();
}

class QuickNotePage extends StatefulWidget {
  const QuickNotePage({super.key});

  @override
  State<QuickNotePage> createState() => _QuickNotePageState();
}

class _QuickNotePageState extends State<QuickNotePage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _headerAnimation;
  late Animation<double> _contentAnimation;
  List<Message> _messages = [];
  bool _isLoading = false;

  final String _apiKey = ApiKeys.openAiKey;
  final String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  final Dio _dio = Dio();

  int _retryCount = 0;
  final int _maxRetries = 3;

  final RateLimiter _rateLimiter = RateLimiter(
    interval: const Duration(seconds: 3),
  );

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _contentAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();

    // Add a welcome message
    _messages.add(
      Message(
        content:
            "Hi there! I'm your Study Buddy AI assistant. How can I help you today?",
        isUser: false,
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    setState(() {
      _messages.add(Message(content: userMessage, isUser: true));
      _messageController.clear();
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final response = await _dio.post(
        _apiUrl,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
          // Don't throw an exception for rate limit errors so we can handle them
          validateStatus: (status) => true,
        ),
        data: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a helpful study assistant. Provide concise, educational responses.',
            },
            ..._messages
                .map(
                  (message) => {
                    'role': message.isUser ? 'user' : 'assistant',
                    'content': message.content,
                  },
                )
                .toList(),
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final aiResponse = data['choices'][0]['message']['content'];

        setState(() {
          _messages.add(Message(content: aiResponse, isUser: false));
          _isLoading = false;
        });

        _scrollToBottom();
      } else if (response.statusCode == 429) {
        // Handle rate limiting specifically
        final errorData = response.data;
        String errorMessage = 'Rate limit exceeded. ';

        // OpenAI sometimes provides retry-after header or includes wait time in response
        final retryAfter = response.headers.value('retry-after');
        final waitTime =
            retryAfter != null ? int.tryParse(retryAfter) ?? 60 : 60;

        errorMessage += 'Please try again in ${waitTime} seconds.';

        _handleError(errorMessage);
      } else {
        // Handle other types of errors
        _handleError(
          'Error: HTTP ${response.statusCode}. ${response.data['error']?['message'] ?? 'Something went wrong.'}',
        );
      }
    } catch (error) {
      if (error is DioException) {
        if (error.type == DioExceptionType.connectionTimeout) {
          _handleError(
            'Connection timed out. Please check your internet connection and try again.',
          );
        } else if (error.type == DioExceptionType.receiveTimeout) {
          _handleError(
            'Request took too long to complete. Please try again later.',
          );
        } else {
          _handleError('Error connecting to OpenAI: ${error.message}');
        }
      } else {
        _handleError('Error: $error');
      }
    }
  }

  Future<void> _sendMessageWithRetry() async {
    try {
      await _sendMessage();
      // Reset retry count on success
      _retryCount = 0;
    } catch (e) {
      if (_retryCount < _maxRetries && e.toString().contains('429')) {
        _retryCount++;
        final waitTime = pow(2, _retryCount).toInt(); // Exponential backoff

        setState(() {
          _messages.add(
            Message(
              content: 'Rate limit exceeded. Retrying in $waitTime seconds...',
              isUser: false,
            ),
          );
        });

        _scrollToBottom();

        // Wait before retrying
        await Future.delayed(Duration(seconds: waitTime));
        await _sendMessageWithRetry(); // Retry
      } else {
        // Give up after max retries or for other errors
        _handleError('Failed after $_retryCount retries: $e');
        _retryCount = 0;
      }
    }
  }

  void _handleError(String errorMessage) {
    setState(() {
      _messages.add(Message(content: errorMessage, isUser: false));
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FadeTransition(
          opacity: _headerAnimation,
          child: const Text('AI Study Assistant'),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: FadeTransition(
              opacity: _contentAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(_contentAnimation),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return _buildMessageBubble(message);
                  },
                ),
              ),
            ),
          ),

          // Loading indicator
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(
                backgroundColor: Colors.deepPurple,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.deepPurpleAccent,
                ),
              ),
            ),

          // Input area
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Ask your study assistant...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(24)),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Color(0xFFF2F2F2),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      minLines: 1,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    onPressed:
                        _rateLimiter.isReady
                            ? () {
                              _sendMessage();
                              _rateLimiter.reset();
                            }
                            : null, // Disable button when not ready
                    backgroundColor:
                        _rateLimiter.isReady ? Colors.deepPurple : Colors.grey,
                    elevation: 2,
                    child: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: message.isUser ? Colors.deepPurple : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
        child:
            message.isUser
                ? Text(
                  message.content,
                  style: const TextStyle(color: Colors.white),
                )
                : MarkdownBody(
                  data: message.content,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(color: Colors.black87),
                    code: TextStyle(
                      backgroundColor: Colors.grey.shade300,
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                    codeblockDecoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
      ),
    );
  }
}
