import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/shell/main_shell.dart';

class DayCapApp extends StatelessWidget {
  const DayCapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'day_cap',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const MainShell(),
    );
  }
}
