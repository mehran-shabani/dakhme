import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/database_helper.dart';

class IncomeAnalysisScreen extends StatefulWidget {
  const IncomeAnalysisScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _IncomeAnalysisScreenState createState() => _IncomeAnalysisScreenState();
}

class _IncomeAnalysisScreenState extends State<IncomeAnalysisScreen> {
  Map<String, double> incomeCategories = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIncomeData();
  }

  Future<void> _loadIncomeData() async {
    final db = await DatabaseHelper.initializeDatabase();
    final incomeRows = await db.query(
      'transactions',
      where: 'type = ?',
      whereArgs: ['Income'],
    );

    Map<String, double> categoryTotals = {};
    for (var row in incomeRows) {
      final category = row['category'] as String;
      final amount = row['amount'] as double;
      categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
    }

    setState(() {
      incomeCategories = categoryTotals;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Income Analysis'),
        backgroundColor: Colors.green,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : incomeCategories.isEmpty
              ? const Center(child: Text('No income data available'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Income Breakdown',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildPieChart(),
                      const SizedBox(height: 24),
                      _buildBarChart(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPieChart() {
    final total = incomeCategories.values.reduce((a, b) => a + b);
    final sections = incomeCategories.entries.map((entry) {
      return PieChartSectionData(
        color: _getCategoryColor(entry.key),
        value: entry.value,
        title: '${((entry.value / total) * 100).toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return SizedBox(
      height: 200,
      child: PieChart(PieChartData(sections: sections, centerSpaceRadius: 40)),
    );
  }

  Widget _buildBarChart() {
    final barData = incomeCategories.entries.map((entry) {
      return BarChartGroupData(
        x: incomeCategories.keys.toList().indexOf(entry.key),
        barRods: [
          BarChartRodData(
            toY: entry.value,
            color: _getCategoryColor(entry.key),
            width: 16,
          ),
        ],
      );
    }).toList();

    return SizedBox(
      height: 200,
      child: BarChart(BarChartData(
        barGroups: barData,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                return Text(incomeCategories.keys.toList()[index]);
              },
            ),
          ),
        ),
      )),
    );
  }

  Color _getCategoryColor(String category) {
    final colors = {
      'Salary': Colors.blue,
      'Business': Colors.green,
      'Investments': Colors.orange,
      'Freelance': Colors.purple,
      'Other': Colors.red,
    };
    return colors[category] ?? Colors.grey;
  }
}
