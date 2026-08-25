import 'package:flutter/material.dart';
import '../theme/app_typography.dart';
import '../utils/formatters.dart';

/// Animates a numeric value with a smooth count-up/down transition.
/// Uses TweenAnimationBuilder so no AnimationController cleanup needed.
class AnimatedCount extends StatelessWidget {
  final num value;
  final String Function(num)? formatter;
  final TextStyle? style;
  final Duration duration;
  final String? prefix;
  final int decimalPlaces;

  const AnimatedCount({
    super.key,
    required this.value,
    this.formatter,
    this.style,
    this.duration = const Duration(milliseconds: 600),
    this.prefix,
    this.decimalPlaces = 0,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        String text;
        if (formatter != null) {
          text = formatter!(animatedValue);
        } else {
          text = '${prefix ?? ""}${animatedValue.toStringAsFixed(decimalPlaces)}';
        }
        return Text(
          text,
          style: style ??
              AppTypography.h3.copyWith(
                fontFamily: AppTypography.numberFontFamily,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}
