import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dagboek_provider.dart';

class ProfielScreen extends StatelessWidget {
  const ProfielScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final commonAllergens = [
      {'name': 'Melk', 'icon': Icons.local_drink_rounded},
      {'name': 'Ei', 'icon': Icons.egg_rounded},
      {'name': 'Gluten', 'icon': Icons.grass_rounded},
      {'name': 'Noten', 'icon': Icons.eco_rounded},
      {'name': 'Pinda', 'icon': Icons.grass_rounded},
      {'name': 'Soja', 'icon': Icons.opacity_rounded},
      {'name': 'Vis', 'icon': Icons.set_meal_rounded},
      {'name': 'Schaaldieren', 'icon': Icons.waves_rounded},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Profiel & Instellingen'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const _ProfileHero(),
            const SizedBox(height: 32),
            _buildSectionHeader(context, 'Mijn Allergiën', 'De app waarschuwt je bij deze stoffen'),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Consumer<DagboekProvider>(
                builder: (context, provider, child) {
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: commonAllergens.map((allergen) {
                      final name = allergen['name'] as String;
                      final icon = allergen['icon'] as IconData;
                      final isSelected = provider.userAllergens.contains(name);

                      return InkWell(
                        onTap: () => provider.toggleAllergen(name),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? Theme.of(context).colorScheme.primary.withOpacity(0.1) 
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected 
                                  ? Theme.of(context).colorScheme.primary 
                                  : Colors.grey.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                icon, 
                                size: 16, 
                                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey
                              ),
                              const SizedBox(width: 8),
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Theme.of(context).colorScheme.primary : Colors.black87,
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 6),
                                Icon(Icons.check_circle, size: 14, color: Theme.of(context).colorScheme.primary),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.blueGrey[400], fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const CircleAvatar(
              radius: 35,
              backgroundColor: Colors.white,
              child: Icon(Icons.person_rounded, size: 40, color: Color(0xFF0F172A)),
            ),
          ),
          const SizedBox(width: 20),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mijn Gezondheid',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Persoonlijk Profiel',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
