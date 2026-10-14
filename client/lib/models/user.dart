class User {
  final String id;
  final String username;
  final String email;
  final String? profilePictureUrl;
  final String? currentMonarchId;
  final DateTime createdAt;
  final DateTime? birthday;
  final bool emailVerified;
  final bool isCreator;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.profilePictureUrl,
    this.currentMonarchId,
    required this.createdAt,
    this.birthday,
    required this.emailVerified,
    required this.isCreator,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String,
    username: json['username'] as String,
    email: json['email'] as String,
    profilePictureUrl: json['profile_picture_url'] as String?,
    currentMonarchId: json['current_monarch_id'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    birthday: json['birthday'] != null ? DateTime.parse(json['birthday'] as String) : null,
    emailVerified: json['email_verified'] as bool? ?? false,
    isCreator: json['is_creator'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'email': email,
    'profile_picture_url': profilePictureUrl,
    'current_monarch_id': currentMonarchId,
    'created_at': createdAt.toIso8601String(),
    'birthday': birthday?.toIso8601String(),
    'email_verified': emailVerified,
    'is_creator': isCreator,
  };
}

class AuthTokens {
  final String accessToken;
  final String refreshToken;

  AuthTokens({required this.accessToken, required this.refreshToken});

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
    accessToken: json['access_token'] as String,
    refreshToken: json['refresh_token'] as String,
  );

  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
  };
}

class AuthResponse {
  final User user;
  final AuthTokens tokens;

  AuthResponse({required this.user, required this.tokens});

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    user: User.fromJson(json['user'] as Map<String, dynamic>),
    tokens: AuthTokens.fromJson(json['tokens'] as Map<String, dynamic>),
  );
}
