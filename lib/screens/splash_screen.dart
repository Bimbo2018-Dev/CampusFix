import 'dart:async';

import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      if (!mounted) {
        return;
      }
      final state = AppStateScope.read(context);
      Navigator.of(context).pushReplacementNamed(
        state.currentUser == null
            ? CampusFixRoutes.roles
            : CampusFixRoutes.dashboard,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 188,
              height: 188,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(44),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    blurRadius: 28,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(36),
                child: Image.asset(
                  'assets/images/campusfix_logo.png',
                  fit: BoxFit.contain,
                  semanticLabel: 'CampusFix logo',
                ),
              ),
            ),
            const SizedBox(height: 36),
            Text(
              'CampusFix',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              'Report. Track. Resolve.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.mutedText,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 160),
            const SizedBox(
              width: 52,
              child: LinearProgressIndicator(
                color: AppColors.primary,
                borderRadius: BorderRadius.all(Radius.circular(999)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
