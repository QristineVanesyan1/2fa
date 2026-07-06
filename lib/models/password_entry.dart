/// Model describing a single stored password entry.
///
/// Serializable so it can be persisted (e.g. in SharedPreferences) via the
/// password local data source.
class PasswordEntry {
  final String service;
  final String account;
  final String password;

  const PasswordEntry({
    required this.service,
    required this.account,
    required this.password,
  });

  String get initial => service.isNotEmpty ? service[0].toUpperCase() : '?';

  PasswordEntry copyWith({String? service, String? account, String? password}) {
    return PasswordEntry(
      service: service ?? this.service,
      account: account ?? this.account,
      password: password ?? this.password,
    );
  }

  Map<String, dynamic> toJson() => {
    'service': service,
    'account': account,
    'password': password,
  };

  factory PasswordEntry.fromJson(Map<String, dynamic> json) => PasswordEntry(
    service: json['service'] as String? ?? '',
    account: json['account'] as String? ?? '',
    password: json['password'] as String? ?? '',
  );
}
