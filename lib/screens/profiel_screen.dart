import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dagboek_provider.dart';
import '../widgets/app_logo.dart';

class ProfielScreen extends StatefulWidget {
  const ProfielScreen({super.key});

  @override
  State<ProfielScreen> createState() => _ProfielScreenState();
}

class _ProfielScreenState extends State<ProfielScreen> {
  final List<TextEditingController> _customControllers = List.generate(
    3,
    (_) => TextEditingController(),
  );

  @override
  void initState() {
    super.initState();
    final provider = context.read<DagboekProvider>();
    final customs = provider.userAllergens
        .where((a) => ![
              'Melk', 'Ei', 'Gluten', 'Noten',
              'Pinda', 'Soja', 'Vis', 'Schaaldieren',
            ].contains(a))
        .toList();
    for (int i = 0; i < customs.length && i < 3; i++) {
      _customControllers[i].text = customs[i];
    }
  }

  @override
  void dispose() {
    for (final c in _customControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveCustomAllergen(int index, String value, DagboekProvider provider) async {
    final knownAllergens = [
      'Melk', 'Ei', 'Gluten', 'Noten',
      'Pinda', 'Soja', 'Vis', 'Schaaldieren',
    ];
    final currentCustoms = provider.userAllergens
        .where((a) => !knownAllergens.contains(a))
        .toList();

    if (index < currentCustoms.length) {
      final old = currentCustoms[index];
      if (provider.userAllergens.contains(old)) {
        await provider.toggleAllergen(old);
      }
    }

    final trimmed = value.trim();
    if (trimmed.isNotEmpty && !provider.userAllergens.contains(trimmed)) {
      await provider.toggleAllergen(trimmed);
    }
  }

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
      appBar: AppBar(
        title: const AppLogo(subtitle: 'Profiel'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const _ProfileHero(),
            const SizedBox(height: 32),
            _buildSectionHeader(context, 'Mijn Voeding', 'De app waarschuwt je bij deze voeding'),
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
                                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) 
                                : Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected 
                                  ? Theme.of(context).colorScheme.primary 
                                  : Colors.grey.withValues(alpha: 0.2),
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
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Consumer<DagboekProvider>(
                builder: (context, provider, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Eigen voeding',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.blueGrey[500],
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (int i = 0; i < 3; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: TextField(
                            controller: _customControllers[i],
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: 'Vrij veld ${i + 1}',
                              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                              prefixIcon: Icon(Icons.edit_rounded, size: 18, color: Colors.grey[400]),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                              ),
                            ),
                            style: const TextStyle(fontSize: 14),
                            onSubmitted: (value) => _saveCustomAllergen(i, value, provider),
                            onTapOutside: (_) {
                              FocusScope.of(context).unfocus();
                              _saveCustomAllergen(i, _customControllers[i].text, provider);
                            },
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionHeader(context, 'Weergave', 'Pas het uiterlijk aan'),
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Consumer<DagboekProvider>(
                builder: (context, provider, _) {
                  return SwitchListTile(
                    secondary: Icon(
                      provider.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      color: const Color(0xFF6B8E5A),
                    ),
                    title: const Text('Donkere modus', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      provider.isDarkMode ? 'Aan' : 'Uit',
                      style: TextStyle(fontSize: 12, color: Colors.blueGrey[400]),
                    ),
                    value: provider.isDarkMode,
                    activeThumbColor: const Color(0xFF6B8E5A),
                    onChanged: (_) => provider.toggleDarkMode(),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
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
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const CircleAvatar(
              radius: 35,
              backgroundColor: Colors.white,
              child: Icon(Icons.person_rounded, size: 40, color: Color(0xFF0F172A)),
            ),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
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
          ),
        ],
      ),
    );
  }
}
