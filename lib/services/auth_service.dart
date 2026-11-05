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
  bool _isOAuthInProgress = false;
  String? _authError;

  AuthService({SupabaseClient? client}) : _client = client ?? _resolveClient() {
    final c = _client;
    if (c != null) {
      try {
        _currentUser = c.auth.currentUser;
        _currentSession = c.auth.currentSession;

        _authSubscription = c.auth.onAuthStateChange.listen(
          (data) {
            _currentUser = data.session?.user;
            _currentSession = data.session;
            if (data.session != null) {
              _isOAuthInProgress = false;
              _authError = null;
            }
            notifyListeners();
          },
          onError: (error) {
            _isOAuthInProgress = false;
            final exception = error is AuthException
                ? error
                : AuthException(error.toString());

            // If a session is already present, flow_state_already_used is a harmless duplicate
            if (_currentUser == null && _currentSession == null) {
              _authError = _formatAuthException(exception);
            }
            notifyListeners();
          },
        );
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

  /// Whether an OAuth flow is currently in progress
  bool get isOAuthInProgress => _isOAuthInProgress;

  /// Latest authentication error message, if any
  String? get authError => _authError;

  /// Reset in-flight OAuth flow state (e.g. after cancellation or user retry)
  void resetOAuthFlow() {
    if (_isOAuthInProgress || _authError != null) {
      _isOAuthInProgress = false;
      _authError = null;
      notifyListeners();
    }
  }

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
      final sanitizedEmail = email.trim();
      final effectiveUsername = (username != null && username.trim().isNotEmpty)
          ? username.trim()
          : '${sanitizedEmail.split('@').first.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '')}_${DateTime.now().millisecondsSinceEpoch % 10000}';

      final response = await client.auth.signUp(
        email: sanitizedEmail,
        password: password,
        data: {
          'username': effectiveUsername,
          'display_name': effectiveUsername,
        },
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

  /// Authenticate user via Google OAuth using Supabase Auth.
  Future<bool> signInWithGoogle({String? redirectTo}) async {
    final client = _client;
    if (client == null) {
      throw Exception(
        'Authentication service is currently offline. Please check your internet connection.',
      );
    }

    if (_isOAuthInProgress) {
      debugPrint('[AUTH] Google OAuth flow already in progress. Ignoring duplicate start request.');
      return false;
    }

    _isOAuthInProgress = true;
    _authError = null;
    SupabaseConfig.clearProcessedAuthCodes();
    notifyListeners();

    try {
      final redirect = redirectTo ?? SupabaseConfig.resolvedAuthCallbackUrl;
      final launched = await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirect,
      );
      if (!launched) {
        _isOAuthInProgress = false;
        notifyListeners();
      }
      return launched;
    } on AuthException catch (e) {
      _isOAuthInProgress = false;
      _authError = _formatAuthException(e);
      notifyListeners();
      throw _formatAuthException(e);
    } catch (e) {
      _isOAuthInProgress = false;
      _authError = 'Google sign in failed: ${e.toString()}';
      notifyListeners();
      throw Exception('Google sign in failed: ${e.toString()}');
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
      _isOAuthInProgress = false;
      _authError = null;
      SupabaseConfig.clearProcessedAuthCodes();
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
    final code = e.code?.toLowerCase() ?? '';
    final statusCode = e.statusCode?.toLowerCase() ?? '';

    if (code.contains('flow_state_already_used') ||
        statusCode.contains('flow_state_already_used') ||
        msg.contains('state has already been used') ||
        msg.contains('flow_state_already_used')) {
      return 'The sign-in session expired or was already used. Please try signing in again.';
    } else if (msg.contains('flow_state_not_found') ||
        code.contains('flow_state_not_found') ||
        statusCode.contains('flow_state_not_found')) {
      return 'Sign-in session not found. Please start a new sign-in.';
    } else if (code.contains('invalid_grant') ||
        statusCode.contains('invalid_grant') ||
        msg.contains('invalid_grant')) {
      return 'Sign-in authorization expired. Please try signing in again.';
    } else if (code.contains('access_denied') ||
        statusCode.contains('access_denied') ||
        msg.contains('access_denied') ||
        msg.contains('canceled') ||
        msg.contains('cancelled') ||
        msg.contains('user_cancelled')) {
      return 'Google sign-in was canceled.';
    } else if (msg.contains('invalid login credentials') ||
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
