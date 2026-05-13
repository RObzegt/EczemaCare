import 'package:flutter/material.dart';

class HomeButton extends StatelessWidget {
  const HomeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.home_rounded),
      tooltip: 'Terug naar Dagboek',
      onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
    );
  }
}
