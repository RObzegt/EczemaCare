import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DebugHelper {
  static Future<void> printStorageData() async {
    debugPrint('=== DEBUG: CHECKING STORAGE ===');
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('dagboek_entries');
      
      if (data != null) {
        final parsed = jsonDecode(data) as List;
        debugPrint('Storage has ${parsed.length} entries');
        
        // Print first entry details
        if (parsed.isNotEmpty) {
          final firstEntry = parsed.first;
          debugPrint('First entry date: ${firstEntry['datum']}');
          
          if (firstEntry['gezondheidsMetrics'] != null && 
              (firstEntry['gezondheidsMetrics'] as List).isNotEmpty) {
            final metrics = (firstEntry['gezondheidsMetrics'] as List).first;
            debugPrint('  Eczeem Ernstig: ${metrics['eczeemErnstig']}');
            debugPrint('  Eczeem Mild: ${metrics['eczeemMild']}');
            debugPrint('  Geen Eczeem: ${metrics['geenEczeem']}');
            debugPrint('  Slaapkwaliteit: ${metrics['slaapKwaliteit']}');
          }
        }
      } else {
        debugPrint('NO DATA IN STORAGE!');
      }
    } catch (e) {
      debugPrint('ERROR checking storage: $e');
    }
    debugPrint('=== END DEBUG ===');
  }
}
