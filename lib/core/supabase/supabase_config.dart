// ignore_for_file: deprecated_member_use

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

  /// The publishable/anon key — safe for client-side code.
  /// Never use the service-role/secret key here.
  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_MF3-7PiHvo9XEmXqtg_FJA_Pl1yrYpS',
  );

  /// Initializes the Supabase client instance safely.
  /// Call this once in `main()` before `runApp()`.
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: url,
        anonKey: publishableKey,
      );
    } catch (e) {
      // Re-throw or handle so callers can catch and handle gracefully
      rethrow;
    }
  }

  /// Global accessor for SupabaseClient instance.
  static SupabaseClient get client => Supabase.instance.client;
}
