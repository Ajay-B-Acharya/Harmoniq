import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase/supabase_config.dart';

/// Legacy/convenience wrapper for Supabase initialization and access.
Future<void> initSupabase() async {
  await SupabaseConfig.initialize();
}

/// Helper shortcut to access the global Supabase client instance.
SupabaseClient get supabase => SupabaseConfig.client;
