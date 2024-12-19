import 'package:dakhme/screens/income_analysis_screen.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/database_helper.dart';
import 'expense_analysis_screen.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<FlSpot> incomeData = [];
  List<FlSpot> expenseData = [];
  Map<String, double> expenseCategories = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final db = await DatabaseHelper.initializeDatabase();

    // Fetch income data
    final incomeRows = await db.query(
      'transactions',
      where: 'type = ?',
      whereArgs: ['Income'],
    );

    // Fetch expense data
    final expenseRows = await db.query(
      'transactions',
      where: 'type = ?',
      whereArgs: ['Expense'],
    );

    // Process income data for chart
    List<FlSpot> incomeChartData = [];
    for (var i = 0; i < incomeRows.length; i++) {
      final amount = incomeRows[i]['amount'] as double;
      incomeChartData.add(FlSpot(i.toDouble(), amount));
    }

    // Process expense data for chart and categories
    List<FlSpot> expenseChartData = [];
    Map<String, double> expenseBreakdown = {};

    for (var i = 0; i < expenseRows.length; i++) {
      final amount = expenseRows[i]['amount'] as double;
      final category = expenseRows[i]['category'] as String;

      expenseChartData.add(FlSpot(i.toDouble(), amount));
      expenseBreakdown[category] = (expenseBreakdown[category] ?? 0) + amount;
    }

    // Update the state with new data
    setState(() {
      incomeData = incomeChartData;
      expenseData = expenseChartData;
      expenseCategories = expenseBreakdown;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Financial Analysis',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Income'),
            Tab(text: 'Expenses'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          const IncomeAnalysisScreen(), // صفحه درآمد
    const ExpenseAnalysisScreen(), // صفحه مخارج
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(),
          const SizedBox(height: 24),
          _buildLineChart(),
          const SizedBox(height: 24),
          _buildPieChart(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final totalIncome = incomeData.fold(0.0, (sum, item) => sum + item.y);
    final totalExpenses = expenseData.fold(0.0, (sum, item) => sum + item.y);

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Income',
            '₹${totalIncome.toStringAsFixed(0)}',
            Colors.green,
            Icons.arrow_upward,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Total Expense',
            '₹${totalExpenses.toStringAsFixed(0)}',
            Colors.red,
            Icons.arrow_downward,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String amount, Color color, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              amount,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

 Widget _buildLineChart() {
  if (incomeData.isEmpty && expenseData.isEmpty) {
    return const Center(
      child: Text('No data available to display.'),
    );
  }

  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                        if (value >= 0 && value < months.length) {
                          return Text(months[value.toInt()]);
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: incomeData,
                    isCurved: true,
                    color: Colors.green,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: expenseData,
                    isCurved: true,
                    color: Colors.red,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}


  Widget _buildPieChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Expense Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _generatePieSections(),
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _generatePieSections() {
    final total = expenseCategories.values.reduce((a, b) => a + b);
    return expenseCategories.entries.map((entry) {
      return PieChartSectionData(
        color: _getCategoryColor(entry.key),
        value: entry.value,
        title: '${((entry.value / total) * 100).toStringAsFixed(1)}%',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Color _getCategoryColor(String category) {
    final colors = {
      'Food': Colors.blue,
      'Transport': Colors.green,
      'Shopping': Colors.orange,
      'Bills': Colors.purple,
      'Entertainment': Colors.red,
    };
    return colors[category] ?? Colors.grey;
  }


}
