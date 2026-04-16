import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'providers/dagboek_provider.dart';
import 'screens/home_screen.dart';
import 'screens/paywall_screen.dart';
import 'services/purchases_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiseer Nederlandse locale voor datums
  await initializeDateFormatting('nl_NL', null);
  
  // Initialiseer RevenueCat
  await PurchasesService.init();
  const bool bypassPaywall = bool.fromEnvironment('BYPASS_PAYWALL');
  final bool hasSubscription = bypassPaywall || await PurchasesService.hasActiveSubscription();
  
  runApp(TriggerTraceApp(hasSubscription: hasSubscription));
}

class TriggerTraceApp extends StatelessWidget {
  final bool hasSubscription;
  const TriggerTraceApp({super.key, required this.hasSubscription});

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6B8E5A),
      primary: const Color(0xFF6B8E5A),
      secondary: const Color(0xFF8FAF7E),
      tertiary: const Color(0xFFF43F5E),
      brightness: brightness,
    );

    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final scaffoldColor = isDark ? const Color(0xFF121212) : const Color(0xFFF1F5F9);
    final textColor = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B);
    final subtleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cardBorderColor = isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF1F5F9);
    final inputFillColor = isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF1F5F9);

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: scaffoldColor,
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: subtleColor),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 2,
        shadowColor: const Color(0x1A000000),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cardBorderColor),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFillColor,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: inputFillColor,
        selectedColor: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE0F2FE),
        labelStyle: TextStyle(
          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide.none,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColor,
        elevation: 10,
        indicatorColor: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE0F2FE),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Color(0xFF0EA5E9));
          }
          return IconThemeData(color: subtleColor);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0EA5E9),
            );
          }
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: subtleColor,
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => DagboekProvider(),
      child: Consumer<DagboekProvider>(
        builder: (context, provider, _) {
          return MaterialApp(
            title: 'TriggerTrace',
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('nl', 'NL'),
              Locale('en', 'US'),
            ],
            locale: const Locale('nl', 'NL'),
            theme: _buildTheme(Brightness.light),
            darkTheme: _buildTheme(Brightness.dark),
            themeMode: provider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: hasSubscription ? const HomeScreen() : const PaywallScreen(),
          );
        },
      ),
    );
  }
}
