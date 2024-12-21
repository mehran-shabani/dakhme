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
  DateTime? _startDate;
  DateTime? _endDate;
  double? _minAmount;
  double? _maxAmount;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadExpenseData();
  }

  Future<void> _loadExpenseData() async {
    setState(() {
      isLoading = true;
    });

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
      final date = DateTime.parse(row['date'] as String);

      if ((_startDate == null || date.isAfter(_startDate!)) &&
          (_endDate == null || date.isBefore(_endDate!)) &&
          (_minAmount == null || amount >= _minAmount!) &&
          (_maxAmount == null || amount <= _maxAmount!) &&
          (_selectedCategory == null || category == _selectedCategory)) {
        categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
      }
    }

    setState(() {
      expenseCategories = categoryTotals;
      isLoading = false;
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadExpenseData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Analysis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _selectDateRange(context),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Expense Breakdown',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildFilters(),
                  const SizedBox(height: 16),
                  _buildPieChart(),
                  const SizedBox(height: 24),
                  _buildBarChart(),
                ],
              ),
            ),
    );
  }

  Widget _buildFilters() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(labelText: 'Min Amount'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    _minAmount = double.tryParse(value);
                  });
                  _loadExpenseData();
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(labelText: 'Max Amount'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    _maxAmount = double.tryParse(value);
                  });
                  _loadExpenseData();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButton<String>(
          value: _selectedCategory,
          hint: const Text('Select Category'),
          isExpanded: true,
          items: expenseCategories.keys.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Text(category),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value;
            });
            _loadExpenseData();
          },
        ),
      ],
    );
  }

  Widget _buildPieChart() {
    final total = expenseCategories.values.isEmpty
        ? 1.0
        : expenseCategories.values.reduce((a, b) => a + b);

    final sections = expenseCategories.entries.map((entry) {
      return PieChartSectionData(
        color: _getCategoryColor(entry.key),
        value: total > 0 ? entry.value : 1,
        title: total > 0
            ? '${((entry.value / total) * 100).toStringAsFixed(1)}%'
            : '0%',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return SizedBox(
      height: 200,
      child: PieChart(PieChartData(
        sections: sections,
        centerSpaceRadius: 40,
      )),
    );
  }

  Widget _buildBarChart() {
    final barData = expenseCategories.entries.isEmpty
        ? [BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 0, color: Colors.grey)])]
        : expenseCategories.entries.map((entry) {
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
                return Text(
                  expenseCategories.keys.isEmpty
                      ? 'N/A'
                      : expenseCategories.keys.toList()[index],
                );
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