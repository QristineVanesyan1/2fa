import 'package:flutter/services.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';

/// Result of a biometric authentication attempt.
class BiometricResult {
  final bool success;
  final String? error;

  const BiometricResult(this.success, [this.error]);
}

/// Thin wrapper around [LocalAuthentication] for Face ID / Touch ID /
/// fingerprint authentication.
class BiometricAuth {
  BiometricAuth._();

  static final LocalAuthentication _auth = LocalAuthentication();

  /// Whether the device supports biometric checks at all.
  static Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  /// Whether the device has biometric hardware that is set up and usable.
  static Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } on PlatformException {
      return false;
    }
  }

  /// The list of enrolled biometric types (e.g. face, fingerprint).
  static Future<List<BiometricType>> availableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return const [];
    }
  }

  /// Prompts the user to authenticate with biometrics.
  static Future<BiometricResult> authenticate({
    String reason = 'Authenticate to continue',
  }) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          // Allow falling back to device passcode so it still works on
          // simulators / devices without enrolled biometrics.
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      return BiometricResult(ok, ok ? null : 'Authentication failed');
    } on PlatformException catch (e) {
      return BiometricResult(false, _messageForError(e));
    }
  }

  static String _messageForError(PlatformException e) {
    switch (e.code) {
      case auth_error.notAvailable:
        return 'Biometric authentication is not available on this device.';
      case auth_error.notEnrolled:
        return 'No biometrics enrolled. Set up Face ID/Touch ID in Settings first.';
      case auth_error.lockedOut:
      case auth_error.permanentlyLockedOut:
        return 'Biometric authentication is locked. Try again later.';
      case auth_error.passcodeNotSet:
        return 'Set a device passcode to use biometric authentication.';
      default:
        return e.message ?? 'Authentication error (${e.code}).';
    }
  }
}
