import 'package:flutter/material.dart';
import 'package:qarshi_kafe/core/constants.dart';
import 'package:qarshi_kafe/screens/auth.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: appName, home: const ScreenAuth());
  }
}
