import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mathmate/models/user_profile.dart';

class UserProfileService extends ChangeNotifier {
  static final UserProfileService _instance = UserProfileService._();
  factory UserProfileService() => _instance;
  UserProfileService._();

  static const _key = 'user_profile';

  UserProfile _profile = UserProfile();
  UserProfile get profile => _profile;

  bool _loaded = false;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        _profile = UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        _profile = UserProfile();
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> save(UserProfile profile) async {
    _profile = profile;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_profile.toJson()));
    notifyListeners();
  }

  Future<void> reset() async {
    _profile = UserProfile();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    _loaded = false;
    notifyListeners();
  }
}
