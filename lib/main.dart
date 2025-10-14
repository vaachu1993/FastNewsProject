import 'package:flutter/material.dart';
import 'screens/home_screen.dart'; // sẽ tạo file này sau

void main() {
  runApp(const FastNewsApp());
}

class FastNewsApp extends StatelessWidget {
  const FastNewsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FastNews',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
