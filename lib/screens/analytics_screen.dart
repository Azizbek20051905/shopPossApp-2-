import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/app_header.dart';
import '../services/analytics_service.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  bool _isLoading = true;
  String _selectedFilter = 'Month';
  Map<String, dynamic>? _data;

  // Design Colors
  static const Color primaryColor = Color(0xFF2FA7A4);
  static const Color bgColor = Color(0xFFF5F7F9);
  static const Color textColor = Color(0xFF2C3E50);
  static const Color secondaryTextColor = Color(0xFF8A97A5);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _analyticsService.fetchAnalytics();
      if (mounted) {
        setState(() {
          _data = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppHeader(
        title: 'ANALYTICS',
        trailing: GestureDetector(
          onTap: _loadData,
          child: const Icon(Icons.refresh, color: textColor, size: 24),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: primaryColor))
        : SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SECTION 1: DATE FILTER
                _buildDateFilter(),
                const SizedBox(height: 24),

                // SECTION 2: KPI CARDS
                _buildKPIGrid(),
                const SizedBox(height: 24),

                // SECTION 3: SALES CHART
                _buildChartSection('Sales Trend', _buildLineChart()),
                const SizedBox(height: 24),

                // SECTION 5: CATEGORY DISTRIBUTION
                _buildChartSection('Category Distribution', _buildPieChart()),
                const SizedBox(height: 24),

                // SECTION 4: TOP PRODUCTS
                _buildSectionTitle('Top Selling Products'),
                const SizedBox(height: 12),
                _buildTopProductsList(),
                const SizedBox(height: 24),

                // SECTION 6: RECENT SALES
                _buildSectionTitle('Recent Sales'),
                const SizedBox(height: 12),
                _buildRecentSalesList(),
                const SizedBox(height: 32),
              ],
            ),
          ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: textColor),
    );
  }

  Widget _buildDateFilter() {
    final filters = ['Today', 'Week', 'Month', 'Year', 'Custom'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = f),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? primaryColor : const Color(0xFFF4F6F8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                f,
                style: TextStyle(
                  color: isSelected ? Colors.white : secondaryTextColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKPIGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _buildKPICard('Revenue', '1,240,000', Icons.payments_outlined, primaryColor),
        _buildKPICard('Profit', '320,000', Icons.trending_up, Colors.green),
        _buildKPICard('Orders', '84', Icons.shopping_cart_outlined, Colors.orange),
        _buildKPICard('Avg Order', '14,760', Icons.calculate_outlined, Colors.blue),
      ],
    );
  }

  Widget _buildKPICard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 20, color: color),
              const Icon(Icons.more_horiz, size: 16, color: secondaryTextColor),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor),
              ),
              Text(
                label,
                style: const TextStyle(color: secondaryTextColor, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(String title, Widget chart) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(title),
          const SizedBox(height: 20),
          SizedBox(height: 220, child: chart),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const style = TextStyle(color: secondaryTextColor, fontSize: 10, fontWeight: FontWeight.bold);
                switch (value.toInt()) {
                  case 1: return const Text('Mon', style: style);
                  case 3: return const Text('Wed', style: style);
                  case 5: return const Text('Fri', style: style);
                  case 7: return const Text('Sun', style: style);
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              const FlSpot(0, 3),
              const FlSpot(1, 4),
              const FlSpot(2, 3.5),
              const FlSpot(3, 5),
              const FlSpot(4, 4.5),
              const FlSpot(5, 6),
              const FlSpot(6, 5.5),
            ],
            isCurved: true,
            color: primaryColor,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: primaryColor.withAlpha(51),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    return PieChart(
      PieChartData(
        sectionsSpace: 0,
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(color: primaryColor, value: 40, title: '40%', radius: 50, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
          PieChartSectionData(color: Colors.orange, value: 30, title: '30%', radius: 50, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
          PieChartSectionData(color: Colors.blue, value: 15, title: '15%', radius: 50, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
          PieChartSectionData(color: Colors.grey[300]!, value: 15, title: '15%', radius: 50, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildTopProductsList() {
    final products = [
      {'name': 'Coca Cola 0.5', 'sold': '142', 'revenue': '710,000', 'color': Colors.red[100]},
      {'name': 'Orbit White', 'sold': '98', 'revenue': '490,000', 'color': Colors.blue[100]},
      {'name': 'Lays Classic', 'sold': '76', 'revenue': '912,000', 'color': Colors.yellow[100]},
    ];

    return Column(
      children: products.map((p) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: p['color'] as Color, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.inventory_2_outlined, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                  Text('${p['sold']} units sold', style: const TextStyle(color: secondaryTextColor, fontSize: 12)),
                ],
              ),
            ),
            Text('${p['revenue']} UZS', style: const TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildRecentSalesList() {
    final sales = [
      {'id': '#1024', 'items': '3', 'amount': '45,000', 'time': '2 mins ago'},
      {'id': '#1023', 'items': '1', 'amount': '12,000', 'time': '12 mins ago'},
      {'id': '#1022', 'items': '5', 'amount': '128,000', 'time': '25 mins ago'},
    ];

    return Column(
      children: sales.map((s) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s['id'] as String, style: const TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                Text('${s['items']} items', style: const TextStyle(color: secondaryTextColor, fontSize: 12)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${s['amount']} UZS', style: const TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 16)),
                Text(s['time'] as String, style: const TextStyle(color: secondaryTextColor, fontSize: 12)),
              ],
            ),
          ],
        ),
      )).toList(),
    );
  }
}
