import 'package:flutter/material.dart';
import 'screens/labeling_screen.dart';

void main() {
  runApp(const EmployeeApp());
}

class EmployeeApp extends StatelessWidget {
  const EmployeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FreshReminder - Employee',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LabelingScreen(),
    );
  }
}
