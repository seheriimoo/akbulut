import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../billing/billing_catalog.dart';
import '../billing/billing_service.dart';
import '../billing/subscription_disclosure.dart';
import 'compliance/legal_document_screen.dart';

/// Production paywall backed by live RevenueCat offerings.
///
/// Prices and trial copy come from the store product — never hardcoded.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final BillingService _billing = BillingService.instance;

  bool _loading = true;
  bool _busy = false;
  String? _error;
  List<Package> _packages = const [];
  Package? _selected;
  bool _alreadyPremium = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (!_billing.isConfigured) {
        setState(() {
          _loading = false;
          _error = 'Purchases are not configured for this build.';
        });
        return;
      }

      final premium = await _billing.hasPremiumEntitlement();
      final packages = await _billing.loadPackages();

      if (!mounted) return;

      setState(() {
        _alreadyPremium = premium;
        _packages = packages;
        _selected = BillingCatalog.preferredPackage(packages);
        _loading = false;
        if (packages.isEmpty && !premium) {
          _error =
              'No live offerings are available yet. Confirm RevenueCat '
              'offering "${BillingCatalog.offeringId}" is Current and products '
              '${BillingCatalog.premiumProductIds.join(", ")} are attached.';
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load offerings. Please try again.';
      });
    }
  }

  Future<void> _purchase() async {
    final package = _selected;
    if (package == null || _busy) return;

    setState(() => _busy = true);
    try {
      final info = await _billing.purchasePackageWithBoundedWait(package);
      if (!mounted) return;

      final premium = await _billing.resolvePremiumAfterPurchase(info);
      if (!mounted) return;

      if (premium) {
        Navigator.pop(context, true);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Purchase completed. Premium may take a moment — tap Restore '
            'purchases or reopen Nocta.',
          ),
        ),
      );
    } on BillingException catch (error) {
      if (!mounted) return;
      if (error.code == BillingErrorCode.cancelled) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase failed. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final info = await _billing.restorePurchases();
      if (!mounted) return;
      if (_billing.customerHasPremium(info)) {
        Navigator.pop(context, true);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No premium purchases found to restore.')),
      );
    } on BillingException catch (error) {
      if (!mounted) return;
      if (error.code == BillingErrorCode.cancelled) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restore failed. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _priceLabel(Package package) {
    return package.storeProduct.priceString;
  }

  String _titleLabel(Package package) {
    final title = package.storeProduct.title.trim();
    if (title.isNotEmpty) return title;
    return package.identifier;
  }

  String _ctaLabel(Package package) {
    final intro = package.storeProduct.introductoryPrice;
    if (intro != null) {
      return 'Start free trial';
    }
    return 'Subscribe';
  }

  String? _introLabel(Package package) {
    final intro = package.storeProduct.introductoryPrice;
    if (intro == null) return null;
    final period = intro.periodUnit.name;
    return '${intro.priceString} for ${intro.periodNumberOfUnits} $period intro';
  }

  String _lengthLabel(Package package) {
    switch (package.packageType) {
      case PackageType.monthly:
        return '1 month';
      case PackageType.annual:
        return '1 year';
      case PackageType.weekly:
        return '1 week';
      default:
        return 'auto-renewing subscription';
    }
  }

  void _openLegal(LegalDocumentKind kind) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LegalDocumentScreen(kind: kind),
      ),
    );
  }

  Widget _subscriptionLegalFooter() {
    return Column(
      children: [
        Text(
          SubscriptionDisclosure.autoRenewTerms,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 11,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          children: [
            TextButton(
              onPressed: _busy
                  ? null
                  : () => _openLegal(LegalDocumentKind.privacyPolicy),
              child: Text(
                SubscriptionDisclosure.privacyLinkLabel,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white.withValues(alpha: 0.35),
                ),
              ),
            ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => _openLegal(LegalDocumentKind.termsOfService),
              child: Text(
                SubscriptionDisclosure.termsLinkLabel,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white.withValues(alpha: 0.35),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090B12),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: SingleChildScrollView(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.pop(context, false),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Every night your mind is still awake',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'A conversation that leads into sleep — whenever you need it.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              const _FeatureCard(
                icon: Icons.nights_stay_rounded,
                title: 'Return any night',
                subtitle:
                    'Keep using Nocta on the nights your mind will not settle.',
              ),
              const SizedBox(height: 14),
              const _FeatureCard(
                icon: Icons.psychology_alt_rounded,
                title: 'The same night conversation',
                subtitle:
                    'Full conversation every night you use Nocta — not a lesser version.',
              ),
              const SizedBox(height: 14),
              const _FeatureCard(
                icon: Icons.auto_awesome_rounded,
                title: 'Conversation into sleep',
                subtitle:
                    'Talk, let go, and move into rest when you are ready.',
              ),
              const SizedBox(height: 28),
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                )
              else if (_alreadyPremium) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: const Text(
                    'Premium is already active on this Apple ID.',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF090B12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ] else if (_error != null) ...[
                Text(
                  _error!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _busy ? null : _load,
                  child: const Text('Retry'),
                ),
              ] else ...[
                ..._packages.map((package) {
                  final selected =
                      _selected?.identifier == package.identifier;
                  final intro = _introLabel(package);
                  final recommended = BillingCatalog.isYearlyProduct(
                    package.storeProduct.identifier,
                  );
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: _busy
                          ? null
                          : () => setState(() => _selected = package),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: selected
                                ? Colors.white.withValues(alpha: 0.35)
                                : Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _titleLabel(package),
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.72),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (recommended)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Text(
                                      'Recommended',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_priceLabel(package)} · ${_lengthLabel(package)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.4,
                              ),
                            ),
                            if (intro != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                intro,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.68),
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: _busy || _selected == null ? null : _purchase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF090B12),
                      disabledBackgroundColor:
                          Colors.white.withValues(alpha: 0.35),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      _busy
                          ? 'Please wait…'
                          : _ctaLabel(_selected ?? _packages.first),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: _busy ? null : _restore,
                    child: Text(
                      'Restore purchases',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.66),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _subscriptionLegalFooter(),
            ],
          ),
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.66),
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
