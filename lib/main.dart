import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() => runApp(const IncomeExpenseTrackerApp());

class IncomeExpenseTrackerApp extends StatelessWidget {
  const IncomeExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Income & Expense Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SplashScreen(),
    );
  }
}
