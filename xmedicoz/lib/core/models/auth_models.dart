class TokensModel {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final int refreshExpiresIn;
  final String tokenType;

  TokensModel({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.refreshExpiresIn,
    this.tokenType = 'Bearer',
  });

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  factory TokensModel.fromJson(Map<String, dynamic> json) {
    final access = (json['accessToken']?.toString() ?? 
                   json['access_token']?.toString() ?? 
                   json['token']?.toString() ?? 
                   json['jwt']?.toString() ?? 
                   json['auth_token']?.toString() ?? '').trim();
                   
    final refresh = (json['refreshToken']?.toString() ?? 
                    json['refresh_token']?.toString() ?? '').trim();

    return TokensModel(
      accessToken: access,
      refreshToken: refresh,
      expiresIn: _parseInt(json['expiresIn'] ?? json['expires_in']),
      refreshExpiresIn: _parseInt(json['refreshExpiresIn'] ?? json['refresh_expires_in']),
      tokenType: json['tokenType']?.toString() ?? json['token_type']?.toString() ?? 'Bearer',
    );
  }

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'expiresIn': expiresIn,
        'refreshExpiresIn': refreshExpiresIn,
        'tokenType': tokenType,
      };
}

class UserModel {
  final String id;
  final String email;
  final String phone;
  final String firstName;
  final String lastName;
  final List<String> roles;
  final List<String> permissions;
  final String? status;
  final bool? emailVerified;
  final bool? phoneVerified;
  final String? avatarUrl;

  UserModel({
    required this.id,
    required this.email,
    required this.phone,
    required this.firstName,
    required this.lastName,
    required this.roles,
    this.permissions = const [],
    this.status,
    this.emailVerified,
    this.phoneVerified,
    this.avatarUrl,
  });

  String get fullName => '$firstName $lastName'.trim();
  bool get isAdmin => roles.any((r) => r.toLowerCase() == 'admin');

  static List<String> _parseList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      roles: _parseList(json['roles']),
      permissions: _parseList(json['permissions']),
      status: json['status']?.toString(),
      emailVerified: json['emailVerified'] as bool?,
      phoneVerified: json['phoneVerified'] as bool?,
      avatarUrl: json['avatarUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'phone': phone,
        'firstName': firstName,
        'lastName': lastName,
        'roles': roles,
        'permissions': permissions,
        'status': status,
        'emailVerified': emailVerified,
        'phoneVerified': phoneVerified,
        'avatarUrl': avatarUrl,
      };
}

class AuthDataModel {
  final TokensModel? tokens;
  final UserModel? user;

  AuthDataModel({this.tokens, this.user});

  factory AuthDataModel.fromJson(Map<String, dynamic> json) {
    TokensModel? extractedTokens;
    
    if (json['tokens'] != null) {
      extractedTokens = TokensModel.fromJson(json['tokens']);
    } else if (json['token'] != null && json['token'] is Map) {
      extractedTokens = TokensModel.fromJson(json['token']);
    } else if (json['accessToken'] != null || json['access_token'] != null || json['token'] != null) {
      // Fallback: If backend returns tokens directly inside data
      extractedTokens = TokensModel.fromJson(json);
    }

    return AuthDataModel(
      tokens: extractedTokens,
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }
}
