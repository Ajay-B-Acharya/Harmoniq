import 'dart:ui';

import 'package:flutter/material.dart';

import '../screens/login_screen.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';

/// Account modal bottom sheet / dialog displaying current Supabase auth status.
class AccountDialog extends StatelessWidget {
  final AuthService authService;
  final VoidCallback? onAuthChanged;

  const AccountDialog({
    super.key,
    required this.authService,
    this.onAuthChanged,
  });

  static void show(
    BuildContext context, {
    required AuthService authService,
    VoidCallback? onAuthChanged,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.sheetSurface,
              border: Border(top: BorderSide(color: AppColors.borderElevated)),
            ),
            child: AccountDialog(
              authService: authService,
              onAuthChanged: onAuthChanged,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;
    final isAuthenticated = user != null;
    final username =
        user?.userMetadata?['username'] as String? ??
        user?.userMetadata?['display_name'] as String? ??
        (user?.email != null ? user!.email!.split('@').first : 'Music Lover');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppDarkColors.textPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppDarkColors.textSecondary : AppColors.textSecondary;
    final textMuted = isDark ? AppDarkColors.textMuted : AppColors.textMuted;
    final surfaceBorder = isDark ? AppDarkColors.borderStandard : AppColors.surfaceBorder;
    final surfaceHigh = isDark ? AppDarkColors.surfaceHigh : AppColors.surfaceHigh;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        // FIX: was CrossAlignment.stretch (invalid class)
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: surfaceBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isAuthenticated
                      ? AppColors.accent.withValues(alpha: 0.15)
                      : surfaceHigh,
                  border: Border.all(
                    color: isAuthenticated
                        ? AppColors.accent.withValues(alpha: 0.5)
                        : surfaceBorder,
                  ),
                ),
                child: Icon(
                  isAuthenticated
                      ? Icons.person_rounded
                      : Icons.person_outline_rounded,
                  color: isAuthenticated
                      ? AppColors.accent
                      : textSecondary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  // FIX: was CrossAlignment.start (invalid class)
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAuthenticated ? username : 'Guest User',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAuthenticated
                          ? (user.email ?? 'Authenticated')
                          : 'Not signed in',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isAuthenticated
                      ? AppColors.accent.withValues(alpha: 0.15)
                      : surfaceHigh,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isAuthenticated ? 'Supabase' : 'Guest',
                  style: TextStyle(
                    color: isAuthenticated
                        ? AppColors.accent
                        : textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Divider(color: surfaceBorder, height: 1),
          const SizedBox(height: 20),

          if (isAuthenticated) ...[
            Text(
              'Your Harmoniq account is connected to Supabase Auth.',
              style: TextStyle(
                color: textSecondary.withValues(alpha: 0.9),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 46,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: AppColors.accentDark),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  await authService.signOut();
                  onAuthChanged?.call();
                },
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text(
                  'Sign Out',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ] else ...[
            Text(
              'Sign in with Supabase to sync your playlists, favorites, and listening history across devices.',
              style: TextStyle(
                color: textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 46,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => LoginScreen(
                        authService: authService,
                        onLoginSuccess: () {
                          onAuthChanged?.call();
                        },
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.login_rounded, size: 18),
                label: const Text('Sign In or Register'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
