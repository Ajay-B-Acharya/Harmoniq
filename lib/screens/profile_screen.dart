import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/song.dart';
import '../services/audio_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/account_dialog.dart';
import '../widgets/harmoniq_emblem.dart';
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

class _ProfileScreenState extends State<ProfileScreen> {
  String _audioQuality = 'High';
  bool _offlineMode = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _audioQuality = prefs.getString('pref_audio_quality') ?? 'High';
        _offlineMode = prefs.getBool('pref_offline_mode') ?? false;
      });
    }
  }

  Future<void> _setAudioQuality(String quality) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pref_audio_quality', quality);
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

  void _showAudioQualityDialog() {
    final options = ['Standard', 'High', 'Very High (Lossless)'];
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
        title: const Text(
          'Streaming Quality',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((opt) {
            final isSelected = _audioQuality.startsWith(opt.split(' ').first);
            return ListTile(
              title: Text(
                opt,
                style: TextStyle(
                  color: isSelected ? AppColors.softCyan : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check_circle_rounded, color: AppColors.softCyan)
                  : null,
              onTap: () {
                _setAudioQuality(opt.split(' ').first);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
        title: const Text(
          'Privacy & Security',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
        ),
        content: const Text(
          'Your listening history and playlists are stored locally and synced only with your authenticated Supabase account. No third-party tracking is enabled.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: AppColors.primaryViolet)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
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
        backgroundColor: AppColors.backgroundSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
        title: const Text(
          'Log Out',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
        ),
        content: const Text(
          'Are you sure you want to log out of Harmoniq?',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sign out notice: $e')),
          );
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
      listenable: Listenable.merge([widget.authService, widget.audioService]),
      builder: (context, _) {
        final user = widget.authService.currentUser;
        final isAuthenticated = user != null;
        final username = user?.userMetadata?['username'] as String? ??
            user?.userMetadata?['display_name'] as String? ??
            (user?.email != null ? user!.email!.split('@').first : 'Guest User');

        final favorites = widget.audioService.favorites;
        final playlists = widget.audioService.playlists;
        final history = widget.audioService.recentlyPlayed;

        final combinedActivity = [...history, ...favorites];
        final topGenre = _calculateTopGenre(combinedActivity);
        final topArtists = _calculateTopArtists(combinedActivity);
        final listeningTimeStr = _calculateListeningTime(history);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SpatialBackground(
            child: SafeArea(
              bottom: false,
              child: CustomScrollView(
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
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.glassBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.glassBorder),
                            ),
                            child: const Icon(
                              Icons.grid_view_rounded,
                              size: 19,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryViolet.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: const HarmoniqEmblem(size: 20),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Harmoniq',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Notifications',
                            onPressed: () {},
                            icon: const Icon(
                              Icons.notifications_none_rounded,
                              size: 22,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          IconButton(
                            tooltip: isAuthenticated ? 'Edit Account' : 'Sign In',
                            onPressed: () {
                              AccountDialog.show(
                                context,
                                authService: widget.authService,
                                onAuthChanged: () => setState(() {}),
                              );
                            },
                            icon: Icon(
                              isAuthenticated
                                  ? Icons.edit_outlined
                                  : Icons.login_rounded,
                              size: 21,
                              color: AppColors.softCyan,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Profile Avatar, Name, and Badges (Screenshot 1)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        children: [
                          // Glowing circular avatar ring (cyan to violet)
                          Center(
                            child: Container(
                              width: 104,
                              height: 104,
                              padding: const EdgeInsets.all(3.5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.softCyan,
                                    AppColors.primaryViolet,
                                    AppColors.secondaryPurple,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryViolet.withValues(alpha: 0.35),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.backgroundSecondary,
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  isAuthenticated
                                      ? Icons.person_rounded
                                      : Icons.person_outline_rounded,
                                  size: 48,
                                  color: isAuthenticated
                                      ? AppColors.softCyan
                                      : AppColors.textMuted,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // User Name
                          Text(
                            username,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Membership status pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primaryViolet.withValues(alpha: 0.35),
                                  AppColors.electricBlue.withValues(alpha: 0.20),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.primaryViolet.withValues(alpha: 0.6),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              isAuthenticated ? 'Harmoniq Member' : 'Guest Mode',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Authentic Stats pill (calculated strictly from stored data)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.glassBackground,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppColors.glassBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _statSegment('${favorites.length}', 'Liked'),
                                _statDivider(),
                                _statSegment('${playlists.length}', 'Playlists'),
                                _statDivider(),
                                _statSegment('${history.length}', 'History'),
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
                      child: const Text(
                        'My Activities',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 120,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          // Card 1: Listening Time
                          _activityCard(
                            title: 'Listening Time',
                            content: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _miniBar(14, AppColors.softCyan),
                                    _miniBar(22, AppColors.primaryViolet),
                                    _miniBar(10, AppColors.softCyan),
                                    _miniBar(28, AppColors.electricBlue),
                                    _miniBar(18, AppColors.primaryViolet),
                                    _miniBar(24, AppColors.softCyan),
                                    _miniBar(16, AppColors.electricBlue),
                                  ],
                                ),
                                const Spacer(),
                                Text(
                                  '$listeningTimeStr recently',
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Card 2: Top Genre
                          _activityCard(
                            title: 'Top Genre',
                            content: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Spacer(),
                                Text(
                                  topGenre,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Spacer(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Card 3: My Favorite Artists
                          _activityCard(
                            title: 'Top Artists',
                            content: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 10),
                                if (topArtists.isNotEmpty)
                                  Row(
                                    children: List.generate(
                                      topArtists.length,
                                      (i) => Container(
                                        width: 32,
                                        height: 32,
                                        margin: EdgeInsets.only(
                                          left: i == 0 ? 0 : -8,
                                        ),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.getGradientForId(i)[0],
                                          border: Border.all(
                                            color: AppColors.backgroundSecondary,
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
                                  )
                                else
                                  const Text(
                                    'Listen to discover',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                const Spacer(),
                                Text(
                                  topArtists.isNotEmpty
                                      ? topArtists.first
                                      : 'No artists yet',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Settings & Preferences Section (Screenshot 1)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
                    sliver: SliverToBoxAdapter(
                      child: const Text(
                        'Settings & Preferences',
                        style: TextStyle(
                          color: AppColors.textPrimary,
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
                          color: AppColors.glassBackground,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppColors.glassBorder),
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
                              icon: Icons.graphic_eq_rounded,
                              title: 'Audio Quality',
                              trailing: Text(
                                '$_audioQuality >',
                                style: const TextStyle(
                                  color: AppColors.softCyan,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onTap: _showAudioQualityDialog,
                            ),
                            _settingsDivider(),
                            _settingsTile(
                              icon: Icons.cloud_download_outlined,
                              title: 'Offline Mode',
                              trailing: Switch(
                                value: _offlineMode,
                                activeThumbColor: AppColors.primaryViolet,
                                activeTrackColor: AppColors.primaryViolet.withValues(alpha: 0.35),
                                inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
                                onChanged: _toggleOfflineMode,
                              ),
                              onTap: () => _toggleOfflineMode(!_offlineMode),
                            ),
                            _settingsDivider(),
                            _settingsTile(
                              icon: Icons.folder_open_rounded,
                              title: 'Local Device Storage',
                              trailing: Text(
                                '${widget.audioService.localSongs.length} tracks >',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
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
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 96),
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
                                    : AppColors.softCyan,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isAuthenticated ? 'Log Out' : 'Sign In / Register',
                                style: TextStyle(
                                  color: isAuthenticated
                                      ? AppColors.error
                                      : AppColors.softCyan,
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

  Widget _statSegment(String count, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: AppColors.glassBorder,
    );
  }

  Widget _activityCard({required String title, required Widget content}) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.glassBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(child: content),
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
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Icon(icon, color: AppColors.textSecondary, size: 22),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: trailing ??
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
      ),
    );
  }

  Widget _settingsDivider() {
    return const Divider(
      color: AppColors.glassBorder,
      height: 1,
      indent: 16,
      endIndent: 16,
    );
  }
}
