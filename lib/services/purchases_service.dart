import 'dart:io';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PurchasesService {
  // TODO: Vervang deze door jouw echte RevenueCat Public API Keys
  static const String appleApiKey = 'appl_JOUW_APPLE_API_KEY_HIER';
  static const String googleApiKey = 'goog_JOUW_GOOGLE_API_KEY_HIER';

  static Future<void> init() async {
    await Purchases.setLogLevel(LogLevel.debug);

    PurchasesConfiguration? configuration;

    if (Platform.isIOS) {
      configuration = PurchasesConfiguration(appleApiKey);
    } else if (Platform.isAndroid) {
      // Optioneel voor later: Play Store
      configuration = PurchasesConfiguration(googleApiKey);
    }

    if (configuration != null) {
      await Purchases.configure(configuration);
    }
  }

  static Future<bool> hasActiveSubscription() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      // 'premium' is de naam van de entitlement die je in RevenueCat instelt
      return customerInfo.entitlements.all['premium']?.isActive ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  static Future<List<Package>> getOfferings() async {
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
    try {
      CustomerInfo customerInfo = await Purchases.purchasePackage(package);
      return customerInfo.entitlements.all['premium']?.isActive ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  static Future<bool> restorePurchases() async {
    try {
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      return customerInfo.entitlements.all['premium']?.isActive ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }
}
