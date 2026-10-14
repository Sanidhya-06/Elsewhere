import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// A trip's cover: the supplied photo when there is one, otherwise a calm
/// tonal placeholder with the destination's initial in the editorial serif.
/// Text is never drawn over the image; titles sit beneath it, which keeps
/// contrast independent of the photograph.
class TripCover extends StatelessWidget {
  const TripCover({
    super.key,
    required this.destination,
    this.imageUrl,
    this.height = 160,
    this.radius = 24,
    this.child,
  });

  final String destination;
  final String? imageUrl;
  final double height;
  final double radius;

  /// Optional overlay, e.g. a back button.
  final Widget? child;

  static const List<List<Color>> _tones = [
    [EvColors.sand, EvColors.terracottaSoft],
    [EvColors.sageSoft, EvColors.sage],
    [EvColors.terracottaSoft, EvColors.sand],
  ];

  @override
  Widget build(BuildContext context) {
    final tone = _tones[destination.hashCode.abs() % _tones.length];
    final initial =
        destination.trim().isEmpty ? '?' : destination.trim()[0].toUpperCase();

    final placeholder = Container(
      color: tone[0],
      child: Stack(
        children: [
          Positioned(
            right: -height * 0.15,
            bottom: -height * 0.35,
            child: Container(
              width: height * 1.2,
              height: height * 1.2,
              decoration: BoxDecoration(color: tone[1], shape: BoxShape.circle),
            ),
          ),
          Positioned(
            left: 20,
            top: 8,
            child: Text(
              initial,
              style: EvTypography.display(
                size: height * 0.5,
                color: EvColors.charcoal,
                weight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    final url = imageUrl;
    final Widget background = (url == null || url.isEmpty)
        ? placeholder
        : Image.network(
            url,
            fit: BoxFit.cover,
            // Fall back to the placeholder on any load failure.
            errorBuilder: (_, __, ___) => placeholder,
            loadingBuilder: (context, image, progress) =>
                progress == null ? image : placeholder,
          );

    return Semantics(
      image: true,
      label: 'Cover for $destination',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              background,
              if (child != null) child!,
            ],
          ),
        ),
      ),
    );
  }
}
