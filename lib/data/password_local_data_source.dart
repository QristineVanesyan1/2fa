import 'dart:convert';

import 'package:authenticator/models/password_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Abstraction over password entry persistence.
///
/// Kept as an interface so consumers can be unit-tested with an in-memory fake
/// instead of touching platform channels.
abstract class PasswordLocalDataSource {
  /// Returns all stored password entries (empty list if none).
  Future<List<PasswordEntry>> getPasswords();

  /// Persists the full list of entries, replacing any existing data.
  Future<void> savePasswords(List<PasswordEntry> passwords);

  /// Appends a single entry and persists.
  Future<void> addPassword(PasswordEntry password);

  /// Replaces the entry at [index] with [password] and persists.
  Future<void> updatePassword(int index, PasswordEntry password);

  /// Removes the entry at [index] and persists.
  Future<void> deletePassword(int index);

  /// Clears all stored entries.
  Future<void> clear();
}

/// Default [PasswordLocalDataSource] backed by [SharedPreferences].
///
/// Entries are serialized to a JSON string list under a single key.
class SharedPrefsPasswordLocalDataSource implements PasswordLocalDataSource {
  SharedPrefsPasswordLocalDataSource();

  static const String _key = 'passwords_v1';

  @override
  Future<List<PasswordEntry>> getPasswords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key);
    if (raw == null) return [];
    return raw
        .map(
          (s) => PasswordEntry.fromJson(jsonDecode(s) as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<void> savePasswords(List<PasswordEntry> passwords) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = passwords.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList(_key, raw);
  }

  @override
  Future<void> addPassword(PasswordEntry password) async {
    final passwords = await getPasswords();
    passwords.add(password);
    await savePasswords(passwords);
  }

  @override
  Future<void> updatePassword(int index, PasswordEntry password) async {
    final passwords = await getPasswords();
    if (index < 0 || index >= passwords.length) return;
    passwords[index] = password;
    await savePasswords(passwords);
  }

  @override
  Future<void> deletePassword(int index) async {
    final passwords = await getPasswords();
    if (index < 0 || index >= passwords.length) return;
    passwords.removeAt(index);
    await savePasswords(passwords);
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

/// Simple in-memory [PasswordLocalDataSource] useful for tests.
class InMemoryPasswordLocalDataSource implements PasswordLocalDataSource {
  InMemoryPasswordLocalDataSource({List<PasswordEntry>? passwords})
    : _passwords = passwords ?? [];

  final List<PasswordEntry> _passwords;

  @override
  Future<List<PasswordEntry>> getPasswords() async => List.of(_passwords);

  @override
  Future<void> savePasswords(List<PasswordEntry> passwords) async {
    _passwords
      ..clear()
      ..addAll(passwords);
  }

  @override
  Future<void> addPassword(PasswordEntry password) async =>
      _passwords.add(password);

  @override
  Future<void> updatePassword(int index, PasswordEntry password) async {
    if (index < 0 || index >= _passwords.length) return;
    _passwords[index] = password;
  }

  @override
  Future<void> deletePassword(int index) async {
    if (index < 0 || index >= _passwords.length) return;
    _passwords.removeAt(index);
  }

  @override
  Future<void> clear() async => _passwords.clear();
}
