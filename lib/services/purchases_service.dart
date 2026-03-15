import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'dart:io' if (dart.library.html) 'dart:io';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PurchasesService {
  static const String appleApiKey = 'appl_bmYbGPwCOZaCXrSGBpIwlOeLDmp';
  static const String googleApiKey = 'goog_JOUW_GOOGLE_API_KEY_HIER';

  static bool get _isSupported => !kIsWeb;

  static Future<void> init() async {
    if (!_isSupported) return;

    try {
      await Purchases.setLogLevel(LogLevel.debug);

      PurchasesConfiguration? configuration;

      if (Platform.isIOS) {
        configuration = PurchasesConfiguration(appleApiKey);
      } else if (Platform.isAndroid) {
        configuration = PurchasesConfiguration(googleApiKey);
      }

      if (configuration != null) {
        await Purchases.configure(configuration);
      }
    } catch (e) {
      debugPrint('PurchasesService.init error: $e');
    }
  }

  static Future<bool> hasActiveSubscription() async {
    if (!_isSupported) return false;
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all['Triggertrace Pro']?.isActive ?? false;
    } on PlatformException catch (e) {
      debugPrint('hasActiveSubscription error: $e');
      return false;
    }
  }

  static Future<List<Package>> getOfferings({int retries = 3}) async {
    if (!_isSupported) return [];
    for (int attempt = 1; attempt <= retries; attempt++) {
      try {
        Offerings offerings = await Purchases.getOfferings();
        if (offerings.current != null &&
            offerings.current!.availablePackages.isNotEmpty) {
          return offerings.current!.availablePackages;
        }
        debugPrint('getOfferings attempt $attempt: no packages available');
      } on PlatformException catch (e) {
        debugPrint('getOfferings attempt $attempt error: $e');
      }
      if (attempt < retries) {
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
    return [];
  }

  static Future<bool> purchasePackage(Package package) async {
    if (!_isSupported) return false;
    try {
      // ignore: deprecated_member_use
      PurchaseResult result = await Purchases.purchasePackage(package);
      return result.customerInfo.entitlements.all['Triggertrace Pro']?.isActive ?? false;
    } on PlatformException catch (e) {
      debugPrint('purchasePackage error: $e');
      return false;
    }
  }

  static Future<bool> restorePurchases() async {
    if (!_isSupported) return false;
    try {
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      return customerInfo.entitlements.all['Triggertrace Pro']?.isActive ?? false;
    } on PlatformException catch (e) {
      debugPrint('restorePurchases error: $e');
      return false;
    }
  }
}
