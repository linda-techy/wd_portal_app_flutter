class PortalLoginRequest {
  final String email;
  final String password;

  PortalLoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }

  factory PortalLoginRequest.fromJson(Map<String, dynamic> json) {
    return PortalLoginRequest(
      email: json['email'] as String,
      password: json['password'] as String,
    );
  }
}

class PortalLoginResponse {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final PortalUserInfo user;
  final List<String> permissions;

  PortalLoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
    required this.permissions,
  });

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'tokenType': tokenType,
      'expiresIn': expiresIn,
      'user': user.toJson(),
      'permissions': permissions,
    };
  }

  factory PortalLoginResponse.fromJson(Map<String, dynamic> json) {
    return PortalLoginResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      tokenType: json['tokenType'] as String,
      expiresIn: json['expiresIn'] as int,
      user: PortalUserInfo.fromJson(json['user'] as Map<String, dynamic>),
      permissions: List<String>.from(json['permissions'] as List),
    );
  }
}

class PortalUserInfo {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final bool enabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  PortalUserInfo({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.enabled,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
      'enabled': enabled,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PortalUserInfo.fromJson(Map<String, dynamic> json) {
    return PortalUserInfo(
      id: json['id'] as int,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      role: json['role'] as String,
      enabled: json['enabled'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

class PortalRefreshTokenRequest {
  final String refreshToken;

  PortalRefreshTokenRequest({
    required this.refreshToken,
  });

  Map<String, dynamic> toJson() {
    return {
      'refreshToken': refreshToken,
    };
  }

  factory PortalRefreshTokenRequest.fromJson(Map<String, dynamic> json) {
    return PortalRefreshTokenRequest(
      refreshToken: json['refreshToken'] as String,
    );
  }
}

class PortalRefreshTokenResponse {
  final String accessToken;
  final String tokenType;
  final int expiresIn;

  PortalRefreshTokenResponse({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
  });

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'tokenType': tokenType,
      'expiresIn': expiresIn,
    };
  }

  factory PortalRefreshTokenResponse.fromJson(Map<String, dynamic> json) {
    return PortalRefreshTokenResponse(
      accessToken: json['accessToken'] as String,
      tokenType: json['tokenType'] as String,
      expiresIn: json['expiresIn'] as int,
    );
  }
}
