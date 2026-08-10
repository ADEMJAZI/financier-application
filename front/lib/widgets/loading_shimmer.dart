import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_spacing.dart';

class LoadingShimmer extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;
  
  const LoadingShimmer({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(AppSpacing.radiusXs),
        ),
      ),
    );
  }
}

class LoadingShimmerList extends StatelessWidget {
  final int itemCount;
  
  const LoadingShimmerList({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LoadingShimmer(
                  width: 150,
                  height: 20,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                ),
                const SizedBox(height: AppSpacing.sm),
                LoadingShimmer(
                  width: double.infinity,
                  height: 16,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                ),
                const SizedBox(height: AppSpacing.xs),
                LoadingShimmer(
                  width: 200,
                  height: 16,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
