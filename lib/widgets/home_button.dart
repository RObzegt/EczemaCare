import 'package:flutter/material.dart';
import '../screens/home_screen.dart';

class HomeButton extends StatelessWidget {
  const HomeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.home_rounded),
      tooltip: 'Terug naar Dagboek',
      onPressed: () {
        // We push and remove until we are back at the HomeScreen
        // Or we just navigate to HomeScreen if we are in a tab.
        // Since many screens are within the HomeScreen PageView/Tab, 
        // we might just want to pop if it's a pushed route, 
        // but the user want a explicit "Home" that returns to Dagboek.
        
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      },
    );
  }
}
