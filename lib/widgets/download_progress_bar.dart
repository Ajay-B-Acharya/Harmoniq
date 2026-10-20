import 'dart:async';

import 'package:flutter/material.dart';

import '../services/download_service.dart';
import '../theme/app_colors.dart';
import 'album_art.dart';
import 'glass_card.dart';
import 'motion.dart';

/// A floating real-time download progress bar displayed right above the mini-player.
///
/// Features:
/// - Real-time percent progress & byte counter (MB transferred / Total MB)
/// - Harmoniq gradient animated progress line
/// - Format badge (e.g. MP3 · 320 kbps)
/// - In-flight cancel button
/// - Smooth animated completion/failure banners with auto-dismiss
class DownloadProgressBar extends StatefulWidget {
  final DownloadService? downloadService;

  const DownloadProgressBar({super.key, this.downloadService});

  @override
  State<DownloadProgressBar> createState() => _DownloadProgressBarState();
}

class _DownloadProgressBarState extends State<DownloadProgressBar> {
  late final DownloadService _downloadService;
  StreamSubscription<DownloadProgress>? _progressSub;
  DownloadProgress? _recentTerminalProgress;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _downloadService = widget.downloadService ?? DownloadService.instance;
    _downloadService.addListener(_onServiceChanged);
    _progressSub = _downloadService.progressStream.listen(_onProgressStream);
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _progressSub?.cancel();
    _downloadService.removeListener(_onServiceChanged);
    super.dispose();
  }

  void _onServiceChanged() {
    if (mounted) setState(() {});
  }

  void _onProgressStream(DownloadProgress progress) {
    if (!mounted) return;
    if (progress.status == DownloadStatus.completed ||
        progress.status == DownloadStatus.failed) {
      _dismissTimer?.cancel();
      setState(() {
        _recentTerminalProgress = progress;
      });
      _dismissTimer = Timer(const Duration(milliseconds: 3500), () {
        if (mounted) {
          setState(() {
            _recentTerminalProgress = null;
          });
        }
      });
    } else if (progress.status == DownloadStatus.cancelled) {
      setState(() {
        if (_recentTerminalProgress?.songIdentity == progress.songIdentity) {
          _recentTerminalProgress = null;
        }
      });
    } else {
      // In flight
      if (_recentTerminalProgress?.songIdentity == progress.songIdentity) {
        _recentTerminalProgress = null;
      }
      setState(() {});
    }
  }

  DownloadProgress? _getActiveOrRecent() {
    final active = _downloadService.activeDownloads.values.where(
      (d) =>
          d.status == DownloadStatus.downloading ||
          d.status == DownloadStatus.preparing,
    );
    if (active.isNotEmpty) {
      return active.last;
    }
    return _recentTerminalProgress;
  }

  String _formatBytes(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _getActiveOrRecent();
    final child = progress == null
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: _buildBar(context, progress),
          );

    if (MediaQuery.disableAnimationsOf(context)) return child;

    return AnimatedSize(
      duration: motionDuration(context, 260),
      curve: Curves.easeOutCubic,
      alignment: Alignment.bottomCenter,
      child: child,
    );
  }

  Widget _buildBar(BuildContext context, DownloadProgress progress) {
    final isDone = progress.status == DownloadStatus.completed;
    final isFail = progress.status == DownloadStatus.failed;
    final isPreparing = progress.status == DownloadStatus.preparing;
    final double? frac = isDone ? 1.0 : progress.progress;

    // Byte string (e.g., "2.4 MB / 5.2 MB")
    final bytesStr = progress.totalBytes != null && progress.totalBytes! > 0
        ? '${_formatBytes(progress.receivedBytes)} / ${_formatBytes(progress.totalBytes!)}'
        : _formatBytes(progress.receivedBytes);

    // Percentage string
    final pctText = isDone
        ? '100%'
        : isFail
            ? 'Failed'
            : isPreparing
                ? 'Preparing...'
                : frac != null
                    ? '${(frac * 100).round()}%'
                    : 'Downloading...';

    return GlassCard(
      borderRadius: 16,
      level: GlassLevel.floating,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Leading Icon / Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: (progress.song.albumArtUrl != null &&
                          progress.song.albumArtUrl!.isNotEmpty)
                      ? AlbumArt(
                          gradientId: progress.song.gradientId,
                          imageUrl: progress.song.albumArtUrl,
                          size: 36,
                          borderRadius: 8,
                          showShadow: false,
                        )
                      : Container(
                          color: AppColors.surface,
                          child: Icon(
                            isDone
                                ? Icons.check_circle_rounded
                                : isFail
                                    ? Icons.error_rounded
                                    : Icons.downloading_rounded,
                            size: 20,
                            color: isDone
                                ? AppColors.success
                                : isFail
                                    ? AppColors.error
                                    : AppColors.coral,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              // Song & Status Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      progress.song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (isDone) ...[
                          const Text(
                            'Saved to Music/Harmoniq · MP3',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.success,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ] else if (isFail) ...[
                          Expanded(
                            child: Text(
                              progress.errorMessage ?? 'Download failed',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.coral.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${progress.quality.format} • ${progress.quality.approxBitrateKbps}k',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.coral,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              bytesStr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Percentage / Progress Indicator
              Text(
                pctText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDone
                      ? AppColors.success
                      : isFail
                          ? AppColors.error
                          : AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              // Cancel / Dismiss Button
              GestureDetector(
                onTap: () {
                  if (isDone || isFail) {
                    setState(() {
                      _recentTerminalProgress = null;
                    });
                  } else {
                    _downloadService.cancelDownload(progress.songIdentity);
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Gradient Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 4,
              child: isFail
                  ? Container(color: AppColors.error)
                  : frac == null
                      ? const LinearProgressIndicator(
                          backgroundColor: AppColors.surface,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.coral,
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            return Stack(
                              children: [
                                Container(
                                  width: constraints.maxWidth,
                                  color: AppColors.surface,
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: constraints.maxWidth * frac.clamp(0.0, 1.0),
                                  decoration: BoxDecoration(
                                    gradient: isDone
                                        ? const LinearGradient(
                                            colors: [
                                              AppColors.success,
                                              Color(0xFF22C55E),
                                            ],
                                          )
                                        : const LinearGradient(
                                            colors: [
                                              AppColors.coral,
                                              AppColors.coralLight,
                                            ],
                                          ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
