import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Platform-conditional storage service
/// Uses SharedPreferences (localStorage) on web, SecureStorage on mobile
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // Mobile storage
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  
  // Web storage (cached instance)
  SharedPreferences? _prefs;

  /// Initialize storage (call this at app startup for web)
  Future<void> initialize() async {
    if (kIsWeb) {
      _prefs = await SharedPreferences.getInstance();
    }
  }

  /// Write a key-value pair to storage
  Future<void> write({required String key, required String value}) async {
    if (kIsWeb) {
      // Web: use SharedPreferences (localStorage)
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs!.setString(key, value);
    } else {
      // Mobile: use SecureStorage
      await _secureStorage.write(key: key, value: value);
    }
  }

  /// Read a value from storage
  Future<String?> read({required String key}) async {
    if (kIsWeb) {
      // Web: use SharedPreferences
      _prefs ??= await SharedPreferences.getInstance();
      return _prefs!.getString(key);
    } else {
      // Mobile: use SecureStorage
      return await _secureStorage.read(key: key);
    }
  }

  /// Delete a single key
  Future<void> delete({required String key}) async {
    if (kIsWeb) {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs!.remove(key);
    } else {
      await _secureStorage.delete(key: key);
    }
  }

  /// Delete all stored data
  Future<void> deleteAll() async {
    if (kIsWeb) {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs!.clear();
    } else {
      await _secureStorage.deleteAll();
    }
  }

  /// Check if a key exists
  Future<bool> containsKey({required String key}) async {
    if (kIsWeb) {
      _prefs ??= await SharedPreferences.getInstance();
      return _prefs!.containsKey(key);
    } else {
      final value = await _secureStorage.read(key: key);
      return value != null;
    }
  }
}
