import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:monaco/providers/auth_provider.dart';
import 'package:monaco/services/chat_api.dart';
import 'package:monaco/models/message.dart';
import 'package:monaco/utils/design_system.dart';
import 'package:monaco/widgets/monaco_loader.dart';

class ConversationScreen extends StatefulWidget {
  final String conversationId;
  final String conversationTitle;

  const ConversationScreen({
    super.key,
    required this.conversationId,
    required this.conversationTitle,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen>
    with WidgetsBindingObserver {
  final ChatApiService _api = ChatApiService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;
  String? _currentUserId;
  Timer? _pollTimer;
  bool _isAppVisible = true;

  static const Duration _pollInterval = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadMessages();
    _startPolling();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _isAppVisible = state == AppLifecycleState.resumed;
    });
    if (_isAppVisible) {
      _loadMessages();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    _pollTimer?.cancel();
    _api.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      if (!_isSending && _isAppVisible && mounted) {
        _loadMessages();
      }
    });
  }

  Future<void> _loadMessages() async {
    final auth = context.read<AuthProvider>();
    final token = auth.tokens?.accessToken;
    if (token == null) return;

    setState(() {
      if (_messages.isEmpty) {
        _isLoading = true;
        _error = null;
      }
    });

    try {
      final messages = await _api.getMessages(
        conversationId: widget.conversationId,
        accessToken: token,
        limit: 50,
      );

      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
          _currentUserId = auth.user?.id;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    final auth = context.read<AuthProvider>();
    final token = auth.tokens?.accessToken;
    if (token == null) return;

    setState(() {
      _isSending = true;
      _error = null;
    });

    final controller = _messageController;
    controller.clear();

    try {
      await _api.sendMessage(
        conversationId: widget.conversationId,
        accessToken: token,
        contentType: 'text',
        contentText: text,
      );
      await _loadMessages();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
        });
        controller.text = text; // Restore text on failure
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
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

  Widget _buildMessage(Message message) {
    final isMe = message.senderId == _currentUserId;
    final alignment = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = isMe
        ? MonacoDesign.inkBlack
        : Theme.of(context).colorScheme.surfaceContainerHighest;
    final textColor = isMe
        ? Colors.white
        : Theme.of(context).colorScheme.onSurface;

    return Align(
      alignment: alignment == CrossAxisAlignment.end ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: Column(
          crossAxisAlignment: alignment,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(MonacoDesign.radiusLg),
                  topRight: const Radius.circular(MonacoDesign.radiusLg),
                  bottomLeft: isMe ? const Radius.circular(MonacoDesign.radiusLg) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(MonacoDesign.radiusLg),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.displayText,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  if (message.editCount > 0)
                    Text(
                      'Edited',
                      style: TextStyle(
                        color: textColor.withOpacity(0.6),
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Padding(
              padding: EdgeInsets.only(
                left: isMe ? 0 : 4,
                right: isMe ? 4 : 0,
              ),
              child: Text(
                message.timeString,
                style: TextStyle(
                  color: textColor.withOpacity(0.5),
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MonacoDesign.charcoalDeep,
      appBar: AppBar(
        title: Text(
          widget.conversationTitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading && _messages.isEmpty
                ? const MonacoLoader()
                : _error != null && _messages.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: MonacoDesign.error.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline_rounded,
                      color: MonacoDesign.error,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: MonacoDesign.md),
                  Text(
                    'Couldn’t load messages',
                    style: MonacoDesign.headlineMedium(context).copyWith(
                      fontWeight: FontWeight.w800,
                      color: MonacoDesign.textInk,
                    ),
                  ),
                  const SizedBox(height: MonacoDesign.sm),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: MonacoDesign.bodyMedium(context).copyWith(
                      color: MonacoDesign.textSecondary,
                    ),
                  ),
                  const SizedBox(height: MonacoDesign.lg),
                  FilledButton(
                    onPressed: _loadMessages,
                    style: MonacoDesign.primaryButton(context),
                    child: const Text('Try again'),
                  ),
                ],
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              reverse: false,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildMessage(_messages[index]),
            ),
          ),
          if (_error != null && _messages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                _error!,
                style: TextStyle(
                  color: MonacoDesign.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: MonacoDesign.charcoalCard,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(MonacoDesign.radiusFull),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(MonacoDesign.radiusFull),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(MonacoDesign.radiusFull),
                    borderSide: BorderSide(color: MonacoDesign.inkBlack, width: 1.5),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                style: const TextStyle(fontSize: 15),
              ),
            ),
            const SizedBox(width: MonacoDesign.sm),
            Container(
              decoration: BoxDecoration(
                color: MonacoDesign.inkBlack,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: MonacoDesign.inkBlack.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                onPressed: _isSending ? null : _sendMessage,
                tooltip: 'Send',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
