import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../colors.dart';
import '../border_radius.dart';

/// Apex Design System — Loading Skeleton
///
/// Consistent loading skeletons for cards, lists, and tables.
class ApexLoadingSkeleton extends StatelessWidget {
  final int count;
  final ApexSkeletonType type;

  const ApexLoadingSkeleton({
    Key? key,
    this.count = 3,
    this.type = ApexSkeletonType.list,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? ApexColors.darkSurfaceVariant : ApexColors.neutral200;
    final highlightColor = isDark ? ApexColors.neutral700 : ApexColors.neutral100;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: switch (type) {
        ApexSkeletonType.list => _buildListSkeleton(),
        ApexSkeletonType.card => _buildCardSkeleton(),
        ApexSkeletonType.table => _buildTableSkeleton(),
        ApexSkeletonType.stat => _buildStatSkeleton(),
      },
    );
  }

  Widget _buildListSkeleton() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: ApexRadius.mdAll,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 150,
                      height: 12,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCardSkeleton() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: List.generate(count, (index) {
        return Container(
          width: 280,
          height: 160,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: ApexRadius.lgAll,
          ),
        );
      }),
    );
  }

  Widget _buildTableSkeleton() {
    return Column(
      children: [
        // Header
        Container(
          height: 48,
          color: Colors.white,
        ),
        // Rows
        ...List.generate(count, (index) {
          return Container(
            height: 56,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: ApexColors.neutral200),
              ),
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: Container(margin: const EdgeInsets.all(16), color: Colors.white)),
                Expanded(flex: 3, child: Container(margin: const EdgeInsets.all(16), color: Colors.white)),
                Expanded(flex: 2, child: Container(margin: const EdgeInsets.all(16), color: Colors.white)),
                Expanded(flex: 1, child: Container(margin: const EdgeInsets.all(16), color: Colors.white)),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStatSkeleton() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: List.generate(count, (index) {
        return Container(
          width: 200,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: ApexRadius.lgAll,
          ),
        );
      }),
    );
  }
}

enum ApexSkeletonType { list, card, table, stat }
