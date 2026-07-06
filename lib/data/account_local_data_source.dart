import 'dart:convert';

import 'package:authenticator/models/account.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Abstraction over 2FA account persistence.
///
/// Kept as an interface so consumers can be unit-tested with an in-memory fake
/// instead of touching platform channels.
abstract class AccountLocalDataSource {
  /// Returns all stored accounts (empty list if none).
  Future<List<Account>> getAccounts();

  /// Persists the full list of accounts, replacing any existing data.
  Future<void> saveAccounts(List<Account> accounts);

  /// Appends a single account and persists.
  Future<void> addAccount(Account account);

  /// Removes the account at [index] and persists.
  Future<void> deleteAccount(int index);

  /// Clears all stored accounts.
  Future<void> clear();
}

/// Default [AccountLocalDataSource] backed by [SharedPreferences].
///
/// Accounts are serialized to a JSON string list under a single key.
class SharedPrefsAccountLocalDataSource implements AccountLocalDataSource {
  SharedPrefsAccountLocalDataSource();

  static const String _key = 'accounts_v1';

  @override
  Future<List<Account>> getAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key);
    if (raw == null) return [];
    return raw
        .map((s) => Account.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveAccounts(List<Account> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = accounts.map((a) => jsonEncode(a.toJson())).toList();
    await prefs.setStringList(_key, raw);
  }

  @override
  Future<void> addAccount(Account account) async {
    final accounts = await getAccounts();
    accounts.add(account);
    await saveAccounts(accounts);
  }

  @override
  Future<void> deleteAccount(int index) async {
    final accounts = await getAccounts();
    if (index < 0 || index >= accounts.length) return;
    accounts.removeAt(index);
    await saveAccounts(accounts);
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

/// Simple in-memory [AccountLocalDataSource] useful for tests.
class InMemoryAccountLocalDataSource implements AccountLocalDataSource {
  InMemoryAccountLocalDataSource({List<Account>? accounts})
    : _accounts = accounts ?? [];

  final List<Account> _accounts;

  @override
  Future<List<Account>> getAccounts() async => List.of(_accounts);

  @override
  Future<void> saveAccounts(List<Account> accounts) async {
    _accounts
      ..clear()
      ..addAll(accounts);
  }

  @override
  Future<void> addAccount(Account account) async => _accounts.add(account);

  @override
  Future<void> deleteAccount(int index) async {
    if (index < 0 || index >= _accounts.length) return;
    _accounts.removeAt(index);
  }

  @override
  Future<void> clear() async => _accounts.clear();
}
