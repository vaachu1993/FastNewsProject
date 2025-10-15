import 'package:flutter/material.dart';
import 'screens/main_screen.dart';

void main() {
  runApp(const FastNewsApp());
}

class FastNewsApp extends StatelessWidget {
  const FastNewsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FastNews',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MainScreen(), // 🔹 chỉ hiển thị MainScreen
    );
  }
}
