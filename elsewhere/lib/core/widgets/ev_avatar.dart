import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../utils/formatters.dart';

/// Circular avatar. Shows initials when a [name] is known, or a person icon
/// when only an opaque [seed] (such as a user id) is available. The tone is
/// chosen deterministically from the palette.
class EvAvatar extends StatelessWidget {
  const EvAvatar({super.key, this.name, this.seed, this.size = 40})
      : assert(name != null || seed != null);

  final String? name;
  final String? seed;
  final double size;

  static const List<Color> _tones = [
    EvColors.sand,
    EvColors.sageSoft,
    EvColors.terracottaSoft,
  ];

  @override
  Widget build(BuildContext context) {
    final key = name ?? seed ?? '';
    final tone = _tones[key.hashCode.abs() % _tones.length];
    final label = name == null ? 'Traveller' : name!;
    return Semantics(
      label: label,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: tone,
          shape: BoxShape.circle,
          border: Border.all(color: EvColors.cream, width: 2),
        ),
        child: name == null
            ? Icon(Icons.person_outline,
                size: size * 0.52, color: EvColors.charcoal)
            : Text(
                EvFormat.initials(name!),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: size * 0.36,
                      color: EvColors.charcoal,
                    ),
              ),
      ),
    );
  }
}

/// A short overlapping row of avatars with an overflow count.
class EvAvatarStack extends StatelessWidget {
  const EvAvatarStack({
    super.key,
    required this.names,
    this.seeds = const [],
    this.size = 32,
    this.max = 4,
  });

  final List<String> names;
  final List<String> seeds;
  final double size;
  final int max;

  @override
  Widget build(BuildContext context) {
    final total = names.isNotEmpty ? names.length : seeds.length;
    final shown = total < max ? total : max;
    final overlap = size * 0.62;
    final extra = total - shown;
    return SizedBox(
      height: size,
      width: shown == 0
          ? 0
          : overlap * (shown - 1) + size + (extra > 0 ? size * 0.9 : 0),
      child: Stack(
        children: [
          for (var i = 0; i < shown; i++)
            Positioned(
              left: overlap * i,
              child: names.isNotEmpty
                  ? EvAvatar(name: names[i], size: size)
                  : EvAvatar(seed: seeds[i], size: size),
            ),
          if (extra > 0)
            Positioned(
              left: overlap * (shown - 1) + size + 6,
              top: 0,
              bottom: 0,
              child: Center(
                child: Text('+$extra',
                    style: Theme.of(context).textTheme.labelMedium),
              ),
            ),
        ],
      ),
    );
  }
}
