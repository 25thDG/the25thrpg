import 'package:flutter/material.dart';

import '../../../../core/theme/rpg_colors.dart';

/// Shared card shell used by every dashboard section.
class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const SectionCard({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: RpgColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.4,
                ),
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
