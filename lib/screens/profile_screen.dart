import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/song.dart';
import '../services/audio_service.dart';
import '../services/auth_service.dart';
import '../services/power_manager_service.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';
import 'history_screen.dart';
import '../theme/app_colors.dart';
import '../theme/theme_controller.dart';
import '../widgets/account_dialog.dart';
import '../widgets/avatar_halo.dart';
import '../widgets/motion.dart';
import '../widgets/spatial_background.dart';

/// Dedicated Spatial UI Profile screen inspired by the SoundWave reference.
/// Displays authentic user data, real listening activity statistics,
/// functional settings & preferences, and authenticated sign-out.
class ProfileScreen extends StatefulWidget {
  final AudioService audioService;
  final AuthService authService;
  final VoidCallback? onLocalTap;
  final ValueChanged<String>? onSearchTap;

  const ProfileScreen({
    super.key,
    required this.audioService,
    required this.authService,
    this.onLocalTap,
    this.onSearchTap,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with WidgetsBindingObserver {
  String _audioQuality = 'High';
  bool _offlineMode = false;
  bool _batteryOptimizationIgnored = true;
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPreferences();
    _checkBatteryStatus();
    _loadProfile();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkBatteryStatus();
    _loadProfile();
    }
  }

  Future<void> _checkBatteryStatus() async {
    final ignored = await PowerManagerService.instance.isIgnoringBatteryOptimizations();
    if (mounted) {
      setState(() => _batteryOptimizationIgnored = ignored);
    }
  }

  Future<void> _loadProfile() async {
    final user = widget.authService.currentUser;
    if (user != null) {
      final profile = await ProfileService.instance.fetchProfile(
        user.id,
        authUser: user,
      );
      if (mounted) {
        setState(() => _userProfile = profile);
      }
    } else {
      if (mounted) {
        setState(() => _userProfile = null);
      }
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _audioQuality = widget.audioService.audioQuality.isNotEmpty
            ? widget.audioService.audioQuality
            : (prefs.getString('pref_audio_quality') ?? 'High');
        _offlineMode = prefs.getBool('pref_offline_mode') ?? false;
      });
    }
  }

  Future<void> _setAudioQuality(String quality) async {
    await widget.audioService.setAudioQuality(quality);
    if (mounted) {
      setState(() => _audioQuality = quality);
    }
  }

  Future<void> _toggleOfflineMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pref_offline_mode', value);
    if (mounted) {
      setState(() => _offlineMode = value);
    }
  }

  Future<void> _handleBackgroundPowerUsage() async {
    if (!_batteryOptimizationIgnored) {
      await PowerManagerService.instance.requestIgnoreBatteryOptimizations();
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await _checkBatteryStatus();
    } else {
      _showBatteryDetailsDialog();
    }
  }

  void _showBatteryDetailsDialog() {
    final isDark = ThemeController.instance.isDark;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppDarkColors.backgroundSecondary : AppColors.backgroundSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.glassBorderOf(context)),
        ),
        title: Row(
          children: [
            const Icon(Icons.bolt_rounded, color: AppColors.softCyan, size: 24),
            const SizedBox(width: 8),
            Text(
              'Background Power Usage',
              style: TextStyle(
                color: isDark ? AppDarkColors.textPrimary : AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _batteryOptimizationIgnored
                  ? 'Harmoniq is granted Unrestricted background access. Music streaming will continue uninterrupted when your screen locks or when the app is minimized.'
                  : 'Android battery optimization (Doze mode) suspends background audio playback after 1-2 minutes of screen lock. Allowing Unrestricted Power Usage ensures smooth, nonstop playback.',
              style: TextStyle(
                color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _batteryOptimizationIgnored
                    ? AppColors.softCyan.withValues(alpha: 0.12)
                    : AppColors.coral.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _batteryOptimizationIgnored
                      ? AppColors.softCyan.withValues(alpha: 0.3)
                      : AppColors.coral.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _batteryOptimizationIgnored
                        ? Icons.check_circle_rounded
                        : Icons.warning_amber_rounded,
                    color: _batteryOptimizationIgnored
                        ? AppColors.softCyan
                        : AppColors.coral,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _batteryOptimizationIgnored
                          ? 'Status: Unrestricted (Background Playback Active)'
                          : 'Status: Restricted (Stops ~2 mins after screen lock)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _batteryOptimizationIgnored
                            ? AppColors.softCyan
                            : AppColors.coral,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Close',
              style: TextStyle(
                color: isDark ? AppDarkColors.textTertiary : AppColors.textTertiary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.softCyan,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              if (!_batteryOptimizationIgnored) {
                await PowerManagerService.instance.requestIgnoreBatteryOptimizations();
              } else {
                await PowerManagerService.instance.openBatteryOptimizationSettings();
              }
              await Future<void>.delayed(const Duration(milliseconds: 500));
              await _checkBatteryStatus();
            },
            child: Text(
              _batteryOptimizationIgnored ? 'System Settings' : 'Allow Unrestricted',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    final user = widget.authService.currentUser;
    if (user == null) {
      AccountDialog.show(
        context,
        authService: widget.authService,
        onAuthChanged: () {
          _loadProfile();
          if (mounted) setState(() {});
        },
      );
      return;
    }

    final isDark = ThemeController.instance.isDark;
    final currentProfile = ProfileService.instance.currentProfile ?? _userProfile;
    final nameCtrl = TextEditingController(text: currentProfile?.displayName ?? user.email?.split('@').first ?? '');
    final userCtrl = TextEditingController(text: currentProfile?.username ?? user.email?.split('@').first ?? '');
    final bioCtrl = TextEditingController(text: currentProfile?.bio ?? 'Music lover on Harmoniq');
    final genreCtrl = TextEditingController(text: currentProfile?.favoriteGenre ?? 'All Genres');
    bool saving = false;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final surface = isDark ? AppDarkColors.backgroundSecondary : AppColors.backgroundSecondary;
          final border = AppColors.glassBorderOf(dialogCtx);
          final textCol = isDark ? AppDarkColors.textPrimary : AppColors.textPrimary;
          final secText = isDark ? AppDarkColors.textSecondary : AppColors.textSecondary;

          return AlertDialog(
            backgroundColor: surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: border),
            ),
            title: Row(
              children: [
                const Icon(Icons.edit_note_rounded, color: AppColors.coral, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Edit Profile',
                  style: TextStyle(
                    color: textCol,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Update your Harmoniq identity and valid public profile.',
                    style: TextStyle(color: secText, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    style: TextStyle(color: textCol, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Display Name',
                      labelStyle: TextStyle(color: secText),
                      prefixIcon: const Icon(Icons.badge_rounded, color: AppColors.coral, size: 20),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.coral),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: userCtrl,
                    style: TextStyle(color: textCol, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Username Handle',
                      labelStyle: TextStyle(color: secText),
                      prefixIcon: const Icon(Icons.alternate_email_rounded, color: AppColors.coral, size: 20),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.coral),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bioCtrl,
                    maxLines: 2,
                    style: TextStyle(color: textCol, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Bio',
                      labelStyle: TextStyle(color: secText),
                      prefixIcon: const Icon(Icons.description_rounded, color: AppColors.coral, size: 20),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.coral),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: genreCtrl,
                    style: TextStyle(color: textCol, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Favorite Genre',
                      labelStyle: TextStyle(color: secText),
                      prefixIcon: const Icon(Icons.music_note_rounded, color: AppColors.coral, size: 20),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.coral),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(ctx),
                child: Text('Cancel', style: TextStyle(color: isDark ? AppDarkColors.textTertiary : AppColors.textTertiary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.coral,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: saving
                    ? null
                    : () async {
                        setDialogState(() => saving = true);
                        final updated = await ProfileService.instance.updateProfile(
                          userId: user.id,
                          displayName: nameCtrl.text.trim(),
                          username: userCtrl.text.trim(),
                          bio: bioCtrl.text.trim(),
                          favoriteGenre: genreCtrl.text.trim(),
                        );
                        if (mounted) {
                          setState(() => _userProfile = updated);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profile updated successfully!'),
                              backgroundColor: AppColors.accent,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                        if (ctx.mounted && Navigator.canPop(ctx)) Navigator.pop(ctx);
                      },
                child: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAudioQualityDialog() {
    final options = ['Standard', 'High', 'Very High (Lossless)'];
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.glassBorder),
        ),
        title: Text(
          'Streaming Quality',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((opt) {
            final targetQuality = opt.startsWith('Very High') ? 'Very High' : opt.split(' ').first;
            final isSelected = _audioQuality.toLowerCase().startsWith(targetQuality.toLowerCase());
            return ListTile(
              title: Text(
                opt,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.softCyan
                      : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
              trailing: isSelected
                  ? const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.softCyan,
                    )
                  : null,
              onTap: () {
                _setAudioQuality(targetQuality);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showThemeDialog() {
    final isDark = ThemeController.instance.isDark;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark
            ? AppDarkColors.backgroundSecondary
            : AppColors.backgroundSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark ? AppDarkColors.borderStandard : AppColors.glassBorder,
          ),
        ),
        title: Text(
          'App Theme',
          style: TextStyle(
            color: isDark ? AppDarkColors.textPrimary : AppColors.textPrimary,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  const Icon(Icons.light_mode_rounded, color: AppColors.coral),
              title: Text(
                'Light Theme',
                style: TextStyle(
                  color: ThemeController.instance.themeMode == ThemeMode.light
                      ? AppColors.coral
                      : (isDark
                          ? AppDarkColors.textPrimary
                          : AppColors.textPrimary),
                  fontWeight:
                      ThemeController.instance.themeMode == ThemeMode.light
                          ? FontWeight.w700
                          : FontWeight.w400,
                ),
              ),
              subtitle: Text(
                'Warm creamy soft canvas',
                style: TextStyle(
                  color: isDark
                      ? AppDarkColors.textSecondary
                      : AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              trailing: ThemeController.instance.themeMode == ThemeMode.light
                  ? const Icon(Icons.check_circle_rounded,
                      color: AppColors.coral)
                  : null,
              onTap: () {
                ThemeController.instance.setThemeMode(ThemeMode.light);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.dark_mode_rounded, color: AppColors.coral),
              title: Text(
                'Dark Theme',
                style: TextStyle(
                  color: ThemeController.instance.themeMode == ThemeMode.dark
                      ? AppColors.coral
                      : (isDark
                          ? AppDarkColors.textPrimary
                          : AppColors.textPrimary),
                  fontWeight:
                      ThemeController.instance.themeMode == ThemeMode.dark
                          ? FontWeight.w700
                          : FontWeight.w400,
                ),
              ),
              subtitle: Text(
                'Deep black canvas',
                style: TextStyle(
                  color: isDark
                      ? AppDarkColors.textSecondary
                      : AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              trailing: ThemeController.instance.themeMode == ThemeMode.dark
                  ? const Icon(Icons.check_circle_rounded,
                      color: AppColors.coral)
                  : null,
              onTap: () {
                ThemeController.instance.setThemeMode(ThemeMode.dark);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.brightness_auto_rounded,
                  color: AppColors.coral),
              title: Text(
                'System Default',
                style: TextStyle(
                  color: ThemeController.instance.themeMode == ThemeMode.system
                      ? AppColors.coral
                      : (isDark
                          ? AppDarkColors.textPrimary
                          : AppColors.textPrimary),
                  fontWeight:
                      ThemeController.instance.themeMode == ThemeMode.system
                          ? FontWeight.w700
                          : FontWeight.w400,
                ),
              ),
              subtitle: Text(
                'Matches your device theme',
                style: TextStyle(
                  color: isDark
                      ? AppDarkColors.textSecondary
                      : AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              trailing: ThemeController.instance.themeMode == ThemeMode.system
                  ? const Icon(Icons.check_circle_rounded,
                      color: AppColors.coral)
                  : null,
              onTap: () {
                ThemeController.instance.setThemeMode(ThemeMode.system);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyDialog() {
    final isDark = ThemeController.instance.isDark;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark
            ? AppDarkColors.cardSurface
            : AppColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark
                ? AppDarkColors.cardBorder
                : AppColors.cardBorder,
          ),
        ),
        title: Text(
          'Privacy & Security',
          style: TextStyle(
            color: isDark ? AppDarkColors.textPrimary : AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Your listening history and playlists are stored locally and synced only with your authenticated Supabase account. No third-party tracking is enabled.',
          style: TextStyle(
            color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
            fontSize: 13.5,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'OK',
              style: TextStyle(color: AppColors.coral, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final isDark = ThemeController.instance.isDark;
    if (!widget.authService.isAuthenticated) {
      AccountDialog.show(
        context,
        authService: widget.authService,
        onAuthChanged: () => setState(() {}),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark
            ? AppDarkColors.cardSurface
            : AppColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark
                ? AppDarkColors.cardBorder
                : AppColors.cardBorder,
          ),
        ),
        title: Text(
          'Log Out',
          style: TextStyle(
            color: isDark ? AppDarkColors.textPrimary : AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to log out of Harmoniq?',
          style: TextStyle(
            color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await widget.authService.signOut();
        if (mounted) setState(() {});
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Sign out notice: $e')));
        }
      }
    }
  }

  // Derive authentic top genres from real user activity
  String _calculateTopGenre(List<Song> songs) {
    if (songs.isEmpty) return 'Discovery';
    final genreCounts = <String, int>{};
    for (final song in songs) {
      final tag = song.album.isNotEmpty && song.album != 'YouTube'
          ? song.album
          : (song.source == SongSource.local ? 'Local Music' : 'Streaming');
      genreCounts[tag] = (genreCounts[tag] ?? 0) + 1;
    }
    final sorted = genreCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  // Derive unique artists from liked/played tracks
  List<String> _calculateTopArtists(List<Song> songs) {
    final seen = <String>{};
    final artists = <String>[];
    for (final song in songs) {
      if (song.artist.isNotEmpty && seen.add(song.artist)) {
        artists.add(song.artist);
        if (artists.length >= 3) break;
      }
    }
    return artists;
  }

  // Calculate total authentic listening time from recently played
  String _calculateListeningTime(List<Song> history) {
    if (history.isEmpty) return '0 hrs';
    final totalSeconds = history.fold<int>(
      0,
      (sum, s) => sum + s.duration.inSeconds,
    );
    final hours = (totalSeconds / 3600).toStringAsFixed(1);
    return '$hours hrs';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(
          [widget.authService, widget.audioService, ThemeController.instance, ProfileService.instance]),
      builder: (context, _) {
        final user = widget.authService.currentUser;
        final isAuthenticated = user != null;
        final profile = ProfileService.instance.currentProfile ?? _userProfile;
        final username = profile?.username ??
            user?.userMetadata?['username'] as String? ??
            (user?.email != null ? user!.email!.split('@').first : 'Guest User');
        final displayName = profile?.effectiveName ?? username;

        final favorites = widget.audioService.favorites;
        final playlists = widget.audioService.playlists;
        final history = widget.audioService.recentlyPlayed;

        final combinedActivity = [...history, ...favorites];
        final topGenre = _calculateTopGenre(combinedActivity);
        final topArtists = _calculateTopArtists(combinedActivity);
        final listeningTimeStr = _calculateListeningTime(history);
        final isDark = ThemeController.instance.isDark;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SpatialNebulaBackground(
            child: SafeArea(
              bottom: false,
              child: CustomScrollView(
                clipBehavior: Clip.none,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  // Top Header
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppDarkColors.cardSurface
                                  : AppColors.cardSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? AppDarkColors.cardBorder
                                    : AppColors.cardBorder,
                              ),
                            ),
                            child: Icon(
                              Icons.grid_view_rounded,
                              size: 18,
                              color: isDark
                                  ? AppDarkColors.textPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Harmoniq',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                                color: isDark
                                    ? AppDarkColors.textPrimary
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: isDark
                                ? 'Switch to Light Theme'
                                : 'Switch to Dark Theme',
                            onPressed: () =>
                                ThemeController.instance.toggleTheme(),
                            icon: Icon(
                              isDark
                                  ? Icons.light_mode_rounded
                                  : Icons.dark_mode_rounded,
                              size: 21,
                              color: isDark
                                  ? const Color(0xFFFFD13B)
                                  : AppColors.accentLight,
                            ),
                          ),
                          IconButton(
                            tooltip: isAuthenticated
                                ? 'Edit Profile'
                                : 'Sign In',
                            onPressed: () {
                              if (isAuthenticated) {
                                _showEditProfileDialog();
                              } else {
                                AccountDialog.show(
                                  context,
                                  authService: widget.authService,
                                  onAuthChanged: () {
                                    _loadProfile();
                                    if (mounted) setState(() {});
                                  },
                                );
                              }
                            },
                            icon: Icon(
                              isAuthenticated
                                  ? Icons.edit_outlined
                                  : Icons.login_rounded,
                              size: 21,
                              color: AppColors.accentLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Profile Avatar, Name, and Badges (Screenshot 1)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        children: [
                          // Profile avatar with restrained gradient halo
                          Center(
                            child: AvatarHalo(
                              size: 96,
                              borderWidth: 2.5,
                              child: Icon(
                                isAuthenticated
                                    ? Icons.person_rounded
                                    : Icons.person_outline_rounded,
                                size: 48,
                                color: isAuthenticated
                                    ? (isDark
                                        ? AppDarkColors.textPrimary
                                        : AppColors.textPrimary)
                                    : (isDark
                                        ? AppDarkColors.textSecondary
                                        : AppColors.textSecondary),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // User Name & Handle
                          Text(
                            displayName,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark
                                  ? AppDarkColors.textPrimary
                                  : AppColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.4,
                            ),
                          ),
                          if (isAuthenticated) ...[
                            const SizedBox(height: 2),
                            Text(
                              profile?.handle ?? '@',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isDark
                                    ? AppDarkColors.textSecondary
                                    : AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          if (profile?.bio != null && profile!.bio.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                profile.bio,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isDark
                                      ? AppDarkColors.textSecondary.withValues(alpha: 0.85)
                                      : AppColors.textSecondary.withValues(alpha: 0.85),
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),

                          // Membership status pill (consistent Harmoniq coral / theme pill)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppDarkColors.cardSurface
                                  : AppColors.cardSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isAuthenticated
                                    ? AppColors.coral.withValues(alpha: isDark ? 0.45 : 0.35)
                                    : (isDark
                                        ? AppDarkColors.cardBorder
                                        : AppColors.cardBorder),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isAuthenticated) ...[
                                  const Icon(
                                    Icons.verified_rounded,
                                    size: 15,
                                    color: AppColors.coral,
                                  ),
                                  const SizedBox(width: 5),
                                ],
                                Text(
                                  isAuthenticated
                                      ? 'Harmoniq Member'
                                      : 'Guest Mode',
                                  style: TextStyle(
                                    color: isAuthenticated
                                        ? AppColors.coral
                                        : (isDark
                                            ? AppDarkColors.textSecondary
                                            : AppColors.textSecondary),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Authentic Stats pill (calculated strictly from stored data)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppDarkColors.cardSurface
                                  : AppColors.cardSurface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? AppDarkColors.cardBorder
                                    : AppColors.cardBorder,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (isDark
                                          ? AppDarkColors.lightShadow
                                          : AppColors.lightShadow)
                                      .withValues(alpha: isDark ? 0.70 : 0.90),
                                  offset: const Offset(-2, -2),
                                  blurRadius: 6,
                                ),
                                BoxShadow(
                                  color: (isDark
                                          ? AppDarkColors.darkShadow
                                          : AppColors.darkShadow)
                                      .withValues(alpha: isDark ? 0.85 : 0.50),
                                  offset: const Offset(2, 2),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _statSegment(
                                    '${favorites.length}',
                                    'Liked',
                                    isDark,
                                  ),
                                ),
                                _statDivider(),
                                Expanded(
                                  child: _statSegment(
                                    '${playlists.length}',
                                    'Playlists',
                                    isDark,
                                  ),
                                ),
                                _statDivider(),
                                Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => HistoryScreen(
                                            audioService: widget.audioService,
                                            authService: widget.authService,
                                          ),
                                        ),
                                      );
                                    },
                                    child: _statSegment(
                                      '${history.length}',
                                      'History',
                                      isDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // My Activities Section (Screenshot 1)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        'My Activities',
                        style: TextStyle(
                          color: isDark
                              ? AppDarkColors.textPrimary
                              : AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final screenWidth = MediaQuery.sizeOf(context).width;
                        final isTablet = constraints.maxWidth >= 540;

                        final cardListening = _activityCard(
                          title: 'Listening Time',
                          content: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              SizedBox(
                                height: 34,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    _miniBar(14, AppColors.accentLight),
                                    _miniBar(22, AppColors.accent),
                                    _miniBar(10, AppColors.accentLight),
                                    _miniBar(28, AppColors.electricBlue),
                                    _miniBar(18, AppColors.accent),
                                    _miniBar(24, AppColors.accentLight),
                                    _miniBar(16, AppColors.electricBlue),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '$listeningTimeStr recently',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isDark
                                        ? AppDarkColors.textSecondary
                                        : AppColors.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );

                        final cardGenre = _activityCard(
                          title: 'Top Genre',
                          content: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              topGenre,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDark
                                    ? AppDarkColors.textPrimary
                                    : AppColors.textPrimary,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        );

                        final cardArtists = _activityCard(
                          title: 'Top Artists',
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 7),
                              if (topArtists.isNotEmpty)
                                Row(
                                  children: List.generate(
                                    topArtists.length,
                                    (i) => Padding(
                                      padding: EdgeInsets.only(
                                        left: i == 0 ? 0 : 6,
                                      ),
                                      child: Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.getGradientForIdTheme(
                                            i,
                                            isDark,
                                          )[0],
                                          border: Border.all(
                                            color: isDark
                                                ? AppDarkColors.cardBorder
                                                : AppColors.cardBorder,
                                            width: 1.5,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          topArtists[i].substring(0, 1),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Text(
                                  'Listen to discover',
                                  style: TextStyle(
                                    color: isDark
                                        ? AppDarkColors.textSecondary
                                        : AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              const SizedBox(height: 6),
                              Text(
                                topArtists.isNotEmpty
                                    ? topArtists.first
                                    : 'No artists yet',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isDark
                                      ? AppDarkColors.textPrimary
                                      : AppColors.textPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );

                        if (isTablet) {
                          final cardWidth = (constraints.maxWidth - 40 - 24) / 3;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: cardWidth,
                                  height: 124,
                                  child: cardListening,
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: cardWidth,
                                  height: 124,
                                  child: cardGenre,
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: cardWidth,
                                  height: 124,
                                  child: cardArtists,
                                ),
                              ],
                            ),
                          );
                        }

                        // Mobile viewport: intentional horizontal carousel
                        // Sizing proportioned so cards start flush within 20px padding and 3rd card peeks intentionally
                        final cardWidth = ((screenWidth - 40 - 12) / 2.18).clamp(142.0, 168.0);
                        return SizedBox(
                          height: 124,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            clipBehavior: Clip.none,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            children: [
                              SizedBox(width: cardWidth, child: cardListening),
                              const SizedBox(width: 12),
                              SizedBox(width: cardWidth, child: cardGenre),
                              const SizedBox(width: 12),
                              SizedBox(width: cardWidth, child: cardArtists),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Settings & Preferences Section (Screenshot 1)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        'Settings & Preferences',
                        style: TextStyle(
                          color: isDark
                              ? AppDarkColors.textPrimary
                              : AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppDarkColors.cardSurface
                              : AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? AppDarkColors.cardBorder
                                : AppColors.cardBorder,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isDark
                                      ? AppDarkColors.lightShadow
                                      : AppColors.lightShadow)
                                  .withValues(alpha: isDark ? 0.70 : 0.90),
                              offset: const Offset(-2, -2),
                              blurRadius: 6,
                            ),
                            BoxShadow(
                              color: (isDark
                                      ? AppDarkColors.darkShadow
                                      : AppColors.darkShadow)
                                  .withValues(alpha: isDark ? 0.85 : 0.50),
                              offset: const Offset(2, 2),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _settingsTile(
                              icon: Icons.account_circle_outlined,
                              title: 'Account Settings',
                              onTap: () {
                                AccountDialog.show(
                                  context,
                                  authService: widget.authService,
                                  onAuthChanged: () => setState(() {}),
                                );
                              },
                            ),
                            _settingsDivider(),
                            _settingsTile(
                              icon: ThemeController.instance.isDark
                                  ? Icons.dark_mode_rounded
                                  : Icons.light_mode_rounded,
                              title: 'Theme',
                              trailing: Text(
                                '${ThemeController.instance.themeModeName} >',
                                style: const TextStyle(
                                  color: AppColors.coral,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onTap: _showThemeDialog,
                            ),
                            _settingsDivider(),
                            _settingsTile(
                              icon: Icons.contrast_rounded,
                              title: 'Low Contrast Mode',
                              trailing: Switch(
                                value: ThemeController.instance.isLowContrast,
                                activeThumbColor: Colors.white,
                                activeTrackColor: AppColors.coral,
                                inactiveThumbColor: isDark
                                    ? AppDarkColors.textTertiary
                                    : AppColors.textTertiary,
                                inactiveTrackColor: isDark
                                    ? AppDarkColors.insetTrack
                                    : AppColors.insetTrack,
                                onChanged: (val) {
                                  ThemeController.instance.setLowContrast(val);
                                },
                              ),
                              onTap: () {
                                ThemeController.instance.setLowContrast(
                                  !ThemeController.instance.isLowContrast,
                                );
                              },
                            ),
                            _settingsDivider(),
                            _settingsTile(
                              icon: Icons.graphic_eq_rounded,
                              title: 'Audio Quality',
                              trailing: Text(
                                '$_audioQuality >',
                                style: const TextStyle(
                                  color: AppColors.coral,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onTap: _showAudioQualityDialog,
                            ),
                            _settingsDivider(),
                            _settingsTile(
                              icon: Icons.bolt_rounded,
                              title: 'Background Playback',
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _batteryOptimizationIgnored
                                      ? AppColors.softCyan.withValues(alpha: 0.12)
                                      : AppColors.coral.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _batteryOptimizationIgnored
                                      ? 'Unrestricted'
                                      : 'Restricted >',
                                  style: TextStyle(
                                    color: _batteryOptimizationIgnored
                                        ? AppColors.softCyan
                                        : AppColors.coral,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              onTap: _handleBackgroundPowerUsage,
                            ),
                            _settingsDivider(),
                            _settingsTile(
                              icon: Icons.cloud_download_outlined,
                              title: 'Offline Mode',
                              trailing: Switch(
                                value: _offlineMode,
                                activeThumbColor: Colors.white,
                                activeTrackColor: AppColors.coral,
                                inactiveThumbColor: isDark
                                    ? AppDarkColors.textTertiary
                                    : AppColors.textTertiary,
                                inactiveTrackColor: isDark
                                    ? AppDarkColors.insetTrack
                                    : AppColors.insetTrack,
                                onChanged: _toggleOfflineMode,
                              ),
                              onTap: () => _toggleOfflineMode(!_offlineMode),
                            ),
                            _settingsDivider(),
                            _settingsTile(
                              icon: Icons.history_rounded,
                              title: 'Song History',
                              trailing: Text(
                                '${history.length} tracks >',
                                style: TextStyle(
                                  color: isDark
                                      ? AppDarkColors.textSecondary
                                      : AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => HistoryScreen(
                                      audioService: widget.audioService,
                                      authService: widget.authService,
                                    ),
                                  ),
                                );
                              },
                            ),
                            _settingsDivider(),
                            _settingsTile(
                              icon: Icons.folder_open_rounded,
                              title: 'Local Device Storage',
                              trailing: Text(
                                '${widget.audioService.localSongs.length} tracks >',
                                style: TextStyle(
                                  color: isDark
                                      ? AppDarkColors.textSecondary
                                      : AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              onTap: widget.onLocalTap,
                            ),
                            _settingsDivider(),
                            _settingsTile(
                              icon: Icons.lock_outline_rounded,
                              title: 'Privacy & Security',
                              onTap: _showPrivacyDialog,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Log Out Button (Screenshot 1: red-tinted glass panel)
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      22,
                      20,
                      AppColors.bottomClearanceOf(context),
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Pressable(
                        onTap: _handleLogout,
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isAuthenticated
                                    ? Icons.logout_rounded
                                    : Icons.login_rounded,
                                color: isAuthenticated
                                    ? AppColors.error
                                    : AppColors.coral,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isAuthenticated
                                    ? 'Log Out'
                                    : 'Sign In / Register',
                                style: TextStyle(
                                  color: isAuthenticated
                                      ? AppColors.error
                                      : AppColors.coral,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _statSegment(String count, String label, [bool isDark = false]) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count,
          style: TextStyle(
            color: isDark ? AppDarkColors.textPrimary : AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _statDivider() {
    final isDark = ThemeController.instance.isDark;
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: isDark ? AppDarkColors.divider : AppColors.cardBorder,
    );
  }

  Widget _activityCard({
    required String title,
    required Widget content,
    double? width,
  }) {
    final isDark = ThemeController.instance.isDark;
    final shadowLight =
        isDark ? AppDarkColors.lightShadow : AppColors.lightShadow;
    final shadowDark =
        isDark ? AppDarkColors.darkShadow : AppColors.darkShadow;
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppDarkColors.cardSurface
            : AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppDarkColors.cardBorder
              : AppColors.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: shadowLight.withValues(alpha: isDark ? 0.70 : 0.85),
            offset: const Offset(-2, -2),
            blurRadius: 5,
          ),
          BoxShadow(
            color: shadowDark.withValues(alpha: isDark ? 0.85 : 0.45),
            offset: const Offset(2, 2),
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: content,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniBar(double height, Color color) {
    return Container(
      width: 3.5,
      height: height,
      margin: const EdgeInsets.only(right: 3.5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
    bool? isDark,
  }) {
    final dark = isDark ?? ThemeController.instance.isDark;
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Icon(
          icon,
          color: dark ? AppDarkColors.textSecondary : AppColors.textSecondary,
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: dark ? AppDarkColors.textPrimary : AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: trailing ??
            Icon(
              Icons.chevron_right_rounded,
              color: dark ? AppDarkColors.textSecondary : AppColors.textSecondary,
              size: 20,
            ),
      ),
    );
  }

  Widget _settingsDivider() {
    final isDark = ThemeController.instance.isDark;
    return Divider(
      color: isDark ? AppDarkColors.cardBorder : AppColors.cardBorder,
      height: 1,
      indent: 16,
      endIndent: 16,
    );
  }
}
