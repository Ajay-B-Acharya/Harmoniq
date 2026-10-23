import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase/supabase_config.dart';
import '../models/user_profile.dart';

/// Service responsible for managing Supabase user profile data.
/// Provides safe offline fallbacks and caches profile attributes locally.
class ProfileService extends ChangeNotifier {
  ProfileService._();
  static final ProfileService instance = ProfileService._();

  SupabaseClient? _client;
  SupabaseClient? get client {
    if (_client != null) return _client;
    try {
      return SupabaseConfig.client;
    } catch (_) {
      return null;
    }
  }

  @visibleForTesting
  void setClient(SupabaseClient? c) {
    _client = c;
  }

  UserProfile? _currentProfile;
  UserProfile? get currentProfile => _currentProfile;

  /// Fetches the profile for the given [userId], creating one if missing.
  Future<UserProfile?> fetchProfile(String userId, {User? authUser}) async {
    final c = client;

    // First try loading cached profile from SharedPreferences
    await _loadCachedProfile(userId);

    if (c == null) {
      return _currentProfile;
    }

    try {
      final res = await c
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (res != null) {
        _currentProfile = UserProfile.fromJson(res);
        await _saveCachedProfile(_currentProfile!);
        notifyListeners();
        return _currentProfile;
      }

      // If no profile row exists, provision one automatically from auth metadata
      final metadata = authUser?.userMetadata ?? c.auth.currentUser?.userMetadata;
      final email = authUser?.email ?? c.auth.currentUser?.email;
      final fallbackUsername = metadata?['username'] as String? ??
          (email != null ? email.split('@').first : 'user');
      final fallbackDisplay = metadata?['display_name'] as String? ?? fallbackUsername;

      final initialProfile = UserProfile(
        id: userId,
        username: fallbackUsername,
        displayName: fallbackDisplay,
        avatarUrl: metadata?['avatar_url'] as String?,
      );

      final insertRes = await c
          .from('profiles')
          .upsert(initialProfile.toJson())
          .select()
          .single();

      _currentProfile = UserProfile.fromJson(insertRes);
      await _saveCachedProfile(_currentProfile!);
      notifyListeners();
      return _currentProfile;
    } catch (e) {
      debugPrint('[PROFILE_SERVICE] Error fetching profile: $e');
      return _currentProfile;
    }
  }

  /// Updates the profile fields in Supabase and syncs auth user metadata.
  Future<UserProfile?> updateProfile({
    required String userId,
    String? displayName,
    String? username,
    String? bio,
    String? avatarUrl,
    String? favoriteGenre,
  }) async {
    final c = client;

    // Apply updates locally first for instant optimistic response
    final existing = _currentProfile ??
        UserProfile(
          id: userId,
          username: username ?? 'user',
          displayName: displayName ?? 'User',
        );

    final updated = existing.copyWith(
      displayName: displayName,
      username: username,
      bio: bio,
      avatarUrl: avatarUrl,
      favoriteGenre: favoriteGenre,
      updatedAt: DateTime.now().toUtc(),
    );

    _currentProfile = updated;
    await _saveCachedProfile(updated);
    notifyListeners();

    if (c == null) return updated;

    try {
      final payload = <String, dynamic>{
        if (displayName != null) 'display_name': displayName.trim(),
        if (username != null) 'username': username.trim().replaceAll('@', ''),
        if (bio != null) 'bio': bio.trim(),
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (favoriteGenre != null) 'favorite_genre': favoriteGenre,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      await c.from('profiles').update(payload).eq('id', userId);

      // Keep Auth metadata in sync
      if (displayName != null || username != null) {
        await c.auth.updateUser(
          UserAttributes(
            data: {
              if (displayName != null) 'display_name': displayName.trim(),
              if (username != null) 'username': username.trim().replaceAll('@', ''),
            },
          ),
        );
      }

      return _currentProfile;
    } catch (e) {
      debugPrint('[PROFILE_SERVICE] Error updating profile in Supabase: $e');
      return _currentProfile;
    }
  }

  /// Increments listening time for the user profile
  Future<void> addListeningSeconds(String userId, int seconds) async {
    if (seconds <= 0) return;
    if (_currentProfile != null && _currentProfile!.id == userId) {
      _currentProfile = _currentProfile!.copyWith(
        totalListeningSeconds: _currentProfile!.totalListeningSeconds + seconds,
      );
      await _saveCachedProfile(_currentProfile!);
      notifyListeners();
    }

    final c = client;
    if (c == null) return;
    try {
      await c.rpc('increment_listening_time', params: {
        'user_id_param': userId,
        'seconds_param': seconds,
      });
    } catch (_) {}
  }

  void clearProfile() {
    _currentProfile = null;
    notifyListeners();
  }

  Future<void> _saveCachedProfile(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'harmoniq_cached_profile_${profile.id}',
        json.encode(profile.toJson()),
      );
    } catch (_) {}
  }

  Future<void> _loadCachedProfile(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('harmoniq_cached_profile_$userId');
      if (str != null) {
        final decoded = json.decode(str) as Map<String, dynamic>;
        _currentProfile = UserProfile.fromJson(decoded);
        notifyListeners();
      }
    } catch (_) {}
  }
}
