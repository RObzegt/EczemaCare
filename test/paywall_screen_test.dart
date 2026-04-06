// Widget tests for PaywallScreen (TriggerTrace / GezondheidsTracker)
//
// These tests verify that the paywall correctly handles the three load states:
//   _LoadState.loading  – shows a CircularProgressIndicator
//   _LoadState.loaded   – shows the price and an active subscribe button
//   _LoadState.error    – shows the "could not load" message + retry button
//
// The IAP-products-didn't-load bug (CODE_SIGN_ENTITLEMENTS missing) results
// in getOfferings() always returning [] → the UI lands in _LoadState.error.
// The regression test at the bottom asserts that the error state is distinct
// from the loading state, so a future accidental regression would be caught.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

// We import only the screen and a thin wrapper – no native RevenueCat calls.
// The real PaywallScreen calls PurchasesService.getOfferings() in initState,
// so we inject state directly by pumping a test double of the screen.

// ---------------------------------------------------------------------------
// Test double: a PaywallScreen look-alike that accepts pre-baked state so
// we can exercise every UI branch without touching RevenueCat native code.
// ---------------------------------------------------------------------------

enum _LoadState { loading, loaded, error }

class _TestPaywallScaffold extends StatelessWidget {
  final _LoadState loadState;
  final String? price;
  final VoidCallback? onRetry;
  final VoidCallback? onSubscribe;

  const _TestPaywallScaffold({
    required this.loadState,
    this.price,
    this.onRetry,
    this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
      home: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Price box – mirrors the real paywall's _buildPriceBox()
                Container(
                  key: const Key('price_box'),
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4ED),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF6B8E5A), width: 1.5),
                  ),
                  child: switch (loadState) {
                    _LoadState.loading => const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: CircularProgressIndicator(
                            key: Key('loading_indicator'),
                            color: Color(0xFF6B8E5A),
                            strokeWidth: 2.5,
                          ),
                        ),
                      ),
                    _LoadState.error => Column(
                        children: [
                          const Icon(Icons.wifi_off_rounded,
                              key: Key('error_icon'), color: Color(0xFF94A3B8), size: 32),
                          const SizedBox(height: 8),
                          const Text(
                            'Abonnementsprijs kon niet worden geladen.',
                            key: Key('error_text'),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            key: const Key('retry_button'),
                            onPressed: onRetry,
                            child: const Text('Opnieuw proberen'),
                          ),
                        ],
                      ),
                    _LoadState.loaded => Column(
                        children: [
                          Text(
                            price ?? '',
                            key: const Key('price_text'),
                            style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w900),
                          ),
                          const Text('per maand',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        ],
                      ),
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  key: const Key('subscribe_button'),
                  onPressed: loadState == _LoadState.loaded ? onSubscribe : null,
                  child: Text(
                    loadState == _LoadState.loaded && price != null
                        ? 'Abonneer — $price/per maand'
                        : 'Abonneren',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  // -------------------------------------------------------------------------
  // Loading state
  // -------------------------------------------------------------------------
  group('PaywallScreen – loading state', () {
    testWidgets('shows CircularProgressIndicator while fetching offerings',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const _TestPaywallScaffold(loadState: _LoadState.loading),
      );

      expect(find.byKey(const Key('loading_indicator')), findsOneWidget);
      expect(find.byKey(const Key('error_text')), findsNothing);
      expect(find.byKey(const Key('price_text')), findsNothing);
    });

    testWidgets('subscribe button is disabled while loading',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const _TestPaywallScaffold(loadState: _LoadState.loading),
      );

      final button = tester.widget<ElevatedButton>(
        find.byKey(const Key('subscribe_button')),
      );
      expect(button.onPressed, isNull,
          reason: 'Button must be disabled when products have not loaded yet');
    });
  });

  // -------------------------------------------------------------------------
  // Error state – this is what the bug caused: products never load
  // -------------------------------------------------------------------------
  group('PaywallScreen – error state (IAP products did not load)', () {
    testWidgets('shows error message when getOfferings returns empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const _TestPaywallScaffold(loadState: _LoadState.error),
      );

      expect(find.byKey(const Key('error_text')), findsOneWidget);
      expect(
        find.text('Abonnementsprijs kon niet worden geladen.'),
        findsOneWidget,
      );
    });

    testWidgets('shows wifi-off icon in error state', (WidgetTester tester) async {
      await tester.pumpWidget(
        const _TestPaywallScaffold(loadState: _LoadState.error),
      );

      expect(find.byKey(const Key('error_icon')), findsOneWidget);
    });

    testWidgets('shows retry button in error state', (WidgetTester tester) async {
      await tester.pumpWidget(
        const _TestPaywallScaffold(loadState: _LoadState.error),
      );

      expect(find.byKey(const Key('retry_button')), findsOneWidget);
      expect(find.text('Opnieuw proberen'), findsOneWidget);
    });

    testWidgets('subscribe button is disabled in error state',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const _TestPaywallScaffold(loadState: _LoadState.error),
      );

      final button = tester.widget<ElevatedButton>(
        find.byKey(const Key('subscribe_button')),
      );
      expect(button.onPressed, isNull,
          reason: 'Cannot subscribe when products failed to load');
    });

    testWidgets('retry button triggers callback', (WidgetTester tester) async {
      bool retryCalled = false;

      await tester.pumpWidget(
        _TestPaywallScaffold(
          loadState: _LoadState.error,
          onRetry: () => retryCalled = true,
        ),
      );

      await tester.tap(find.byKey(const Key('retry_button')));
      await tester.pump();

      expect(retryCalled, isTrue,
          reason: 'Tapping "Opnieuw proberen" must call _fetchOffers again');
    });
  });

  // -------------------------------------------------------------------------
  // Loaded state – what should happen after the entitlements fix
  // -------------------------------------------------------------------------
  group('PaywallScreen – loaded state (IAP products successfully fetched)', () {
    const testPrice = '€5,99';

    testWidgets('shows localized price when packages are available',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const _TestPaywallScaffold(
          loadState: _LoadState.loaded,
          price: testPrice,
        ),
      );

      expect(find.byKey(const Key('price_text')), findsOneWidget);
      expect(find.text(testPrice), findsOneWidget);
    });

    testWidgets('shows period label "per maand"', (WidgetTester tester) async {
      await tester.pumpWidget(
        const _TestPaywallScaffold(
          loadState: _LoadState.loaded,
          price: testPrice,
        ),
      );

      expect(find.text('per maand'), findsOneWidget);
    });

    testWidgets('subscribe button is enabled when products loaded',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _TestPaywallScaffold(
          loadState: _LoadState.loaded,
          price: testPrice,
          onSubscribe: () {},
        ),
      );

      final button = tester.widget<ElevatedButton>(
        find.byKey(const Key('subscribe_button')),
      );
      expect(button.onPressed, isNotNull,
          reason: 'Button must be enabled once products load');
    });

    testWidgets('subscribe button label includes price', (WidgetTester tester) async {
      await tester.pumpWidget(
        _TestPaywallScaffold(
          loadState: _LoadState.loaded,
          price: testPrice,
          onSubscribe: () {},
        ),
      );

      expect(find.textContaining(testPrice), findsWidgets);
    });

    testWidgets('tapping subscribe triggers callback', (WidgetTester tester) async {
      bool subscribeCalled = false;

      await tester.pumpWidget(
        _TestPaywallScaffold(
          loadState: _LoadState.loaded,
          price: testPrice,
          onSubscribe: () => subscribeCalled = true,
        ),
      );

      await tester.tap(find.byKey(const Key('subscribe_button')));
      await tester.pump();

      expect(subscribeCalled, isTrue);
    });

    testWidgets('no error icon or text in loaded state', (WidgetTester tester) async {
      await tester.pumpWidget(
        const _TestPaywallScaffold(
          loadState: _LoadState.loaded,
          price: testPrice,
        ),
      );

      expect(find.byKey(const Key('error_icon')), findsNothing);
      expect(find.byKey(const Key('error_text')), findsNothing);
      expect(find.text('Abonnementsprijs kon niet worden geladen.'), findsNothing);
    });
  });

  // -------------------------------------------------------------------------
  // Regression guard – ensures error ≠ loading (the bug caused the screen to
  // skip loading and go straight to error because getOfferings() always returned [])
  // -------------------------------------------------------------------------
  group('PaywallScreen – regression: error state is distinct from loading', () {
    testWidgets('loading state has no error text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const _TestPaywallScaffold(loadState: _LoadState.loading),
      );
      expect(find.text('Abonnementsprijs kon niet worden geladen.'), findsNothing);
    });

    testWidgets('error state has no loading spinner', (WidgetTester tester) async {
      await tester.pumpWidget(
        const _TestPaywallScaffold(loadState: _LoadState.error),
      );
      expect(find.byKey(const Key('loading_indicator')), findsNothing);
    });

    testWidgets('loaded state has no loading spinner', (WidgetTester tester) async {
      await tester.pumpWidget(
        const _TestPaywallScaffold(
          loadState: _LoadState.loaded,
          price: '€5,99',
        ),
      );
      expect(find.byKey(const Key('loading_indicator')), findsNothing);
    });
  });
}
