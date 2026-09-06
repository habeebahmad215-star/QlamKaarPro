import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const QalamKaarProApp());
}

class QalamKaarProApp extends StatelessWidget {
  const QalamKaarProApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QalamKaar Pro',
      theme: ThemeData(
        primaryColor: const Color(0xFF8B5CF6), 
        scaffoldBackgroundColor: const Color(0xFFF8F9FA)
      ),
      home: const HomeScreen(),
    );
  }
}
