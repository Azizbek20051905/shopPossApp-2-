import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../widgets/app_header.dart';
import '../services/analytics_service.dart';
import '../widgets/app_drawer.dart';

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

  final NumberFormat _fmt = NumberFormat('#,###');

  // Design Colors
  static const Color primaryColor = Color(0xFF2FA7A4);
  static const Color bgColor = Color(0xFFF5F7F9);
  static const Color textColor = Color(0xFF2C3E50);
  static const Color secondaryTextColor = Color(0xFF8A97A5);

  // Map UI filter name → API period param
  static const _periodMap = {
    'Today': 'today',
    'Week': 'week',
    'Month': 'month',
    'Year': 'year',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final period = _periodMap[_selectedFilter] ?? 'month';
      final res = await _analyticsService.fetchAnalytics(period: period);
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

  // Helpers
  double get _revenue => (_data?['revenue'] as num?)?.toDouble() ?? 0;
  double get _profit => (_data?['profit'] as num?)?.toDouble() ?? 0;
  int get _orders => (_data?['orders'] as num?)?.toInt() ?? 0;
  double get _avgOrder => (_data?['avg_order'] as num?)?.toDouble() ?? 0;

  List<Map<String, dynamic>> get _trend =>
      (_data?['trend'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  List<Map<String, dynamic>> get _categories =>
      (_data?['categories'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  List<Map<String, dynamic>> get _topProducts =>
      (_data?['top_products'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  List<Map<String, dynamic>> get _recentSales =>
      (_data?['recent_sales'] as List?)?.cast<Map<String, dynamic>>() ?? [];

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
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: primaryColor,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: primaryColor))
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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

                    // SECTION 4: CATEGORY DISTRIBUTION
                    _buildChartSection('Category Distribution', _buildPieChartWithLegend()),
                    const SizedBox(height: 24),

                    // SECTION 5: TOP PRODUCTS
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
    final filters = _periodMap.keys.toList();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f;
          return GestureDetector(
            onTap: () {
              if (_selectedFilter != f) {
                setState(() => _selectedFilter = f);
                _loadData();
              }
            },
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
        _buildKPICard('Revenue', '${_fmt.format(_revenue)} UZS', Icons.payments_outlined, primaryColor),
        _buildKPICard('Profit', '${_fmt.format(_profit)} UZS', Icons.trending_up, Colors.green),
        _buildKPICard('Orders', _orders.toString(), Icons.shopping_cart_outlined, Colors.orange),
        _buildKPICard('Avg Order', '${_fmt.format(_avgOrder)} UZS', Icons.calculate_outlined, Colors.blue),
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
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor),
                ),
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
          chart,
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    if (_trend.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('No data for this period', style: TextStyle(color: secondaryTextColor))),
      );
    }

    final spots = <FlSpot>[];
    double maxY = 0;
    for (int i = 0; i < _trend.length; i++) {
      final rev = (_trend[i]['revenue'] as num).toDouble();
      spots.add(FlSpot(i.toDouble(), rev));
      if (rev > maxY) maxY = rev;
    }

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY * 1.2,
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (_trend.length > 7) ? (_trend.length / 5).roundToDouble() : 1,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= _trend.length) return const Text('');
                  final dateStr = _trend[idx]['date'] as String;
                  try {
                    final d = DateTime.parse(dateStr);
                    return Text(
                      '${d.month}/${d.day}',
                      style: const TextStyle(color: secondaryTextColor, fontSize: 9),
                    );
                  } catch (_) {
                    return const Text('');
                  }
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: primaryColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: spots.length <= 7),
              belowBarData: BarAreaData(
                show: true,
                color: primaryColor.withAlpha(40),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Pie chart colours (cycle if more categories)
  static const _pieColors = [primaryColor, Colors.orange, Colors.blue, Colors.purple, Colors.red, Colors.green];

  Widget _buildPieChartWithLegend() {
    if (_categories.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('No category data', style: TextStyle(color: secondaryTextColor))),
      );
    }

    final sections = <PieChartSectionData>[];
    for (int i = 0; i < _categories.length; i++) {
      final cat = _categories[i];
      final pct = (cat['percent'] as num).toDouble();
      final color = _pieColors[i % _pieColors.length];
      sections.add(PieChartSectionData(
        color: color,
        value: pct,
        title: '${pct.toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
      ));
    }

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(PieChartData(sectionsSpace: 2, centerSpaceRadius: 36, sections: sections)),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: List.generate(_categories.length, (i) {
            final cat = _categories[i];
            final color = _pieColors[i % _pieColors.length];
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text('${cat['category']}', style: const TextStyle(fontSize: 12, color: textColor)),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTopProductsList() {
    if (_topProducts.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('No top products data', style: TextStyle(color: secondaryTextColor)),
      ));
    }

    final productColors = [Colors.red[100]!, Colors.blue[100]!, Colors.yellow[100]!, Colors.green[100]!, Colors.purple[100]!];
    return Column(
      children: List.generate(_topProducts.length, (index) {
        final p = _topProducts[index];
        final name = p['name'] as String? ?? 'Unknown';
        final units = (p['units'] as num?)?.toDouble() ?? 0;
        final revenue = (p['revenue'] as num?)?.toDouble() ?? 0;
        return Container(
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
                decoration: BoxDecoration(color: productColors[index % productColors.length], borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: textColor))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                    Text('${units % 1 == 0 ? units.toInt() : units.toStringAsFixed(2)} units sold', style: const TextStyle(color: secondaryTextColor, fontSize: 12)),
                  ],
                ),
              ),
              Text('${_fmt.format(revenue)} UZS', style: const TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 13)),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildRecentSalesList() {
    if (_recentSales.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('No recent sales', style: TextStyle(color: secondaryTextColor)),
      ));
    }

    return Column(
      children: _recentSales.map((s) {
        final id = s['id'];
        final total = (s['total'] as num?)?.toDouble() ?? 0;
        final items = s['items'] as int? ?? 0;
        final createdAt = s['created_at'] as String? ?? '';

        String timeAgo = '';
        try {
          final dt = DateTime.parse(createdAt);
          final diff = DateTime.now().difference(dt);
          if (diff.inDays > 0) {
            timeAgo = '${diff.inDays}d ago';
          } else if (diff.inHours > 0) {
            timeAgo = '${diff.inHours}h ago';
          } else if (diff.inMinutes > 0) {
            timeAgo = '${diff.inMinutes}m ago';
          } else {
            timeAgo = 'Just now';
          }
        } catch (_) {}

        return Container(
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
                  Text('Order #$id', style: const TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                  Text('$items items', style: const TextStyle(color: secondaryTextColor, fontSize: 12)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${_fmt.format(total)} UZS', style: const TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 16)),
                  Text(timeAgo, style: const TextStyle(color: secondaryTextColor, fontSize: 12)),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
