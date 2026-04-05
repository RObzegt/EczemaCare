import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/purchases_service.dart';
import '../widgets/app_logo.dart';
import 'home_screen.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

enum _LoadState { loading, loaded, error }

class _PaywallScreenState extends State<PaywallScreen> {
  _LoadState _loadState = _LoadState.loading;
  bool _isPurchasing = false;
  List<Package> _packages = [];

  @override
  void initState() {
    super.initState();
    _fetchOffers();
  }

  Future<void> _fetchOffers() async {
    if (!mounted) return;
    setState(() => _loadState = _LoadState.loading);

    final packages = await PurchasesService.getOfferings(retries: 3);

    if (!mounted) return;
    setState(() {
      _packages = packages;
      _loadState = packages.isNotEmpty ? _LoadState.loaded : _LoadState.error;
    });
  }

  /// Returns the localized price string from the first available package,
  /// or null if no package is loaded yet.
  String? get _localizedPrice {
    if (_packages.isEmpty) return null;
    return _packages.first.storeProduct.priceString;
  }

  /// Returns the period unit label for display purposes.
  String get _periodLabel {
    if (_packages.isEmpty) return 'per maand';
    final period = _packages.first.storeProduct.subscriptionPeriod;
    if (period == null) return 'per maand';
    if (period.contains('M')) return 'per maand';
    if (period.contains('Y')) return 'per jaar';
    if (period.contains('W')) return 'per week';
    return 'per maand';
  }

  Future<void> _handleSubscribe() async {
    if (_packages.isEmpty) return;
    setState(() => _isPurchasing = true);

    final outcome = await PurchasesService.purchasePackage(_packages.first);

    if (!mounted) return;

    if (outcome == PurchaseOutcome.success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
      return;
    }

    if (outcome == PurchaseOutcome.cancelled) {
      // User tapped Cancel in the payment sheet — reset silently.
      setState(() => _isPurchasing = false);
      return;
    }

    // Real error
    setState(() => _isPurchasing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Abonnement kon niet worden gestart. Probeer het opnieuw.'),
      ),
    );
  }

  Future<void> _restorePurchases() async {
    setState(() => _isPurchasing = true);
    final isSuccess = await PurchasesService.restorePurchases();
    if (!mounted) return;

    if (isSuccess) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      setState(() => _isPurchasing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geen actief abonnement gevonden.')),
      );
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const AppLogo(),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Icon(
                Icons.health_and_safety_outlined,
                size: 64,
                color: Color(0xFF6B8E5A),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ontgrendel Je Volledige Gezondheidsdagboek',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Krijg onbeperkt inzicht in je leefstijl, voeding en patronen.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),

              // ── PRICE BOX ──────────────────────────────────────────────
              _buildPriceBox(),
              // ── END PRICE BOX ──────────────────────────────────────────

              const SizedBox(height: 24),
              _buildSubscribeButton(),
              const SizedBox(height: 4),
              if (_loadState == _LoadState.loaded) ...[
                const Text(
                  'Eerste 7 dagen gratis — annuleer op elk moment',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              TextButton(
                onPressed: (_isPurchasing || _loadState == _LoadState.loading)
                    ? null
                    : _restorePurchases,
                child: const Text(
                  'Aankopen Herstellen',
                  style: TextStyle(
                    color: Color(0xFF6B8E5A),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              if (_loadState == _LoadState.loaded && _localizedPrice != null)
                Text(
                  'Een betaling van $_localizedPrice wordt in rekening gebracht op je Apple ID-account bij de bevestiging van de aankoop, na de gratis proefperiode van 7 dagen. Het abonnement wordt automatisch verlengd tenzij dit ten minste 24 uur voor het einde van de lopende periode wordt geannuleerd. Je kunt je abonnement op elk moment beheren in je Apple ID-instellingen.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                    height: 1.4,
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => _launchUrl(
                        'https://robzegt.github.io/EczemaCare/Privacy.html'),
                    child: const Text(
                      'Privacy Policy',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ),
                  const Text('|', style: TextStyle(color: Color(0xFF94A3B8))),
                  TextButton(
                    onPressed: () => _launchUrl(
                        'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/'),
                    child: const Text(
                      'Terms of Use',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceBox() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6B8E5A),
          width: 1.5,
        ),
      ),
      child: switch (_loadState) {
        _LoadState.loading => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: CircularProgressIndicator(
                color: Color(0xFF6B8E5A),
                strokeWidth: 2.5,
              ),
            ),
          ),
        _LoadState.error => Column(
            children: [
              const Icon(Icons.wifi_off_rounded,
                  color: Color(0xFF94A3B8), size: 32),
              const SizedBox(height: 8),
              const Text(
                'Abonnementsprijs kon niet worden geladen.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _fetchOffers,
                child: const Text(
                  'Opnieuw proberen',
                  style: TextStyle(
                    color: Color(0xFF6B8E5A),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        _LoadState.loaded => Column(
            children: [
              // PRIMARY: billed amount — largest, most prominent element
              Text(
                _localizedPrice ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                  height: 1.0,
                ),
              ),
              Text(
                _periodLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              // SUBORDINATE: free trial notice — smaller, lighter
              const Text(
                'inclusief 7 dagen gratis proefperiode',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
              const Text(
                'Daarna automatisch verlengd tenzij je opzegt.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
      },
    );
  }

  Widget _buildSubscribeButton() {
    final bool canSubscribe =
        !_isPurchasing && _loadState == _LoadState.loaded && _packages.isNotEmpty;

    return ElevatedButton(
      onPressed: canSubscribe ? _handleSubscribe : null,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: const Color(0xFF6B8E5A),
        disabledBackgroundColor: const Color(0xFF6B8E5A).withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: _isPurchasing
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(
              _loadState == _LoadState.loaded && _localizedPrice != null
                  ? 'Abonneer — $_localizedPrice/$_periodLabel'
                  : 'Abonneren',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
    );
  }
}
