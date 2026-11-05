// ignore_for_file: deprecated_member_use

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Configuration manager for Supabase connection parameters.
///
/// Uses environment variables via `--dart-define` if provided, falling back to
/// the configured Harmoniq Supabase credentials.
class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://plgjdahnooizyevaxhsh.supabase.co',
  );

  /// The standard JWT anon key — safe for client-side code and required by PostgREST/Auth.
  /// Never use the service_role key in client code.
  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBsZ2pkYWhub29penlldmF4aHNoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE0NjEyNjksImV4cCI6MjEwNzAzNzI2OX0.Rf2BOpN3Sjr-zCQSzKkZFSF9qbaqmDs1h1-WlAaCBR8',
  );

  /// Redirect URI used by Supabase Auth OAuth flow.
  /// Matches the custom deep link scheme configured in AndroidManifest.xml
  /// and allowed redirect URLs in the Supabase Dashboard.
  static const String authCallbackUrl = String.fromEnvironment(
    'SUPABASE_AUTH_REDIRECT_URL',
    defaultValue: 'com.example.rachan://login-callback',
  );

  /// Resolves the appropriate redirect URL based on current environment and platform.
  /// - If explicitly defined via SUPABASE_AUTH_REDIRECT_URL, uses that.
  /// - For Web (kIsWeb), resolves dynamically to Uri.base.origin.
  /// - For Mobile/Native, defaults to authCallbackUrl ('com.example.rachan://login-callback').
  static String get resolvedAuthCallbackUrl {
    const fromEnv = String.fromEnvironment('SUPABASE_AUTH_REDIRECT_URL');
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }
    if (kIsWeb) {
      return Uri.base.origin;
    }
    return authCallbackUrl;
  }

  // Track processed authorization codes and error signatures to ensure each OAuth PKCE code is processed exactly once
  static final Set<String> _processedAuthCodes = <String>{};
  static final Set<String> _processedErrorSignatures = <String>{};

  /// Predicate that detects auth callback deep links and filters out duplicate codes.
  /// Prevents `flow_state_already_used` errors caused by double execution or multiple stream events.
  static bool isAuthCallbackDeeplink(Uri uri) {
    final fragmentParameters = Uri.splitQueryString(uri.fragment);
    final queryParameters = uri.queryParameters;

    final code = queryParameters['code'] ?? fragmentParameters['code'];
    if (code != null) {
      if (_processedAuthCodes.contains(code)) {
        // Prevent duplicate PKCE code exchange
        return false;
      }
      _processedAuthCodes.add(code);
      if (_processedAuthCodes.length > 50) {
        _processedAuthCodes.remove(_processedAuthCodes.first);
      }
    }

    final errorCode = queryParameters['error_code'] ??
        fragmentParameters['error_code'] ??
        queryParameters['error'] ??
        fragmentParameters['error'];
    if (errorCode != null) {
      final sig = '${uri.scheme}://${uri.host}${uri.path}?${uri.query}#${uri.fragment}';
      if (_processedErrorSignatures.contains(sig)) {
        return false;
      }
      _processedErrorSignatures.add(sig);
      if (_processedErrorSignatures.length > 50) {
        _processedErrorSignatures.remove(_processedErrorSignatures.first);
      }
    }

    bool hasParameter(String key) =>
        queryParameters.containsKey(key) ||
        fragmentParameters.containsKey(key);

    return hasParameter('access_token') ||
        hasParameter('code') ||
        hasParameter('error') ||
        hasParameter('error_code') ||
        hasParameter('error_description');
  }

  /// Clear the cache of processed codes (useful in tests or fresh sign-in attempts)
  static void clearProcessedAuthCodes() {
    _processedAuthCodes.clear();
    _processedErrorSignatures.clear();
  }

  /// Initializes the Supabase client instance safely.
  /// Call this once in `main()` before `runApp()`.
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: url,
        anonKey: publishableKey,
        authOptions: const FlutterAuthClientOptions(
          detectSessionInUriPredicate: isAuthCallbackDeeplink,
        ),
      );
    } catch (e) {
      // Re-throw or handle so callers can catch and handle gracefully
      rethrow;
    }
  }

  /// Global accessor for SupabaseClient instance.
  static SupabaseClient get client => Supabase.instance.client;
}
