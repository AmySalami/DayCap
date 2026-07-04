import 'package:flutter/material.dart';

import 'features/record/record_screen.dart';

class DayCapApp extends StatelessWidget {
  const DayCapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'day_cap',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const RecordScreen(),
    );
  }
}
