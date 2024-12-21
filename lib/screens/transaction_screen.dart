// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../database/database_helper.dart';
import '../utils/category_types.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  _TransactionScreenState createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> with SingleTickerProviderStateMixin {
  String _selectedType = 'Income';
  String? _selectedCategory;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = _selectedType == 'Income' ? incomeCategories : expenseCategories;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _selectedType == 'Income' 
            ? Colors.green.shade500 
            : Colors.red.shade500,
        title: const Text(
          'New Transaction',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: _selectedType == 'Income' 
                    ? Colors.green.shade500 
                    : Colors.red.shade500,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedType = 'Income'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _selectedType == 'Income' 
                              ? Colors.white 
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_upward, color: _selectedType == 'Income' ? Colors.green.shade500 : Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              'Income',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _selectedType == 'Income' 
                                    ? Colors.green.shade500 
                                    : Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedType = 'Expense'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _selectedType == 'Expense' 
                              ? Colors.white 
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_downward, color: _selectedType == 'Expense' ? Colors.red.shade500 : Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              'Expense',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _selectedType == 'Expense' 
                                    ? Colors.red.shade500 
                                    : Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputCard('Amount', _amountController, TextInputType.number, 'Enter amount', isNumber: true),
                  const SizedBox(height: 16),
                  _buildDropdownCard('Category', categories, _selectedCategory, (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }),
                  const SizedBox(height: 16),
                  _buildInputCard('Note', _noteController, TextInputType.text, 'Add a note...'),
                  const SizedBox(height: 24),
                  _buildSaveButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard(String label, TextEditingController controller, TextInputType inputType, String hint, {bool isNumber = false}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              keyboardType: inputType,
              inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : null,
              decoration: InputDecoration(
                hintText: hint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) {
                if (isNumber && value.isNotEmpty && double.tryParse(value) == null) {
                  Fluttertoast.showToast(
                    msg: "Please enter a valid number",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownCard(String label, List<String> items, String? selectedValue, ValueChanged<String?> onChanged) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedValue,
                hint: Text('Select $label'),
                isExpanded: true,
                items: items.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _selectedType == 'Income' 
              ? Colors.green.shade500 
              : Colors.red.shade500,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: () async {
          if (_amountController.text.isEmpty || _selectedCategory == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please fill in all required fields'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          final db = await DatabaseHelper.initializeDatabase();

          await db.insert('transactions', {
            'type': _selectedType,
            'category': _selectedCategory,
            'amount': double.parse(_amountController.text),
            'note': _noteController.text,
            'date': DateTime.now().toIso8601String(),
          });

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Transaction Added Successfully!'),
              backgroundColor: _selectedType == 'Income' ? Colors.green : Colors.red,
            ),
          );

          _amountController.clear();
          _noteController.clear();
          setState(() {
            _selectedCategory = null;
          });
        },
        child: const Text(
          'Add Transaction',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}