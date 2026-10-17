import 'package:flutter_test/flutter_test.dart';
import 'package:monaco/models/message.dart';
import 'package:monaco/models/user.dart';

void main() {
  group('User model', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'id': 'user-123',
        'username': 'alice',
        'email': 'alice@example.com',
        'profile_picture_url': null,
        'current_monarch_id': null,
        'created_at': '2026-01-01T00:00:00Z',
        'birthday': null,
        'email_verified': true,
        'is_creator': false,
      };

      final user = User.fromJson(json);

      expect(user.id, 'user-123');
      expect(user.username, 'alice');
      expect(user.email, 'alice@example.com');
      expect(user.profilePictureUrl, isNull);
      expect(user.currentMonarchId, isNull);
      expect(user.emailVerified, isTrue);
      expect(user.isCreator, isFalse);
    });

    test('fromJson handles optional fields', () {
      final json = {
        'id': 'user-456',
        'username': 'bob',
        'email': 'bob@example.com',
        'profile_picture_url': 'https://example.com/avatar.png',
        'current_monarch_id': 'MONARCH-001',
        'created_at': '2026-06-15T12:30:00Z',
        'birthday': '1990-05-20',
        'email_verified': false,
        'is_creator': true,
      };

      final user = User.fromJson(json);

      expect(user.profilePictureUrl, 'https://example.com/avatar.png');
      expect(user.currentMonarchId, 'MONARCH-001');
      expect(user.birthday, isNotNull);
      expect(user.emailVerified, isFalse);
      expect(user.isCreator, isTrue);
    });

    test('toJson round-trips correctly', () {
      final user = User(
        id: 'user-789',
        username: 'carol',
        email: 'carol@example.com',
        profilePictureUrl: 'https://example.com/carol.png',
        currentMonarchId: 'MONARCH-002',
        createdAt: DateTime(2026, 1, 15),
        birthday: DateTime(1985, 8, 10),
        emailVerified: true,
        isCreator: false,
      );

      final json = user.toJson();
      final parsed = User.fromJson(json);

      expect(parsed.id, user.id);
      expect(parsed.username, user.username);
      expect(parsed.email, user.email);
      expect(parsed.emailVerified, user.emailVerified);
      expect(parsed.isCreator, user.isCreator);
    });
  });

  group('AuthTokens model', () {
    test('fromJson parses tokens correctly', () {
      final json = {
        'access_token': 'access-token-abc',
        'refresh_token': 'refresh-token-xyz',
      };

      final tokens = AuthTokens.fromJson(json);

      expect(tokens.accessToken, 'access-token-abc');
      expect(tokens.refreshToken, 'refresh-token-xyz');
    });

    test('toJson round-trips correctly', () {
      final tokens = AuthTokens(
        accessToken: 'acc-123',
        refreshToken: 'ref-456',
      );

      final json = tokens.toJson();
      final parsed = AuthTokens.fromJson(json);

      expect(parsed.accessToken, tokens.accessToken);
      expect(parsed.refreshToken, tokens.refreshToken);
    });
  });

  group('AuthResponse model', () {
    test('fromJson parses user and tokens', () {
      final json = {
        'user': {
          'id': 'user-1',
          'username': 'dave',
          'email': 'dave@example.com',
          'profile_picture_url': null,
          'current_monarch_id': null,
          'created_at': '2026-01-01T00:00:00Z',
          'birthday': null,
          'email_verified': false,
          'is_creator': false,
        },
        'tokens': {
          'access_token': 'acc-abc',
          'refresh_token': 'ref-xyz',
        },
      };

      final response = AuthResponse.fromJson(json);

      expect(response.user.id, 'user-1');
      expect(response.user.username, 'dave');
      expect(response.tokens.accessToken, 'acc-abc');
      expect(response.tokens.refreshToken, 'ref-xyz');
    });

    test('fromJson throws when user is missing', () {
      final json = {
        'tokens': {
          'access_token': 'acc-abc',
          'refresh_token': 'ref-xyz',
        },
      };

      expect(
        () => AuthResponse.fromJson(json),
        isA<TypeError>(),
      );
    });

    test('fromJson throws when tokens is missing', () {
      final json = {
        'user': {
          'id': 'user-1',
          'username': 'dave',
          'email': 'dave@example.com',
          'profile_picture_url': null,
          'current_monarch_id': null,
          'created_at': '2026-01-01T00:00:00Z',
          'birthday': null,
          'email_verified': false,
          'is_creator': false,
        },
      };

      expect(
        () => AuthResponse.fromJson(json),
        isA<TypeError>(),
      );
    });
  });

  group('Message model', () {
    test('fromJson parses text message', () {
      final json = {
        'id': 'msg-1',
        'conversation_id': 'conv-1',
        'sender_id': 'user-1',
        'sender_username': 'alice',
        'content_type': 'text',
        'content_text': 'Hello world',
        'content_reference': null,
        'edit_count': 0,
        'edited_at': null,
        'deletion_state': 'active',
        'created_at': '2026-01-15T10:30:00Z',
      };

      final message = Message.fromJson(json);

      expect(message.id, 'msg-1');
      expect(message.senderUsername, 'alice');
      expect(message.contentType, 'text');
      expect(message.contentText, 'Hello world');
      expect(message.displayText, 'Hello world');
      expect(message.isDeleted, isFalse);
    });

    test('displayText returns deleted message for deleted messages', () {
      final json = {
        'id': 'msg-2',
        'conversation_id': 'conv-1',
        'sender_id': 'user-1',
        'sender_username': 'alice',
        'content_type': 'text',
        'content_text': null,
        'content_reference': null,
        'edit_count': 0,
        'edited_at': null,
        'deletion_state': 'deleted_for_everyone',
        'created_at': '2026-01-15T10:30:00Z',
      };

      final message = Message.fromJson(json);

      expect(message.isDeleted, isTrue);
      expect(message.displayText, 'This message was deleted');
    });

    test('fromJson parses image message', () {
      final json = {
        'id': 'msg-3',
        'conversation_id': 'conv-1',
        'sender_id': 'user-1',
        'sender_username': 'bob',
        'content_type': 'image',
        'content_text': null,
        'content_reference': 'https://example.com/image.jpg',
        'edit_count': 0,
        'edited_at': null,
        'deletion_state': 'active',
        'created_at': '2026-01-15T11:00:00Z',
      };

      final message = Message.fromJson(json);

      expect(message.contentType, 'image');
      expect(message.displayText, '📷 Photo');
    });

    test('timeString formats correctly', () {
      final message = Message(
        id: 'msg-1',
        conversationId: 'conv-1',
        senderId: 'user-1',
        senderUsername: 'alice',
        contentType: 'text',
        contentText: 'Hello',
        createdAt: DateTime(2026, 1, 15, 14, 30),
      );

      expect(message.timeString, contains('2:30 PM'));
    });
  });

  group('Conversation model', () {
    test('fromJson parses conversation with last message', () {
      final json = {
        'id': 'conv-1',
        'name': null,
        'created_at': '2026-01-10T00:00:00Z',
        'joined_at': '2026-01-10T00:00:00Z',
        'last_message_text': 'Hello there',
        'last_message_at': '2026-01-15T10:30:00Z',
        'last_message_sender': 'alice',
        'participants': [
          {
            'id': 'user-1',
            'username': 'alice',
            'email': 'alice@example.com',
          },
          {
            'id': 'user-2',
            'username': 'bob',
            'email': 'bob@example.com',
          },
        ],
        'other_participant': {
          'id': 'user-2',
          'username': 'bob',
          'email': 'bob@example.com',
        },
      };

      final conversation = Conversation.fromJson(json);

      expect(conversation.id, 'conv-1');
      expect(conversation.name, isNull);
      expect(conversation.displayName, 'bob');
      expect(conversation.hasLastMessage, isTrue);
      expect(conversation.lastMessagePreview, 'alice: Hello there');
      expect(conversation.otherParticipant, isNotNull);
      expect(conversation.participants.length, 2);
    });

    test('displayName falls back to default when no name and no participant', () {
      final json = {
        'id': 'conv-2',
        'name': null,
        'created_at': '2026-01-10T00:00:00Z',
        'joined_at': null,
        'last_message_text': null,
        'last_message_at': null,
        'last_message_sender': null,
        'participants': [],
        'other_participant': null,
      };

      final conversation = Conversation.fromJson(json);

      expect(conversation.displayName, 'Direct conversation');
      expect(conversation.hasLastMessage, isFalse);
      expect(conversation.lastMessagePreview, 'No messages yet');
    });

    test('fromJson parses named conversation', () {
      final json = {
        'id': 'conv-3',
        'name': 'Project Discussion',
        'created_at': '2026-01-10T00:00:00Z',
        'joined_at': null,
        'last_message_text': null,
        'last_message_at': null,
        'last_message_sender': null,
        'participants': [],
        'other_participant': null,
      };

      final conversation = Conversation.fromJson(json);

      expect(conversation.displayName, 'Project Discussion');
    });

    test('toJson round-trips correctly', () {
      final conversation = Conversation(
        id: 'conv-4',
        name: 'Test Chat',
        createdAt: DateTime(2026, 1, 10),
        lastMessageText: 'Hello',
        lastMessageAt: DateTime(2026, 1, 15),
        lastMessageSender: 'alice',
        participants: [
          {'id': 'user-1', 'username': 'alice'},
        ],
        otherParticipant: {'id': 'user-2', 'username': 'bob'},
      );

      final json = conversation.toJson();
      final parsed = Conversation.fromJson(json);

      expect(parsed.id, conversation.id);
      expect(parsed.name, conversation.name);
      expect(parsed.lastMessageText, conversation.lastMessageText);
      expect(parsed.lastMessageSender, conversation.lastMessageSender);
      expect(parsed.participants.length, conversation.participants.length);
    });
  });
}
