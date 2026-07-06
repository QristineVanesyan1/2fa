import 'package:flutter/material.dart';

/// Model describing a single 2FA account.
///
/// Serializable so it can be persisted (e.g. in SharedPreferences) via the
/// account local data source.
class Account {
  final String name;
  final String issuerEmail;
  final String secret; // Base32 encoded TOTP secret.
  final String code; // formatted, e.g. "482 091"
  final Color avatarColor;

  const Account({
    required this.name,
    required this.issuerEmail,
    this.secret = '',
    this.code = '',
    this.avatarColor = const Color(0xFF0D0D0D),
  });

  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';

  Account copyWith({
    String? name,
    String? issuerEmail,
    String? secret,
    String? code,
    Color? avatarColor,
  }) {
    return Account(
      name: name ?? this.name,
      issuerEmail: issuerEmail ?? this.issuerEmail,
      secret: secret ?? this.secret,
      code: code ?? this.code,
      avatarColor: avatarColor ?? this.avatarColor,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'issuerEmail': issuerEmail,
    'secret': secret,
    'code': code,
    'avatarColor': avatarColor.toARGB32(),
  };

  factory Account.fromJson(Map<String, dynamic> json) => Account(
    name: json['name'] as String? ?? '',
    issuerEmail: json['issuerEmail'] as String? ?? '',
    secret: json['secret'] as String? ?? '',
    code: json['code'] as String? ?? '',
    avatarColor: Color(json['avatarColor'] as int? ?? 0xFF0D0D0D),
  );
}
