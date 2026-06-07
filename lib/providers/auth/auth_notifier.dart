import 'dart:async';
import 'dart:convert';
import 'package:done_today/services/encryption_service.dart';
import 'package:done_today/state/auth/auth_state.dart';
import 'package:done_today/storage/hive/hive_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

class AuthNotifier extends Notifier<AuthState> {

  bool get isLoggedIn => state is AuthLoggedIn;

  Future<String?> _cacheImageAsBase64(String? url) async {
    if (url == null) return null;
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return base64Encode(response.bodyBytes);
      }
    } catch (e) {
      debugPrint("Auth: Failed to cache avatar: $e");
    }
    return null;
  }

  @override
  AuthState build() {
    // Initialize session asynchronously
    Future.microtask(() => _restoreSession());
    return AuthInitial();
  }

  // -------------------
  // Session Management
  // -------------------
  Future<void> _restoreSession() async {
    // 1. Check Hive first for immediate offline support
    final token = HiveService.getToken();
    final userDetails = HiveService.getUserDetails();

    if (token != null && userDetails != null) {
      EncryptionService().init(userDetails['id'] as String);
      state = AuthLoggedIn(token: token, userDetails: userDetails);
      // Don't return yet, we'll verify with Supabase in the background
    } else {
      state = AuthLoading();
    }
  }

  // -------------------
  // Authentication
  // -------------------

  Future<void> initializeAccount() async {
    state = AuthLoading();
    try {
      final userDetails = {
        'id': 'user_${DateTime.now().millisecondsSinceEpoch}',
        'email': 'local@account',
        'name': 'Daily Explorer',
        'avatar': null,
        'avatar_data': null,
        'isLocal': true,
        'feedback': null,
      };

      // Save to Hive for offline support
      await HiveService.setToken('local_session');
      await HiveService.setUserDetails(userDetails);

      EncryptionService().init(userDetails['id'] as String);
      state = AuthLoggedIn(token: 'local_session', userDetails: userDetails);
    } catch (e) {
      state = AuthError("Account initialization failed: $e");
    }
  }

  Future<void> logout() async {
    state = AuthLoading();
    try {
      //  Clear local storage and state
      await HiveService.clearAllData();
      state = AuthLoggedOut();
    } catch (e) {
      debugPrint("Auth: Logout error: $e");
      // Still try to clear local data even if an error occurred
      await HiveService.clearAllData();
      state = AuthLoggedOut();
    }
  }

  Future<void> updateProfile({
    String? name,
    String? avatarUrl,
    Uint8List? avatarBytes,
  }) async {
    final currentState = state;
    if (currentState is! AuthLoggedIn) return;

    final isLocal = currentState.userDetails['isLocal'] == true;

    try {
      // Update local state
      final newUserDetails = Map<String, dynamic>.from(
        currentState.userDetails,
      );
      if (name != null) newUserDetails['name'] = name;

      if (avatarBytes != null) {
        // Direct bytes provided (usually for local update)
        newUserDetails['avatar_data'] = base64Encode(avatarBytes);
        // For local accounts, we don't have a URL, so we keep it null or existing
        if (isLocal) newUserDetails['avatar'] = null;
      } else if (avatarUrl != null) {
        // URL provided
        newUserDetails['avatar'] = avatarUrl;
        newUserDetails['avatar_data'] = await _cacheImageAsBase64(avatarUrl);
      }

      await HiveService.setUserDetails(newUserDetails);
      state = AuthLoggedIn(
        token: currentState.token,
        userDetails: newUserDetails,
      );
    } catch (e) {
      debugPrint("Auth: Profile update error: $e");
    }
  }
}