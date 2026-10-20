import 'package:flutter/foundation.dart';
import 'package:monaco/models/message.dart';
import 'package:monaco/models/user.dart';

/// Demo identity for development / exploration without real registration.
///
/// This identity is clearly distinguishable from normal registered users.
/// It is never used for production authentication.
class DemoIdentity {
  static const String id = 'demo-alex-morgan-001';
  static const String username = 'alexmorgan_demo';
  static const String email = 'alex.morgan@demo.monaco';
  static const String displayName = 'Alex Morgan';
  static const String profilePictureUrl = null;
  static const bool isDemo = true;

  static User toUser() => User(
        id: id,
        username: username,
        email: email,
        profilePictureUrl: profilePictureUrl,
        currentMonarchId: null,
        createdAt: DateTime(2026, 1, 15),
        birthday: null,
        emailVerified: true,
        isCreator: false,
      );

  static AuthTokens toTokens() => const AuthTokens(
        accessToken: 'demo-access-token-alex-morgan',
        refreshToken: 'demo-refresh-token-alex-morgan',
      );

  static AuthResponse toAuthResponse() => AuthResponse(user: toUser(), tokens: toTokens());
}

/// Seeded demo users for demonstration purposes.
class DemoUsers {
  static const List<Map<String, dynamic>> users = [
    {
      'id': 'demo-user-maya-001',
      'username': 'maya_chen',
      'email': 'maya.chen@demo.monaco',
      'profile_picture_url': null,
      'current_monarch_id': null,
      'created_at': '2026-01-10T00:00:00Z',
      'birthday': null,
      'email_verified': true,
      'is_creator': false,
    },
    {
      'id': 'demo-user-theo-001',
      'username': 'theo_reyes',
      'email': 'theo.reyes@demo.monaco',
      'profile_picture_url': null,
      'current_monarch_id': null,
      'created_at': '2026-02-03T00:00:00Z',
      'birthday': null,
      'email_verified': true,
      'is_creator': false,
    },
    {
      'id': 'demo-user-sara-001',
      'username': 'sara_connor',
      'email': 'sara.connor@demo.monaco',
      'profile_picture_url': null,
      'current_monarch_id': null,
      'created_at': '2026-03-12T00:00:00Z',
      'birthday': null,
      'email_verified': false,
      'is_creator': false,
    },
    {
      'id': 'demo-user-leo-001',
      'username': 'leo_tan',
      'email': 'leo.tan@demo.monaco',
      'profile_picture_url': null,
      'current_monarch_id': null,
      'created_at': '2026-04-20T00:00:00Z',
      'birthday': null,
      'email_verified': true,
      'is_creator': false,
    },
    {
      'id': 'demo-user-nina-001',
      'username': 'nina_patel',
      'email': 'nina.patel@demo.monaco',
      'profile_picture_url': null,
      'current_monarch_id': null,
      'created_at': '2026-05-08T00:00:00Z',
      'birthday': null,
      'email_verified': true,
      'is_creator': false,
    },
  ];

  static List<User> toUserList() {
    return users.map((u) => User.fromJson(Map<String, dynamic>.from(u))).toList();
  }

  static User get maya => toUserList()[0];
  static User get theo => toUserList()[1];
  static User get sara => toUserList()[2];
  static User get leo => toUserList()[3];
  static User get nina => toUserList()[4];
}

/// Seeded demo conversations: Councils (3+ participants) and private DMs (2 participants).
class DemoConversations {
  static const now = DateTime(2026, 10, 20, 14, 30);

  static const List<Map<String, dynamic>> councils = [
    {
      'id': 'demo-council-design-001',
      'name': 'The Design Council',
      'created_at': '2026-01-10T00:00:00Z',
      'joined_at': '2026-01-10T00:00:00Z',
      'last_message_text': 'Nota: New direction is looking good.',
      'last_message_at': '2026-10-20T14:25:00Z',
      'last_message_sender': 'maya_chen',
      'participants': [
        {'id': 'demo-alex-morgan-001', 'username': 'alexmorgan_demo'},
        {'id': 'demo-user-maya-001', 'username': 'maya_chen'},
        {'id': 'demo-user-theo-001', 'username': 'theo_reyes'},
        {'id': 'demo-user-sara-001', 'username': 'sara_connor'},
      ],
      'other_participant': null,
    },
    {
      'id': 'demo-council-weekend-001',
      'name': 'Weekend people',
      'created_at': '2026-02-03T00:00:00Z',
      'joined_at': '2026-02-03T00:00:00Z',
      'last_message_text': 'Sam: Table booked for six.',
      'last_message_at': '2026-10-20T14:10:00Z',
      'last_message_sender': 'theo_reyes',
      'participants': [
        {'id': 'demo-alex-morgan-001', 'username': 'alexmorgan_demo'},
        {'id': 'demo-user-theo-001', 'username': 'theo_reyes'},
        {'id': 'demo-user-nina-001', 'username': 'nina_patel'},
      ],
      'other_participant': null,
    },
    {
      'id': 'demo-council-study-001',
      'name': 'Study Circle',
      'created_at': '2026-03-12T00:00:00Z',
      'joined_at': '2026-03-12T00:00:00Z',
      'last_message_text': 'Alex: Final revision done?',
      'last_message_at': '2026-10-20T13:45:00Z',
      'last_message_sender': 'alexmorgan_demo',
      'participants': [
        {'id': 'demo-alex-morgan-001', 'username': 'alexmorgan_demo'},
        {'id': 'demo-user-leo-001', 'username': 'leo_tan'},
        {'id': 'demo-user-nina-001', 'username': 'nina_patel'},
      ],
      'other_participant': null,
    },
  ];

  static const List<Map<String, dynamic>> dms = [
    {
      'id': 'demo-dm-maya-001',
      'name': null,
      'created_at': '2026-01-15T00:00:00Z',
      'joined_at': '2026-01-15T00:00:00Z',
      'last_message_text': "You: I'll send it tonight.",
      'last_message_at': '2026-10-20T13:20:00Z',
      'last_message_sender': 'alexmorgan_demo',
      'participants': [
        {'id': 'demo-alex-morgan-001', 'username': 'alexmorgan_demo'},
        {'id': 'demo-user-maya-001', 'username': 'maya_chen'},
      ],
      'other_participant': {
        'id': 'demo-user-maya-001',
        'username': 'maya_chen',
        'email': 'maya.chen@demo.monaco',
      },
    },
    {
      'id': 'demo-dm-theo-001',
      'name': null,
      'created_at': '2026-02-05T00:00:00Z',
      'joined_at': '2026-02-05T00:00:00Z',
      'last_message_text': 'Theo: Are we still on for coffee?',
      'last_message_at': '2026-10-19T16:45:00Z',
      'last_message_sender': 'theo_reyes',
      'participants': [
        {'id': 'demo-alex-morgan-001', 'username': 'alexmorgan_demo'},
        {'id': 'demo-user-theo-001', 'username': 'theo_reyes'},
      ],
      'other_participant': {
        'id': 'demo-user-theo-001',
        'username': 'theo_reyes',
        'email': 'theo.reyes@demo.monaco',
      },
    },
    {
      'id': 'demo-dm-leo-001',
      'name': null,
      'created_at': '2026-04-22T00:00:00Z',
      'joined_at': '2026-04-22T00:00:00Z',
      'last_message_text': "Leo: Can't make it tonight.",
      'last_message_at': '2026-10-18T09:30:00Z',
      'last_message_sender': 'leo_tan',
      'participants': [
        {'id': 'demo-alex-morgan-001', 'username': 'alexmorgan_demo'},
        {'id': 'demo-user-leo-001', 'username': 'leo_tan'},
      ],
      'other_participant': {
        'id': 'demo-user-leo-001',
        'username': 'leo_tan',
        'email': 'leo.tan@demo.monaco',
      },
    },
  ];

  static List<Conversation> toConversationList() {
    return [
      ...councils.map((c) => Conversation.fromJson(Map<String, dynamic>.from(c))),
      ...dms.map((d) => Conversation.fromJson(Map<String, dynamic>.from(d))),
    ];
  }

  static List<Conversation> getCouncils() {
    return toConversationList().where((c) => c.isGroup).toList();
  }

  static List<Conversation> getDMs() {
    return toConversationList().where((c) => !c.isGroup).toList()..sort((a, b) {
      final aTime = a.lastMessageAt ?? DateTime(1970);
      final bTime = b.lastMessageAt ?? DateTime(1970);
      return bTime.compareTo(aTime);
    });
  }
}

/// Seeded demo messages for the Design Council conversation.
class DemoMessages {
  static const List<Map<String, dynamic>> messages = [
    {
      'id': 'demo-msg-001',
      'conversation_id': 'demo-council-design-001',
      'sender_id': 'demo-user-maya-001',
      'sender_username': 'maya_chen',
      'content_type': 'text',
      'content_text': 'Hey everyone, new direction is looking good.',
      'content_reference': null,
      'edit_count': 0,
      'edited_at': null,
      'deletion_state': 'active',
      'created_at': '2026-10-20T14:25:00Z',
    },
    {
      'id': 'demo-msg-002',
      'conversation_id': 'demo-council-design-001',
      'sender_id': 'demo-user-theo-001',
      'sender_username': 'theo_reyes',
      'content_type': 'text',
      'content_text': 'I agree. The color palette works well.',
      'content_reference': null,
      'edit_count': 0,
      'edited_at': null,
      'deletion_state': 'active',
      'created_at': '2026-10-20T14:26:00Z',
    },
    {
      'id': 'demo-msg-003',
      'conversation_id': 'demo-council-design-001',
      'sender_id': 'demo-alex-morgan-001',
      'sender_username': 'alexmorgan_demo',
      'content_type': 'text',
      'content_text': 'Great, let me know if you need any changes.',
      'content_reference': null,
      'edit_count': 0,
      'edited_at': null,
      'deletion_state': 'active',
      'created_at': '2026-10-20T14:27:00Z',
    },
  ];

  static List<Message> toMessageList(String conversationId) {
    return messages
        .where((m) => m['conversation_id'] == conversationId)
        .map((m) => Message.fromJson(Map<String, dynamic>.from(m)))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }
}

/// Demo mode provider — manages demo identity, seeded data, and demo state.
class DemoModeProvider extends ChangeNotifier {
  bool _isDemoMode = false;
  User? _demoUser;
  List<User> _demoUsers = [];
  List<Conversation> _demoConversations = [];
  List<Conversation> _demoCouncils = [];
  List<Conversation> _demoDMs = [];
  String _error;

  bool get isDemoMode => _isDemoMode;
  User? get demoUser => _demoUser;
  List<User> get demoUsers => _demoUsers;
  List<Conversation> get demoConversations => _demoConversations;
  List<Conversation> get demoCouncils => _demoCouncils;
  List<Conversation> get demoDMs => _demoDMs;
  String? get error => _error;

  DemoModeProvider() {
    _error = null;
  }

  /// Activate demo mode with seeded data.
  Future<void> activateDemoMode() async {
    _isDemoMode = true;
    _error = null;

    try {
      _demoUser = DemoIdentity.toUser();
      _demoUsers = DemoUsers.toUserList();
      _demoConversations = DemoConversations.toConversationList();
      _demoCouncils = DemoConversations.getCouncils();
      _demoDMs = DemoConversations.getDMs();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isDemoMode = false;
      notifyListeners();
    }
  }

  /// Reset demo data to its initial seeded state.
  Future<void> resetDemoData() async {
    _error = null;
    try {
      _demoUser = DemoIdentity.toUser();
      _demoUsers = DemoUsers.toUserList();
      _demoConversations = DemoConversations.toConversationList();
      _demoCouncils = DemoConversations.getCouncils();
      _demoDMs = DemoConversations.getDMs();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Deactivate demo mode and clear all demo data.
  Future<void> deactivateDemoMode() async {
    _isDemoMode = false;
    _demoUser = null;
    _demoUsers = [];
    _demoConversations = [];
    _demoCouncils = [];
    _demoDMs = [];
    _error = null;
    notifyListeners();
  }

  /// Get demo messages for a given conversation.
  List<Message> getDemoMessages(String conversationId) {
    return DemoMessages.toMessageList(conversationId);
  }

  /// Get a demo user by ID.
  User? getDemoUserById(String id) {
    return _demoUsers.firstWhere((u) => u.id == id, orElse: () => null);
  }

  /// Get a demo conversation by ID.
  Conversation? getDemoConversationById(String id) {
    return _demoConversations.firstWhere((c) => c.id == id, orElse: () => null);
  }

  /// Check if a user ID is the demo user.
  bool isDemoUserId(String id) => id == DemoIdentity.id;

  /// Clear any error.
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

/// Demo AuthTokens for demo identity.
class AuthTokens {
  final String accessToken;
  final String refreshToken;

  const AuthTokens({required this.accessToken, required this.refreshToken});
}

/// Demo AuthResponse for demo identity.
class AuthResponse {
  final User user;
  final AuthTokens tokens;

  AuthResponse({required this.user, required this.tokens});
}
