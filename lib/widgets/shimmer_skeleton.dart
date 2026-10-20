import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ShimmerSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final ShapeBorder? shapeBorder;

  const ShimmerSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
    this.shapeBorder,
  });

  const ShimmerSkeleton.circular({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        borderRadius = size / 2,
        shapeBorder = const CircleBorder();

  @override
  State<ShimmerSkeleton> createState() => _ShimmerSkeletonState();
}

class _ShimmerSkeletonState extends State<ShimmerSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? AppColors.glassSecondary
        : Colors.grey.shade300.withValues(alpha: 0.6);
    final highlightColor = isDark
        ? AppColors.glassSelected
        : Colors.grey.shade100.withValues(alpha: 0.8);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.shapeBorder == null
                ? BorderRadius.circular(widget.borderRadius)
                : null,
            shape: widget.shapeBorder is CircleBorder
                ? BoxShape.circle
                : BoxShape.rectangle,
            gradient: LinearGradient(
              begin: Alignment(-2.0 + 4.0 * _controller.value, -0.3),
              end: Alignment(-0.5 + 4.0 * _controller.value, 0.3),
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const [0.1, 0.5, 0.9],
            ),
          ),
        );
      },
    );
  }
}

/// A shimmer placeholder for horizontal cards (e.g. in Explore / Home)
class ShimmerSongCard extends StatelessWidget {
  final double width;
  const ShimmerSongCard({super.key, this.width = 140});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      margin: const EdgeInsets.only(right: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerSkeleton(
            width: width,
            height: width,
            borderRadius: 16,
          ),
          const SizedBox(height: 10),
          ShimmerSkeleton(
            width: width * 0.85,
            height: 12,
            borderRadius: 4,
          ),
          const SizedBox(height: 6),
          ShimmerSkeleton(
            width: width * 0.55,
            height: 10,
            borderRadius: 4,
          ),
        ],
      ),
    );
  }
}

/// A shimmer placeholder for vertical list tiles (e.g. in Search / Library)
class ShimmerSongTile extends StatelessWidget {
  const ShimmerSongTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const ShimmerSkeleton(
            width: 52,
            height: 52,
            borderRadius: 12,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerSkeleton(
                  width: double.infinity,
                  height: 14,
                  borderRadius: 4,
                ),
                SizedBox(height: 8),
                ShimmerSkeleton(
                  width: 120,
                  height: 11,
                  borderRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          const ShimmerSkeleton(
            width: 32,
            height: 14,
            borderRadius: 4,
          ),
        ],
      ),
    );
  }
}

/// A list of shimmer placeholder tiles
class ShimmerSongList extends StatelessWidget {
  final int count;
  const ShimmerSongList({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(count, (_) => const ShimmerSongTile()),
    );
  }
}
