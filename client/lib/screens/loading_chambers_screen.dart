import 'package:flutter/material.dart';
import 'package:monaco/utils/design_system.dart';

/// Loading Chambers — separate GUI for historical archives.
/// This screen is accessed via the bottom navigation bar.
/// It is intentionally minimal — a placeholder for planned archive features.
class LoadingChambersScreen extends StatelessWidget {
  const LoadingChambersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MonacoDesign.charcoalDeep,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: MonacoDesign.charcoalSurface,
                borderRadius: BorderRadius.circular(MonacoDesign.radiusLg),
                border: Border.all(
                  color: MonacoDesign.borderSubtle,
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 32,
                color: MonacoDesign.textSecondary,
              ),
            ),
            const SizedBox(height: MonacoDesign.md),
            Text(
              'Loading Chambers',
              style: MonacoDesign.headlineMedium(context).copyWith(
                fontWeight: FontWeight.w800,
                color: MonacoDesign.textInk,
              ),
            ),
            const SizedBox(height: MonacoDesign.sm),
            Text(
              'Historical archives.\nPlanned features coming soon.',
              textAlign: TextAlign.center,
              style: MonacoDesign.bodyMedium(context).copyWith(
                color: MonacoDesign.textSecondary,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
