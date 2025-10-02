import 'package:flutter/material.dart';
import 'package:flutter_image_gallery/ui/widgets/image_shimmer_placeholder.dart';

class ImageShimmerGrid extends StatelessWidget {
  final int itemCount;
  final double childAspectRatio;

  const ImageShimmerGrid({super.key, required this.itemCount, this.childAspectRatio = 1.0});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return const ImageShimmerPlaceholder();
      },
    );
  }
}
