import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase/supabase_config.dart';

/// Service responsible for managing user authentication with Supabase Auth.
/// Designed to fail safely without crashing if Supabase client is unavailable.
class AuthService extends ChangeNotifier {
  final SupabaseClient? _client;
  User? _currentUser;
  Session? _currentSession;
  StreamSubscription<AuthState>? _authSubscription;

  AuthService({SupabaseClient? client}) : _client = client ?? _resolveClient() {
    final c = _client;
    if (c != null) {
      try {
        _currentUser = c.auth.currentUser;
        _currentSession = c.auth.currentSession;

        _authSubscription = c.auth.onAuthStateChange.listen((data) {
          _currentUser = data.session?.user;
          _currentSession = data.session;
          notifyListeners();
        });
      } catch (e) {
        debugPrint('[AUTH] Supabase session listener notice: $e');
      }
    }
  }

  static SupabaseClient? _resolveClient() {
    try {
      return SupabaseConfig.client;
    } catch (e) {
      debugPrint('[AUTH] Supabase client unavailable: $e');
      return null;
    }
  }

  /// Whether Supabase client is configured and available
  bool get isClientAvailable => _client != null;

  /// Get currently authenticated Supabase user
  User? get currentUser => _currentUser ?? _client?.auth.currentUser;

  /// Get active Supabase session
  Session? get currentSession => _currentSession ?? _client?.auth.currentSession;

  /// Convenience getter for auth state status
  bool get isAuthenticated => currentUser != null;

  /// Stream of Supabase Auth state changes
  Stream<AuthState> get authStateChanges =>
      _client?.auth.onAuthStateChange ?? const Stream<AuthState>.empty();

  /// Register a new user with email, password, and optional username
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? username,
  }) async {
    final client = _client;
    if (client == null) {
      throw Exception('Authentication service is currently offline. Please check your internet connection.');
    }

    try {
      final response = await client.auth.signUp(
        email: email.trim(),
        password: password,
        data: username != null && username.trim().isNotEmpty
            ? {
                'username': username.trim(),
                'display_name': username.trim(),
              }
            : null,
      );
      return response;
    } on AuthException catch (e) {
      throw _formatAuthException(e);
    } catch (e) {
      throw Exception('Sign up failed: ${e.toString()}');
    }
  }

  /// Authenticate user with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final client = _client;
    if (client == null) {
      throw Exception('Authentication service is currently offline. Please check your internet connection.');
    }

    try {
      final response = await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      throw _formatAuthException(e);
    } catch (e) {
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  /// Terminate active session and sign out user
  Future<void> signOut() async {
    final client = _client;
    if (client == null) return;

    try {
      await client.auth.signOut();
      _currentUser = null;
      _currentSession = null;
      notifyListeners();
    } on AuthException catch (e) {
      throw _formatAuthException(e);
    } catch (e) {
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  /// Translates raw Supabase AuthExceptions into user-friendly error messages
  String _formatAuthException(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid_credentials')) {
      return 'Invalid email or password. Please try again.';
    } else if (msg.contains('user already registered') ||
        msg.contains('already exists')) {
      return 'An account with this email address already exists.';
    } else if (msg.contains('password should be at least')) {
      return 'Password must be at least 6 characters long.';
    } else if (msg.contains('unable to validate email')) {
      return 'Please enter a valid email address.';
    } else if (msg.contains('email not confirmed')) {
      return 'Please check your inbox and confirm your email address.';
    }
    return e.message;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
