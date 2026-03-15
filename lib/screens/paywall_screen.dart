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

class _PaywallScreenState extends State<PaywallScreen> {
  bool _isPurchasing = false;
  List<Package> _packages = [];

  @override
  void initState() {
    super.initState();
    _fetchOffers();
  }

  Future<void> _fetchOffers() async {
    final packages = await PurchasesService.getOfferings(retries: 3);
    if (mounted) {
      setState(() {
        _packages = packages;
      });
    }
  }

  Future<void> _handleSubscribe() async {
    setState(() => _isPurchasing = true);

    if (_packages.isEmpty) {
      final packages = await PurchasesService.getOfferings(retries: 2);
      if (mounted) {
        setState(() => _packages = packages);
      }
    }

    if (_packages.isNotEmpty) {
      final isSuccess = await PurchasesService.purchasePackage(_packages.first);
      if (isSuccess && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
        return;
      }
    }

    if (mounted) {
      setState(() => _isPurchasing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Abonnement kon niet worden gestart. Probeer het opnieuw.'),
        ),
      );
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isPurchasing = true);
    final isSuccess = await PurchasesService.restorePurchases();
    if (isSuccess && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      if (mounted) {
        setState(() => _isPurchasing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Geen actief abonnement gevonden.')),
        );
      }
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
              const SizedBox(height: 40),
              const Icon(
                Icons.health_and_safety_outlined,
                size: 80,
                color: Color(0xFF6B8E5A),
              ),
              const SizedBox(height: 24),
              const Text(
                'Ontgrendel Je Volledige Gezondheidsdagboek',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Krijg onbeperkt inzicht in je leefstijl, voeding en patronen. Start nu zorgeloos met een gratis proefperiode.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Column(
                  children: [
                    Text(
                      'TriggerTrace Premium',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Maandelijks abonnement',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '7 dagen gratis proefperiode, daarna €5,99/maand',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B8E5A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isPurchasing ? null : _handleSubscribe,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF6B8E5A),
                  disabledBackgroundColor: const Color(0xFF6B8E5A).withValues(alpha: 0.5),
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
                    : const Text(
                        'Start 7 Dagen Gratis',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _isPurchasing ? null : _restorePurchases,
                child: const Text(
                  'Aankopen Herstellen',
                  style: TextStyle(
                    color: Color(0xFF6B8E5A),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Een betaling wordt in rekening gebracht op je Apple ID-account bij de bevestiging van de aankoop. Het abonnement wordt automatisch verlengd tenzij dit ten minste 24 uur voor het einde van de lopende periode wordt geannuleerd. Je kunt je abonnement op elk moment beheren in je Apple ID-instellingen.',
                textAlign: TextAlign.center,
                style: TextStyle(
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
                    onPressed: () => _launchUrl('https://robzegt.github.io/EczemaCare/Privacy.html'),
                    child: const Text(
                      'Privacy Policy',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ),
                  const Text('|', style: TextStyle(color: Color(0xFF94A3B8))),
                  TextButton(
                    onPressed: () => _launchUrl('https://www.apple.com/legal/internet-services/itunes/dev/stdeula/'),
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
}
