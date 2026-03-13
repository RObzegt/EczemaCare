import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' if (dart.library.html) 'dart:io';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PurchasesService {
  // TODO: Vervang deze door jouw echte RevenueCat Public API Keys
  static const String appleApiKey = 'appl_bmYbGPwCOZaCXrSGBpIwlOeLDmp';
  static const String googleApiKey = 'goog_JOUW_GOOGLE_API_KEY_HIER';

  static bool get _isSupported => !kIsWeb;

  static Future<void> init() async {
    if (!_isSupported) return;

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
  }

  static Future<bool> hasActiveSubscription() async {
    if (!_isSupported) return false;
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all['Triggertrace Pro']?.isActive ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  static Future<List<Package>> getOfferings() async {
    if (!_isSupported) return [];
    try {
      Offerings offerings = await Purchases.getOfferings();
      if (offerings.current != null) {
        return offerings.current!.availablePackages;
      }
      return [];
    } on PlatformException catch (_) {
      return [];
    }
  }

  static Future<bool> purchasePackage(Package package) async {
    if (!_isSupported) return false;
    try {
      // ignore: deprecated_member_use
      PurchaseResult result = await Purchases.purchasePackage(package);
      return result.customerInfo.entitlements.all['Triggertrace Pro']?.isActive ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  static Future<bool> restorePurchases() async {
    if (!_isSupported) return false;
    try {
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      return customerInfo.entitlements.all['Triggertrace Pro']?.isActive ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }
}
