import 'package:flutter/material.dart';
import 'home_screen.dart';

void main() => runApp(const BudgetApp());

class BudgetApp extends StatelessWidget {
  const BudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Budget',
      theme: ThemeData(colorSchemeSeed: Colors.teal),
      home: const HomeScreen(),
    );
  }
}
