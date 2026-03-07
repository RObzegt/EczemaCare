import 'package:flutter/material.dart';
import 'dagboek_screen.dart';
import 'toevoegen_screen.dart';
import 'analyse_screen.dart';
import 'eliminatie_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    DagboekScreen(),
    ToevoegenScreen(),
    AnalyseScreen(),
    EliminatieScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.history_edu_rounded),
            selectedIcon: Icon(Icons.history_edu_rounded),
            label: 'Dagboek',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_moderator_rounded),
            selectedIcon: Icon(Icons.add_moderator_rounded),
            label: 'Toevoegen',
          ),
          NavigationDestination(
            icon: Icon(Icons.troubleshoot_rounded),
            selectedIcon: Icon(Icons.troubleshoot_rounded),
            label: 'Analyse',
          ),
          NavigationDestination(
            icon: Icon(Icons.science_outlined),
            selectedIcon: Icon(Icons.science_rounded),
            label: 'Eliminatie',
          ),
        ],
      ),
    );
  }
}
