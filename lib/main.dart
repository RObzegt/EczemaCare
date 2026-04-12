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

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6B8E5A), // TriggerTrace sage green
      primary: const Color(0xFF6B8E5A),
      secondary: const Color(0xFF8FAF7E), // Light sage accent
      tertiary: const Color(0xFFF43F5E), // Rose for warnings
      brightness: Brightness.light,
    );

    return ChangeNotifierProvider(
      create: (context) => DagboekProvider(),
      child: MaterialApp(
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
        theme: ThemeData(
          colorScheme: colorScheme,
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF1F5F9), // Medical grey background
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF1E293B),
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.w700, 
              color: Color(0xFF1E293B),
              letterSpacing: -0.5,
            ),
            iconTheme: IconThemeData(color: Color(0xFF64748B)),
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 2,
            shadowColor: const Color(0x1A000000),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFF1F5F9)),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFF1F5F9),
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
            backgroundColor: const Color(0xFFF1F5F9),
            selectedColor: const Color(0xFFE0F2FE),
            labelStyle: const TextStyle(
              color: Color(0xFF334155), 
              fontSize: 12, 
              fontWeight: FontWeight.w500
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            side: BorderSide.none,
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: Colors.white,
            elevation: 10,
            indicatorColor: const Color(0xFFE0F2FE),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const IconThemeData(color: Color(0xFF0EA5E9));
              }
              return const IconThemeData(color: Color(0xFF94A3B8));
            }),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const TextStyle(
                  fontSize: 12, 
                  fontWeight: FontWeight.w700, 
                  color: Color(0xFF0EA5E9)
                );
              }
              return const TextStyle(
                fontSize: 12, 
                fontWeight: FontWeight.w500, 
                color: Color(0xFF94A3B8)
              );
            }),
          ),
        ),
        home: hasSubscription ? const HomeScreen() : const PaywallScreen(),
      ),
    );
  }
}
