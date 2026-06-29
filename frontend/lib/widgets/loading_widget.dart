import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../design_system/colors.dart';

class LoadingWidget extends StatelessWidget {
  final bool useShimmer;
  final int count;

  const LoadingWidget({
    Key? key,
    this.useShimmer = true,
    this.count = 3,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!useShimmer) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? ApexColors.neutral800 : ApexColors.neutral200;
    final highlightColor = isDark ? ApexColors.neutral700 : ApexColors.neutral100;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: ApexColors.neutral0,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 12,
                        color: ApexColors.neutral0,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 150,
                        height: 12,
                        color: ApexColors.neutral0,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 80,
                        height: 10,
                        color: ApexColors.neutral0,
                      ),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
