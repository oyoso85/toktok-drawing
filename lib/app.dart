import 'package:flutter/material.dart';
import 'package:toktok_drawing/core/theme/app_theme.dart';
import 'package:toktok_drawing/features/mode_selection/mode_selection_screen.dart';

class TokTokDrawingApp extends StatelessWidget {
  const TokTokDrawingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TokTok Drawing',
      theme: AppTheme.lightTheme,
      home: const ModeSelectionScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
