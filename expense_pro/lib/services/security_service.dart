import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityService {
  static const _kAppLockEnabledKey = 'sec_app_lock_enabled_v1';
  static const _kBiometricsEnabledKey = 'sec_biometrics_enabled_v1';
  static const _kPinHashKey = 'sec_pin_hash_v1';
  static const _kPinSalt = 'expense_pro_secure_salt_2026';

  static final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if app lock is enabled
  static Future<bool> isAppLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kAppLockEnabledKey) ?? false;
  }

  /// Toggle app lock enabled state
  static Future<void> setAppLockEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAppLockEnabledKey, enabled);
  }

  /// Check if biometric authentication is enabled
  static Future<bool> isBiometricsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kBiometricsEnabledKey) ?? false;
  }

  /// Toggle biometric authentication
  static Future<void> setBiometricsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBiometricsEnabledKey, enabled);
  }

  /// Check if a PIN code has been set
  static Future<bool> hasPinCode() async {
    final prefs = await SharedPreferences.getInstance();
    final hash = prefs.getString(_kPinHashKey);
    return hash != null && hash.isNotEmpty;
  }

  /// Save new PIN code (hashed)
  static Future<void> setPinCode(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final hash = hashPin(pin);
    await prefs.setString(_kPinHashKey, hash);
  }

  /// Verify entered PIN code against stored hash
  static Future<bool> verifyPinCode(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final storedHash = prefs.getString(_kPinHashKey);
    if (storedHash == null) return false;
    return storedHash == hashPin(pin);
  }

  /// Remove stored PIN code
  static Future<void> removePinCode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPinHashKey);
  }

  /// Hash a PIN string with salt
  static String hashPin(String pin) {
    final bytes = utf8.encode('$_kPinSalt:$pin');
    return sha256.convert(bytes).toString();
  }

  /// Check if device hardware supports biometrics
  static Future<bool> canCheckBiometrics() async {
    try {
      final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canAuthenticateWithBiometrics || isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  /// Get list of available biometric types (fingerprint, face, etc.)
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Authenticate user via biometric hardware (Face ID, Fingerprint)
  static Future<bool> authenticateWithBiometrics({
    String localizedReason = 'សូមផ្ទៀងផ្ទាត់ស្នាមម្រាមដៃ ឬទម្រង់មុខដើម្បីដោះសោកម្មវិធី',
  }) async {
    try {
      final canAuth = await canCheckBiometrics();
      if (!canAuth) return false;

      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        persistAcrossBackgrounding: true,
        biometricOnly: false,
      );
    } catch (_) {
      return false;
    }
  }
}
