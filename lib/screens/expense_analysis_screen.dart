import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/database_helper.dart';

class ExpenseAnalysisScreen extends StatefulWidget {
  const ExpenseAnalysisScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ExpenseAnalysisScreenState createState() => _ExpenseAnalysisScreenState();
}

class _ExpenseAnalysisScreenState extends State<ExpenseAnalysisScreen> {
  Map<String, double> expenseCategories = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExpenseData();
  }

  Future<void> _loadExpenseData() async {
    final db = await DatabaseHelper.initializeDatabase();
    final expenseRows = await db.query(
      'transactions',
      where: 'type = ?',
      whereArgs: ['Expense'],
    );

    Map<String, double> categoryTotals = {};
    for (var row in expenseRows) {
      final category = row['category'] as String;
      final amount = row['amount'] as double;
      categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
    }

    setState(() {
      expenseCategories = categoryTotals;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Analysis'),
        backgroundColor: Colors.red,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : expenseCategories.isEmpty
              ? const Center(child: Text('No expense data available'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Expense Breakdown',
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
    final total = expenseCategories.values.reduce((a, b) => a + b);
    final sections = expenseCategories.entries.map((entry) {
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
    final barData = expenseCategories.entries.map((entry) {
      return BarChartGroupData(
        x: expenseCategories.keys.toList().indexOf(entry.key),
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
                return Text(expenseCategories.keys.toList()[index]);
              },
            ),
          ),
        ),
      )),
    );
  }

  Color _getCategoryColor(String category) {
    final colors = {
      'Food': Colors.blue,
      'Transportation': Colors.green,
      'Housing': Colors.orange,
      'Utilities': Colors.purple,
      'Other': Colors.red,
    };
    return colors[category] ?? Colors.grey;
  }
}
