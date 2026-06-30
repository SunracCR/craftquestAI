class AuthTokensModel {
  const AuthTokensModel({
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthTokensModel.fromJson(Map<String, dynamic> json) {
    return AuthTokensModel(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }

  final String accessToken;
  final String refreshToken;
}

class UserProfileModel {
  const UserProfileModel({
    required this.userId,
    required this.email,
    this.displayName,
    this.avatarId,
    this.preferredLanguage,
    required this.roles,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      userId: json['userId'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      avatarId: json['avatarId'] as String?,
      preferredLanguage: json['preferredLanguage'] as String?,
      roles: (json['roles'] as List<dynamic>).cast<String>(),
    );
  }

  final String userId;
  final String email;
  final String? displayName;
  final String? avatarId;
  final String? preferredLanguage;
  final List<String> roles;

  UserProfileModel copyWith({
    String? displayName,
    String? avatarId,
    String? preferredLanguage,
  }) {
    return UserProfileModel(
      userId: userId,
      email: email,
      displayName: displayName ?? this.displayName,
      avatarId: avatarId ?? this.avatarId,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      roles: roles,
    );
  }
}

class AuthResponseModel {
  const AuthResponseModel({
    required this.tokens,
    required this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      tokens: AuthTokensModel.fromJson(json['tokens'] as Map<String, dynamic>),
      user: UserProfileModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  final AuthTokensModel tokens;
  final UserProfileModel user;
}

class RegisterResultModel {
  const RegisterResultModel({
    required this.requiresEmailVerification,
    required this.email,
    this.requiresParentalConsent = false,
    this.guardianEmail,
  });

  factory RegisterResultModel.fromJson(Map<String, dynamic> json) {
    return RegisterResultModel(
      requiresEmailVerification:
          json['requiresEmailVerification'] as bool? ?? true,
      requiresParentalConsent:
          json['requiresParentalConsent'] as bool? ?? false,
      email: json['email'] as String,
      guardianEmail: json['guardianEmail'] as String?,
    );
  }

  final bool requiresEmailVerification;
  final bool requiresParentalConsent;
  final String email;
  final String? guardianEmail;
}
