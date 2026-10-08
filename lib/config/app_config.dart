import 'youtube_config.dart';
import '../core/supabase/supabase_config.dart';

/// Centralized application configuration for Harmoniq.
/// Keeps all external endpoints, timeouts, and API hosts in one location.
abstract final class AppConfig {
  static const String appName = 'Harmoniq';
  static const String appVersion = '1.0.0';

  // ── Network Timeouts ────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration requestTimeout = Duration(seconds: 20);

  // ── Supabase Configuration ──────────────────────────────────────────────────
  static String get supabaseUrl => SupabaseConfig.url;
  static String get supabasePublishableKey => SupabaseConfig.publishableKey;

  // ── YouTube Public Data API ─────────────────────────────────────────────────
  static String get youtubeApiHost => YoutubeConfig.apiHost;
  static String get youtubeApiPath => YoutubeConfig.apiPath;
  static String get youtubeApiKey => YoutubeConfig.apiKey;
  static const String youtubeWatchBase = 'https://www.youtube.com/watch?v=';

  // ── Network Security & Offline Fallbacks ───────────────────────────────────
  static const bool allowSimulatedAudio = true;
  static const int maxSearchLength = 200;
  static const int maxRecentSearches = 20;
}
