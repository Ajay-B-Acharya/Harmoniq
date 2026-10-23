import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// Shape modes for Neumorphic components
enum NeumorphicShape {
  flat,
  convex,
  concave,
}

/// Core Neumorphic container supporting both extruded (raised) and
/// tactile indentation (inset/concave) states with dual light/dark shadows.
class NeumorphicBox extends StatelessWidget {
  final Widget? child;
  final double borderRadius;
  final BoxShape shape;
  final bool isInset;
  final double depth;
  final Color? color;
  final Gradient? gradient;
  final Border? border;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const NeumorphicBox({
    super.key,
    this.child,
    this.borderRadius = 16,
    this.shape = BoxShape.rectangle,
    this.isInset = false,
    this.depth = 4.5,
    this.color,
    this.gradient,
    this.border,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor =
        color ?? (isDark ? AppDarkColors.background : AppColors.background);
    final shadowLight =
        isDark ? AppDarkColors.lightShadow : AppColors.lightShadow;
    final shadowDark =
        isDark ? AppDarkColors.darkShadow : AppColors.darkShadow;

    Widget container = Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveColor,
        gradient: gradient,
        shape: shape,
        borderRadius: shape == BoxShape.rectangle
            ? BorderRadius.circular(borderRadius)
            : null,
        border: border,
        boxShadow: isInset
            ? null
            : [
                BoxShadow(
                  color: shadowLight.withValues(alpha: isDark ? 0.90 : 0.95),
                  offset: Offset(-depth, -depth),
                  blurRadius: depth * 2.2,
                  spreadRadius: 0.5,
                ),
                BoxShadow(
                  color: shadowDark.withValues(alpha: isDark ? 0.85 : 0.65),
                  offset: Offset(depth, depth),
                  blurRadius: depth * 2.2,
                  spreadRadius: 0.5,
                ),
              ],
      ),
      child: isInset
          ? CustomPaint(
              foregroundPainter: _NeumorphicInnerShadowPainter(
                borderRadius: borderRadius,
                shape: shape,
                shadowColor:
                    shadowDark.withValues(alpha: isDark ? 0.85 : 0.8),
                highlightColor:
                    shadowLight.withValues(alpha: isDark ? 0.90 : 0.95),
                depth: depth,
              ),
              child: child,
            )
          : child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: container,
      );
    }
    return container;
  }
}

/// Custom painter that casts dual inner shadows (top-left dark, bottom-right white)
/// creating authentic Neumorphic tactile indentations / grooves.
class _NeumorphicInnerShadowPainter extends CustomPainter {
  final double borderRadius;
  final BoxShape shape;
  final Color shadowColor;
  final Color highlightColor;
  final double depth;

  const _NeumorphicInnerShadowPainter({
    required this.borderRadius,
    required this.shape,
    required this.shadowColor,
    required this.highlightColor,
    required this.depth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final rrect = shape == BoxShape.circle
        ? RRect.fromRectAndRadius(rect, Radius.circular(size.width / 2))
        : RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    canvas.save();
    canvas.clipRRect(rrect);

    // Dark top-left inner shadow
    final darkPaint = Paint()
      ..color = shadowColor
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, depth * 1.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = depth * 1.6;
    canvas.drawRRect(rrect.shift(Offset(-depth * 0.7, -depth * 0.7)), darkPaint);

    // Light bottom-right inner specular reflection
    final lightPaint = Paint()
      ..color = highlightColor
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, depth * 1.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = depth * 1.6;
    canvas.drawRRect(rrect.shift(Offset(depth * 0.7, depth * 0.7)), lightPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NeumorphicInnerShadowPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.shape != shape ||
      oldDelegate.shadowColor != shadowColor ||
      oldDelegate.highlightColor != highlightColor ||
      oldDelegate.depth != depth;
}

/// Interactive Neumorphic button that smoothly depresses (transitions to inset / reduced depth)
/// when pressed, providing responsive tactile feedback.
class NeumorphicButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final BoxShape shape;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;
  final Color? color;
  final double depth;
  final String? tooltip;

  const NeumorphicButton({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = 16,
    this.shape = BoxShape.rectangle,
    this.padding = const EdgeInsets.all(12),
    this.width,
    this.height,
    this.color,
    this.depth = 4.5,
    this.tooltip,
  });

  @override
  State<NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<NeumorphicButton> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails _) {
    if (widget.onTap == null) return;
    setState(() => _isPressed = true);
    HapticFeedback.selectionClick();
  }

  void _onTapUp(TapUpDetails _) {
    if (widget.onTap == null) return;
    setState(() => _isPressed = false);
    widget.onTap?.call();
  }

  void _onTapCancel() {
    if (widget.onTap == null) return;
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    Widget button = GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: NeumorphicBox(
          width: widget.width,
          height: widget.height,
          padding: widget.padding,
          borderRadius: widget.borderRadius,
          shape: widget.shape,
          color: widget.color,
          depth: _isPressed ? 1.5 : widget.depth,
          isInset: _isPressed,
          child: widget.child,
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: button);
    }
    return button;
  }
}

/// Neumorphic round or squircle icon button matching the reference top bar back & menu buttons.
class NeumorphicIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final Color? color;
  final Color? iconColor;
  final String? tooltip;
  final bool isCircle;

  const NeumorphicIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 46,
    this.iconSize = 22,
    this.color,
    this.iconColor,
    this.tooltip,
    this.isCircle = true,
  });

  @override
  Widget build(BuildContext context) {
    return NeumorphicButton(
      width: size,
      height: size,
      borderRadius: isCircle ? size / 2 : 14,
      shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
      padding: EdgeInsets.zero,
      color: color,
      onTap: onTap,
      tooltip: tooltip,
      child: Center(
        child: Icon(
          icon,
          size: iconSize,
          color: iconColor ?? AppColors.textPrimaryOf(context),
        ),
      ),
    );
  }
}

/// Neumorphic Switch (Toggle)
///
/// Faithfully reproduces the tactile toggle from the reference image:
/// Recessed groove track that illuminates with vibrant coral when active,
/// and an extruded circular knob with dual outer shadow that glides smoothly.
class NeumorphicSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const NeumorphicSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<NeumorphicSwitch> createState() => _NeumorphicSwitchState();
}

class _NeumorphicSwitchState extends State<NeumorphicSwitch> {
  static const double _trackWidth = 54.0;
  static const double _trackHeight = 30.0;
  static const double _knobDiameter = 24.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackInactive =
        isDark ? AppDarkColors.insetTrack : AppColors.insetTrack;
    final shadowDark =
        isDark ? AppDarkColors.darkShadow : AppColors.darkShadow;
    final shadowLight =
        isDark ? AppDarkColors.lightShadow : Colors.white;

    return Semantics(
      toggled: widget.value,
      button: true,
      onTap: () => widget.onChanged(!widget.value),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onChanged(!widget.value);
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: _trackWidth,
          height: _trackHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_trackHeight / 2),
            color: widget.value ? AppColors.coral : trackInactive,
            boxShadow: [
              if (widget.value)
                BoxShadow(
                  color: AppColors.coral.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: CustomPaint(
            foregroundPainter: _NeumorphicInnerShadowPainter(
              borderRadius: _trackHeight / 2,
              shape: BoxShape.rectangle,
              shadowColor: widget.value
                  ? AppColors.coralDark.withValues(alpha: 0.5)
                  : shadowDark.withValues(alpha: 0.75),
              highlightColor: widget.value
                  ? Colors.white.withValues(alpha: 0.3)
                  : shadowLight.withValues(alpha: isDark ? 0.35 : 0.85),
              depth: 3.5,
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              alignment: widget.value
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Container(
                  width: _knobDiameter,
                  height: _knobDiameter,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? AppDarkColors.textPrimary : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.14),
                        offset: const Offset(1, 2),
                        blurRadius: 4,
                      ),
                      BoxShadow(
                        color: shadowLight.withValues(alpha: isDark ? 0.40 : 0.8),
                        offset: const Offset(-1, -1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Neumorphic Slider
///
/// Reproduces the "Transaction Limit: $2000" slider from the reference:
/// Recessed groove track with vibrant coral progress fill, and an extruded
/// rounded-square knob embossed with 4 tactile grip dots.
class NeumorphicSlider extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const NeumorphicSlider({
    super.key,
    required this.value,
    this.min = 0.0,
    this.max = 100.0,
    required this.onChanged,
  });

  @override
  State<NeumorphicSlider> createState() => _NeumorphicSliderState();
}

class _NeumorphicSliderState extends State<NeumorphicSlider> {
  static const double _trackHeight = 8.0;
  static const double _knobSize = 26.0;

  void _handleDrag(Offset localPosition, double width) {
    if (width <= _knobSize) return;
    final trackUsableWidth = width - _knobSize;
    final clampedX = (localPosition.dx - (_knobSize / 2)).clamp(0.0, trackUsableWidth);
    final percent = clampedX / trackUsableWidth;
    final newValue = widget.min + percent * (widget.max - widget.min);
    widget.onChanged(newValue.clamp(widget.min, widget.max));
  }

  @override
  Widget build(BuildContext context) {
    final range = widget.max - widget.min;
    final fraction = range > 0 ? ((widget.value - widget.min) / range).clamp(0.0, 1.0) : 0.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackInactive =
        isDark ? AppDarkColors.insetTrack : AppColors.insetTrack;
    final knobColor =
        isDark ? AppDarkColors.background : AppColors.background;
    final shadowDark =
        isDark ? AppDarkColors.darkShadow : AppColors.darkShadow;
    final shadowLight =
        isDark ? AppDarkColors.lightShadow : Colors.white;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final trackUsableWidth = (totalWidth - _knobSize).clamp(0.0, totalWidth);
        final knobOffset = fraction * trackUsableWidth;

        return GestureDetector(
          onHorizontalDragUpdate: (details) => _handleDrag(details.localPosition, totalWidth),
          onTapDown: (details) => _handleDrag(details.localPosition, totalWidth),
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            height: 36,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Recessed track
                Positioned(
                  left: 0,
                  right: 0,
                  child: Container(
                    height: _trackHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(_trackHeight / 2),
                      color: trackInactive,
                    ),
                    child: CustomPaint(
                      foregroundPainter: _NeumorphicInnerShadowPainter(
                        borderRadius: _trackHeight / 2,
                        shape: BoxShape.rectangle,
                        shadowColor: shadowDark.withValues(alpha: 0.7),
                        highlightColor: shadowLight.withValues(alpha: isDark ? 0.35 : 0.9),
                        depth: 2.5,
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: fraction,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(_trackHeight / 2),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF7A44), AppColors.coral],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Extruded Knob with 4 grip dots
                Positioned(
                  left: knobOffset,
                  child: Container(
                    width: _knobSize,
                    height: _knobSize,
                    decoration: BoxDecoration(
                      color: knobColor,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: shadowLight.withValues(alpha: isDark ? 0.40 : 0.95),
                          offset: const Offset(-2, -2),
                          blurRadius: 5,
                        ),
                        BoxShadow(
                          color: shadowDark.withValues(alpha: isDark ? 0.85 : 0.75),
                          offset: const Offset(2, 3),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildGripDot(context),
                              const SizedBox(width: 3),
                              _buildGripDot(context),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildGripDot(context),
                              const SizedBox(width: 3),
                              _buildGripDot(context),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGripDot(BuildContext context) => Container(
        width: 3,
        height: 3,
        decoration: BoxDecoration(
          color: AppColors.textSecondaryOf(context),
          shape: BoxShape.circle,
        ),
      );
}

/// Neumorphic Segmented Control (Pill Tabs)
///
/// Reproduces "Today", "Yesterday", "Month" filter tabs from the History screen:
/// The active item is sunken with tactile indentation; inactive items are soft extruded pills.
class NeumorphicSegmentedControl extends StatelessWidget {
  final List<String> segments;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const NeumorphicSegmentedControl({
    super.key,
    required this.segments,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(segments.length, (index) {
          final isSelected = index == selectedIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onSelected(index);
              },
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                child: NeumorphicBox(
                  borderRadius: 20,
                  isInset: isSelected,
                  depth: isSelected ? 3.0 : 3.5,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 10,
                  ),
                  child: Text(
                    segments[index],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.textPrimaryOf(context)
                          : AppColors.textSecondaryOf(context),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// 3D Rainbow Donut / Ring Chart
///
/// Faithfully reproduces the centerpiece from the "History" screen:
/// A vibrant smooth rainbow gradient ring with an extruded circular center cap
/// emerging proudly out of the background, plus a soft extruded callout badge.
class NeumorphicDonutChart extends StatelessWidget {
  final double size;
  final String calloutLabel;
  final double progress;

  const NeumorphicDonutChart({
    super.key,
    this.size = 230,
    this.calloutLabel = '30% (Listening)',
    this.progress = 0.85,
  });

  @override
  Widget build(BuildContext context) {
    final capSize = size * 0.52;

    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Rainbow Ring with outer & inner soft 3D shadows
            CustomPaint(
              size: Size(size, size),
              painter: _RainbowDonutPainter(
                strokeWidth: size * 0.22,
              ),
            ),
            // Extruded Center Circular Cap emerging directly out of the middle
            NeumorphicBox(
              width: capSize,
              height: capSize,
              shape: BoxShape.circle,
              depth: 6.0,
              child: const SizedBox.shrink(),
            ),
            // Floating Callout Badge "✖ 30% (Food)" / category
            Positioned(
              left: 0,
              bottom: size * 0.18,
              child: NeumorphicBox(
                borderRadius: 14,
                depth: 3.5,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.close_rounded,
                      size: 13,
                      color: AppColors.textPrimaryOf(context),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      calloutLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paints the continuous multi-stop rainbow spectrum donut ring with soft bevel
class _RainbowDonutPainter extends CustomPainter {
  final double strokeWidth;

  const _RainbowDonutPainter({required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Outer soft glow/shadow for 3D elevation
    final shadowPaint = Paint()
      ..color = AppColors.darkShadow.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center + const Offset(3, 4), radius, shadowPaint);

    // Multi-color SweepGradient rainbow
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      startAngle: 0,
      endAngle: math.pi * 2,
      colors: const [
        Color(0xFFFF5252), // Coral Red
        Color(0xFFFF7A30), // Orange
        Color(0xFFFFD13B), // Amber
        Color(0xFF6DD400), // Lime Green
        Color(0xFF28C76F), // Emerald Mint
        Color(0xFF00CFE8), // Cyan Blue
        Color(0xFFFF5252), // Loop back
      ],
      stops: const [0.0, 0.20, 0.40, 0.60, 0.78, 0.92, 1.0],
      transform: const GradientRotation(-math.pi / 2),
    );

    final ringPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, ringPaint);
  }

  @override
  bool shouldRepaint(covariant _RainbowDonutPainter oldDelegate) =>
      oldDelegate.strokeWidth != strokeWidth;
}

/// Neumorphic Credit Card
///
/// Reproduces the "Main Card" VISA element from the reference image:
/// Soft extruded card with VISA mark, embossed card number, and expiration/CVV details.
class NeumorphicCreditCard extends StatelessWidget {
  final String cardNumber;
  final String expires;
  final String cvv;
  final String cardType;

  const NeumorphicCreditCard({
    super.key,
    this.cardNumber = '****  ****  ****  1385',
    this.expires = '10/24',
    this.cvv = '123',
    this.cardType = 'VISA',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppDarkColors.textPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppDarkColors.textSecondary : AppColors.textSecondary;

    return NeumorphicBox(
      borderRadius: 22,
      depth: 6.0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Card Type Brand Mark (e.g. VISA)
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              cardType,
              style: const TextStyle(
                fontFamily: 'sans-serif',
                fontSize: 22,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 1.5,
                color: Color(0xFF1E3A8A), // Classic VISA Navy
              ),
            ),
          ),
          const SizedBox(height: 28),
          // Masked Card Number
          Text(
            cardNumber,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.2,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          // Expiration & CVV
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EXPIRES',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    expires,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 48),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CVV',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cvv,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Setting item row with icon, title, optional subtitle, and Neumorphic switch or trailing widget
class NeumorphicSettingRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const NeumorphicSettingRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          NeumorphicBox(
            width: 42,
            height: 42,
            shape: BoxShape.circle,
            depth: 3.0,
            child: Icon(
              icon,
              size: 20,
              color: AppColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondaryOf(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
