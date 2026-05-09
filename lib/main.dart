import 'package:flutter/material.dart';
import 'package:vitrinx/screens/landing_screen.dart';

void main() {
  runApp(const VitrinXApp());
}

class VitrinXApp extends StatelessWidget {
  const VitrinXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VitrinX',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
        fontFamily: 'Helvetica', // Basic font since no GoogleFonts
      ),
      home: const LandingScreen(),
    );
  }
}
