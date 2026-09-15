import 'package:flutter/material.dart';
import 'package:loob/models/affiliate_model.dart';

/// Affiliate marketing screen with zero-division protection.
class AffiliateScreen extends StatefulWidget {
  const AffiliateScreen({super.key});

  @override
  State<AffiliateScreen> createState() => _AffiliateScreenState();
}

class _AffiliateScreenState extends State<AffiliateScreen> {
  Affiliate? _affiliateData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAffiliateData();
  }

  @override
  void dispose() {
    // Clean up any listeners or timers
    super.dispose();
  }

  Future<void> _loadAffiliateData() async {
    try {
      setState(() => _isLoading = true);
      // Load affiliate data from your service
      // _affiliateData = await AffiliateService().getAffiliateData();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Calculate conversion rate with zero-division protection.
  double _calculateConversionRate(int conversions, int clicks) {
    if (clicks <= 0) return 0.0;
    return conversions / clicks;
  }

  /// Calculate earnings per click with zero-division protection.
  double _calculateEarningsPerClick(double earnings, int clicks) {
    if (clicks <= 0) return 0.0;
    return earnings / clicks;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('البرنامج التسويقي'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('خطأ: $_error'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatsCard(),
                      const SizedBox(height: 16),
                      _buildConversionCard(),
                      const SizedBox(height: 16),
                      _buildEarningsCard(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatsCard() {
    final data = _affiliateData;
    final clicks = data?.totalClicks ?? 0;
    final conversions = data?.totalConversions ?? 0;
    final earnings = data?.totalEarnings ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatRow('إجمالي النقرات', clicks.toString()),
            _buildStatRow('إجمالي التحويلات', conversions.toString()),
            _buildStatRow('إجمالي الأرباح', '${earnings.toStringAsFixed(2)} ر.س'),
            const Divider(),
            _buildStatRow(
              'معدل التحويل',
              '${(_calculateConversionRate(conversions, clicks) * 100).toStringAsFixed(2)}%',
            ),
            _buildStatRow(
              'الأرباح لكل نقرة',
              '${_calculateEarningsPerClick(earnings, clicks).toStringAsFixed(2)} ر.س',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversionCard() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'روابط التسويق',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            // Add your affiliate links here
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsCard() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الأرباح المعلقة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            // Add pending earnings details
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
