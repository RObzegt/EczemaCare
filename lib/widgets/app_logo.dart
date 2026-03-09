import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double height;
  final bool showTitle;
  final String? subtitle;

  const AppLogo({
    super.key,
    this.height = 44,
    this.showTitle = true,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/logo.png',
          height: height,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.track_changes_rounded,
            size: height - 4,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        if (showTitle) ...[
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'TriggerTrace',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                  letterSpacing: -0.5,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.blueGrey[400],
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
