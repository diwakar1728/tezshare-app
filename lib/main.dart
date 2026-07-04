import 'package:flutter/material.dart';
import 'package:tezshare/screens/home_screen.dart';
import 'package:tezshare/theme/app_theme.dart';

void main() {
  runApp(const TezShareApp());
}

class TezShareApp extends StatelessWidget {
  const TezShareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TezShare',
      debugShowCheckedModeBanner: false,
      theme: buildTezShareTheme(),
      home: const HomeScreen(),
    );
  }
}
