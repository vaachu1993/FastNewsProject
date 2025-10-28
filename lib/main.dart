import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

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
      home: const LoginScreen(), // 🔹 hiển thị màn hình đăng nhập
    );
  }
}
