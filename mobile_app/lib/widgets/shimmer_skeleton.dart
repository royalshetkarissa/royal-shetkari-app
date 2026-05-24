import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerSkeleton extends StatelessWidget {
  final double? width;
  final double? height;
  final double? borderRadius;

  const ShimmerSkeleton({super.key, this.width, this.height, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    final baseColor = Colors.grey.shade300;
    final highlightColor = Colors.grey.shade100;

    // Render a simple rectangular skeleton when dimensions are provided.
    if (width != null && height != null) {
      return Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(borderRadius ?? 8),
          ),
        ),
      );
    }

    // Default full-page placeholder layout.
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avatar and greeting
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: baseColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _Line(widthFactor: 0.6),
                      SizedBox(height: 8),
                      _Line(widthFactor: 0.4),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Weather card
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 20),
            // Action cards (book call, scan disease)
            Row(
              children: const [
                _Rect(width: 0.45),
                SizedBox(width: 12),
                _Rect(width: 0.45),
              ],
            ),
            const SizedBox(height: 20),
            // Tasks list placeholder
            _Line(widthFactor: 0.5, height: 20),
            const SizedBox(height: 12),
            ...List.generate(
                3,
                (_) => _Line(
                    widthFactor: 1.0,
                    height: 16,
                    margin: EdgeInsets.only(bottom: 8))),
            const SizedBox(height: 20),
            // Disease history horizontal list
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 5,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, __) => Container(
                  width: 120,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Simple line placeholder
class _Line extends StatelessWidget {
  final double widthFactor;
  final double height;
  final EdgeInsetsGeometry? margin;
  const _Line({required this.widthFactor, this.height = 14, this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 4),
      width: MediaQuery.of(context).size.width * widthFactor,
      height: height,
      color: Colors.grey.shade300,
    );
  }
}

// Simple rectangular placeholder used in other screens
class _Rect extends StatelessWidget {
  final double width;
  const _Rect({required this.width});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: (width * 100).toInt(),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
