import 'package:intl/intl.dart';

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderUsername;
  final String contentType;
  final String? contentText;
  final String? contentReference;
  final int editCount;
  final DateTime? editedAt;
  final String deletionState;
  final DateTime createdAt;
  final bool isDeleted;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderUsername,
    required this.contentType,
    this.contentText,
    this.contentReference,
    this.editCount = 0,
    this.editedAt,
    this.deletionState = 'active',
    required this.createdAt,
  }) : isDeleted = deletionState != 'active';

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: json['id'] as String,
    conversationId: json['conversation_id'] as String,
    senderId: json['sender_id'] as String,
    senderUsername: json['sender_username'] as String? ?? 'Unknown',
    contentType: json['content_type'] as String? ?? 'text',
    contentText: json['content_text'] as String?,
    contentReference: json['content_reference'] as String?,
    editCount: json['edit_count'] as int? ?? 0,
    editedAt: json['edited_at'] != null ? DateTime.parse(json['edited_at'] as String) : null,
    deletionState: json['deletion_state'] as String? ?? 'active',
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversation_id': conversationId,
    'sender_id': senderId,
    'sender_username': senderUsername,
    'content_type': contentType,
    'content_text': contentText,
    'content_reference': contentReference,
    'edit_count': editCount,
    'edited_at': editedAt?.toIso8601String(),
    'deletion_state': deletionState,
    'created_at': createdAt.toIso8601String(),
  };

  String get displayText {
    if (isDeleted) return 'This message was deleted';
    if (contentType == 'text') return contentText ?? '';
    if (contentType == 'image') return '📷 Photo';
    if (contentType == 'video') return '🎥 Video';
    if (contentType == 'file') return '📎 File';
    if (contentType == 'voice') return '🎙️ Voice message';
    return contentText ?? '';
  }

  String get timeString {
    return DateFormat('hh:mm a').format(createdAt.toLocal());
  }

  bool get isToday {
    final now = DateTime.now();
    return createdAt.year == now.year &&
        createdAt.month == now.month &&
        createdAt.day == now.day;
  }
}

class Conversation {
  final String id;
  final String? name;
  final DateTime createdAt;
  final DateTime? joinedAt;
  final String? lastMessageText;
  final DateTime? lastMessageAt;
  final String? lastMessageSender;
  final List<Map<String, dynamic>> participants;
  final Map<String, dynamic>? otherParticipant;

  String get displayName {
    final n = name;
    if (n != null && n.isNotEmpty) return n;
    if (otherParticipant != null) {
      return otherParticipant!['username'] as String? ?? 'Unknown';
    }
    return 'Direct conversation';
  }

  bool get hasLastMessage => lastMessageText != null && lastMessageText!.isNotEmpty;

  Conversation({
    required this.id,
    this.name,
    required this.createdAt,
    this.joinedAt,
    this.lastMessageText,
    this.lastMessageAt,
    this.lastMessageSender,
    this.participants = const [],
    this.otherParticipant,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
    id: json['id'] as String,
    name: json['name'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    joinedAt: json['joined_at'] != null ? DateTime.parse(json['joined_at'] as String) : null,
    lastMessageText: json['last_message_text'] as String?,
    lastMessageAt: json['last_message_at'] != null ? DateTime.parse(json['last_message_at'] as String) : null,
    lastMessageSender: json['last_message_sender'] as String?,
    participants: (json['participants'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList(),
    otherParticipant: json['other_participant'] != null
        ? Map<String, dynamic>.from(json['other_participant'] as Map)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'created_at': createdAt.toIso8601String(),
    'joined_at': joinedAt?.toIso8601String(),
    'last_message_text': lastMessageText,
    'last_message_at': lastMessageAt?.toIso8601String(),
    'last_message_sender': lastMessageSender,
    'participants': participants,
    'other_participant': otherParticipant,
  };

  String get lastMessageTime {
    if (lastMessageAt == null) return '';
    return DateFormat('hh:mm a').format(lastMessageAt!.toLocal());
  }

  String get lastMessageDate {
    if (lastMessageAt == null) return '';
    return DateFormat('MMM d').format(lastMessageAt!.toLocal());
  }

  bool get lastMessageIsToday {
    if (lastMessageAt == null) return false;
    final now = DateTime.now();
    return lastMessageAt!.year == now.year &&
        lastMessageAt!.month == now.month &&
        lastMessageAt!.day == now.day;
  }

  String get lastMessagePreview {
    if (!hasLastMessage) return 'No messages yet';
    final sender = lastMessageSender ?? 'You';
    final text = lastMessageText!;
    return '$sender: $text';
  }
}
