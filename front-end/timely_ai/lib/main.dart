import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timely_ai/features/home/screens/home_screen.dart';

void main() {
  // ProviderScope is the widget that stores the state of all your providers.
  // It must be at the root of your application.
  runApp(const ProviderScope(child: TimelyAIApp()));
}

class TimelyAIApp extends StatelessWidget {
  const TimelyAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Timely.AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
