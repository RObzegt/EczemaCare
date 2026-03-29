import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'dart:io' if (dart.library.html) 'dart:io';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Outcome of a [PurchasesService.purchasePackage] call.
enum PurchaseOutcome {
  /// The purchase completed successfully and the entitlement is now active.
  success,

  /// The user cancelled the Apple/Google payment sheet — no error should be shown.
  cancelled,

  /// A real error occurred (network failure, billing unavailable, etc.).
  error,
}

class PurchasesService {
  static const String appleApiKey = String.fromEnvironment(
    'REVENUECAT_APPLE_KEY',
    defaultValue: 'appl_bmYbGPwCOZaCXrSGBpIwlOeLDmp',
  );
  static const String googleApiKey = String.fromEnvironment(
    'REVENUECAT_GOOGLE_KEY',
    defaultValue: 'goog_JOUW_GOOGLE_API_KEY_HIER',
  );

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
      final CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all['premium']?.isActive ?? false;
    } on PlatformException catch (e) {
      debugPrint('hasActiveSubscription error: $e');
      return false;
    }
  }

  static Future<List<Package>> getOfferings({int retries = 3}) async {
    if (!_isSupported) return [];
    for (int attempt = 1; attempt <= retries; attempt++) {
      try {
        final Offerings offerings = await Purchases.getOfferings();
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

  /// Attempts to purchase [package].
  ///
  /// Returns [PurchaseOutcome.success] if the entitlement becomes active,
  /// [PurchaseOutcome.cancelled] if the user dismissed the payment sheet,
  /// or [PurchaseOutcome.error] for any other failure.
  static Future<PurchaseOutcome> purchasePackage(Package package) async {
    if (!_isSupported) return PurchaseOutcome.error;
    try {
      // ignore: deprecated_member_use
      final PurchaseResult result = await Purchases.purchasePackage(package);
      final bool active =
          result.customerInfo.entitlements.all['premium']?.isActive ??
              false;
      return active ? PurchaseOutcome.success : PurchaseOutcome.error;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        debugPrint('purchasePackage: user cancelled');
        return PurchaseOutcome.cancelled;
      }
      debugPrint('purchasePackage error: $e');
      return PurchaseOutcome.error;
    }
  }

  static Future<bool> restorePurchases() async {
    if (!_isSupported) return false;
    try {
      final CustomerInfo customerInfo = await Purchases.restorePurchases();
      return customerInfo.entitlements.all['premium']?.isActive ?? false;
    } on PlatformException catch (e) {
      debugPrint('restorePurchases error: $e');
      return false;
    }
  }
}
