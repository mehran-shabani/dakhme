import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class ManageDbScreen extends StatefulWidget {
  const ManageDbScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ManageDbScreenState createState() => _ManageDbScreenState();
}

class _ManageDbScreenState extends State<ManageDbScreen> {
  List<Map<String, dynamic>> _data = [];
  List<Map<String, dynamic>> _filteredData = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _filterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _showDatabase();
  }

  Future<void> _showDatabase() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final db = await DatabaseHelper.initializeDatabase();
      final result = await db.query('transactions');
      setState(() {
        _data = result;
        _filteredData = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error accessing the database: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _filterData(String query) {
    setState(() {
      _filteredData = _data.where((item) {
        final category = item['category'].toString().toLowerCase();
        final note = item['note'].toString().toLowerCase();
        final amount = item['amount'].toString().toLowerCase();
        return category.contains(query.toLowerCase()) ||
               note.contains(query.toLowerCase()) ||
               amount.contains(query.toLowerCase());
      }).toList();
    });
  }

  Future<void> _deleteData(int id) async {
    try {
      final db = await DatabaseHelper.initializeDatabase();
      await db.delete(
        'transactions',
        where: 'id = ?',
        whereArgs: [id],
      );
      _showDatabase();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error deleting the record: ${e.toString()}';
      });
    }
  }

  Future<void> _showDeleteConfirmationDialog(int id) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this transaction?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteData(id);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Database'),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 50),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _showDatabase,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Database Transactions',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _filterController,
                        decoration: const InputDecoration(
                          labelText: 'Filter',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: _filterData,
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _filteredData.isEmpty ? _buildEmptyTable() : _buildDataTable(),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyTable() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 100, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No Data Available',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Your database does not contain any transactions.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    return ListView(
      children: [
        Table(
          border: TableBorder.all(color: Colors.grey),
          columnWidths: const {
            0: FlexColumnWidth(1),
            1: FlexColumnWidth(2),
            2: FlexColumnWidth(2),
            3: FlexColumnWidth(2),
            4: FlexColumnWidth(1),
          },
          children: [
            _buildTableHeader(),
            ..._filteredData.map((item) {
              return TableRow(
                children: [
                  _buildTableCell(item['id'].toString()),
                  _buildTableCell(item['category']),
                  _buildTableCell('\$${item['amount']}'),
                  _buildTableCell(item['note']),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _showDeleteConfirmationDialog(item['id']),
                  ),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  TableRow _buildTableHeader() {
    return TableRow(
      decoration: const BoxDecoration(color: Colors.grey),
      children: [
        _buildTableCell('ID', isHeader: true),
        _buildTableCell('Category', isHeader: true),
        _buildTableCell('Amount', isHeader: true),
        _buildTableCell('Note', isHeader: true),
        _buildTableCell('Action', isHeader: true),
      ],
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isHeader ? Colors.grey[300] : Colors.white,
        border: Border.all(color: Colors.grey),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}