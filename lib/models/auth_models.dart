class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final UserInfo user;
  final List<String> permissions;

  LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
    required this.permissions,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      tokenType: json['tokenType'],
      expiresIn: json['expiresIn'],
      user: UserInfo.fromJson(json['user']),
      permissions: List<String>.from(json['permissions']),
    );
  }
}

class UserInfo {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;

  UserInfo({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'],
      email: json['email'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      role: json['role'],
    );
  }

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
    };
  }
}

class RefreshTokenRequest {
  final String refreshToken;

  RefreshTokenRequest({
    required this.refreshToken,
  });

  Map<String, dynamic> toJson() {
    return {
      'refreshToken': refreshToken,
    };
  }
}

class RefreshTokenResponse {
  final String accessToken;
  final String tokenType;
  final int expiresIn;

  RefreshTokenResponse({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
  });

  factory RefreshTokenResponse.fromJson(Map<String, dynamic> json) {
    return RefreshTokenResponse(
      accessToken: json['accessToken'],
      tokenType: json['tokenType'],
      expiresIn: json['expiresIn'],
    );
  }
}
