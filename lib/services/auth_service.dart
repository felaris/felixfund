import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite/sqflite.dart';
import 'package:felixfund/services/database_service.dart';

class AuthService extends ChangeNotifier {
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  bool _isAuthenticated = false;
  bool _isPinSet = false;

  // Getter for authentication state
  bool get isAuthenticated => _isAuthenticated;
  bool get isPinSet => _isPinSet;

  // Initialize the auth service
  Future<void> initialize() async {
    // Check if PIN is set
    final pin = await _secureStorage.read(key: 'user_pin');
    _isPinSet = pin != null && pin.isNotEmpty;
    notifyListeners();
  }

  // Create a new PIN
  Future<bool> createPin(String pin) async {
    try {
      // Store PIN securely
      await _secureStorage.write(key: 'user_pin', value: pin);

      // Create user in database
      final db = await DatabaseService().database;
      await db.insert('users', {
        'pin': pin,
      });

      _isPinSet = true;
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error creating PIN: $e');
      return false;
    }
  }

  // Verify PIN
  Future<bool> verifyPin(String pin) async {
    try {
      final storedPin = await _secureStorage.read(key: 'user_pin');
      final isValid = storedPin == pin;

      if (isValid) {
        _isAuthenticated = true;
        notifyListeners();
      }

      return isValid;
    } catch (e) {
      print('Error verifying PIN: $e');
      return false;
    }
  }

  // Change PIN
  Future<bool> changePin(String oldPin, String newPin) async {
    try {
      // Verify old PIN first
      final isValid = await verifyPin(oldPin);

      if (!isValid) {
        return false;
      }

      // Update PIN in secure storage
      await _secureStorage.write(key: 'user_pin', value: newPin);

      // Update PIN in database
      final db = await DatabaseService().database;
      await db.update(
        'users',
        {'pin': newPin},
        where: 'pin = ?',
        whereArgs: [oldPin],
      );

      return true;
    } catch (e) {
      print('Error changing PIN: $e');
      return false;
    }
  }

  // Logout
  void logout() {
    _isAuthenticated = false;
    notifyListeners();
  }
}