import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// The calm, organic backdrop used on the welcome screens: two soft circles
/// in sand and sage on warm cream. It stands in for destination photography
/// until real images are supplied.
class BrandBackdrop extends StatelessWidget {
  const BrandBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Container(
      color: EvColors.cream,
      child: Stack(
        children: [
          Positioned(
            right: -size.width * 0.25,
            top: -size.width * 0.1,
            child: Container(
              width: size.width * 0.9,
              height: size.width * 0.9,
              decoration: const BoxDecoration(
                color: EvColors.sand,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: size.width * 0.12,
            top: size.width * 0.38,
            child: Container(
              width: size.width * 0.34,
              height: size.width * 0.34,
              decoration: const BoxDecoration(
                color: EvColors.sageSoft,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}
