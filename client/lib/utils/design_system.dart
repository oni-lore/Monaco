import 'package:flutter/material.dart';

/// Monaco Corp design system — consistent colors, typography, spacing, and shapes.
class MonacoDesign {
  // ── Brand palette ──────────────────────────────────────────────────────
  static const Color brandPrimary = Color(0xFF4F46E5);      // indigo-600
  static const Color brandPrimaryDark = Color(0xFF4338CA);   // indigo-700
  static const Color brandPrimaryLight = Color(0xFF818CF8);  // indigo-400
  static const Color brandSurface = Color(0xFFF8FAFC);       // slate-50
  static const Color brandCard = Color(0xFFFFFFFF);
  static const Color brandTextPrimary = Color(0xFF0F172A);   // slate-900
  static const Color brandTextSecondary = Color(0xFF64748B); // slate-500
  static const Color brandAccent = Color(0xFF06B6D4);        // cyan-500

  // ── Semantic colors ────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981); // emerald-500
  static const Color warning = Color(0xFFF59E0B); // amber-500
  static const Color error = Color(0xFFEF4444);   // red-500

  // ── Spacing ────────────────────────────────────────────────────────────
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  // ── Border radius ──────────────────────────────────────────────────────
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusFull = 28;

  // ── Text styles ────────────────────────────────────────────────────────
  static TextStyle displayLarge(BuildContext context) =>
      Theme.of(context).textTheme.displayLarge?.copyWith(
        fontWeight: FontWeight.w800,
        color: brandTextPrimary,
        letterSpacing: -0.8,
      ) ??
      const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: brandTextPrimary);

  static TextStyle headlineLarge(BuildContext context) =>
      Theme.of(context).textTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w800,
        color: brandTextPrimary,
        letterSpacing: -1.0,
      ) ??
      const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: brandTextPrimary);

  static TextStyle headlineMedium(BuildContext context) =>
      Theme.of(context).textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: brandTextPrimary,
        letterSpacing: -0.4,
      ) ??
      const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: brandTextPrimary);

  static TextStyle titleLarge(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: brandTextPrimary,
      ) ??
      const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: brandTextPrimary);

  static TextStyle bodyLarge(BuildContext context) =>
      Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: brandTextPrimary,
        height: 1.5,
      ) ??
      const TextStyle(fontSize: 16, color: brandTextPrimary, height: 1.5);

  static TextStyle bodyMedium(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: brandTextSecondary,
        height: 1.5,
      ) ??
      const TextStyle(fontSize: 14, color: brandTextSecondary, height: 1.5);

  static TextStyle labelMedium(BuildContext context) =>
      Theme.of(context).textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: brandTextSecondary,
        letterSpacing: 0.5,
      ) ??
      const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: brandTextSecondary);

  // ── Button style helpers ───────────────────────────────────────────────
  static ButtonStyle primaryButton(BuildContext context) => FilledButton.styleFrom(
    backgroundColor: brandPrimary,
    foregroundColor: Colors.white,
    elevation: 0,
    shadowColor: brandPrimary.withOpacity(0.3),
    minimumSize: const Size(double.infinity, 52),
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  );

  static ButtonStyle secondaryButton(BuildContext context) => OutlinedButton.styleFrom(
    foregroundColor: brandPrimary,
    minimumSize: const Size(double.infinity, 52),
    padding: const EdgeInsets.symmetric(vertical: 16),
    side: BorderSide(color: brandPrimary.withOpacity(0.4), width: 1.5),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  );

  static ButtonStyle textButton(BuildContext context) => TextButton.styleFrom(
    foregroundColor: brandPrimary,
    minimumSize: const Size(double.infinity, 48),
    padding: const EdgeInsets.symmetric(vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
  );

  // ── Input decoration ───────────────────────────────────────────────────
  static InputDecoration inputDecoration({
    required BuildContext context,
    required String label,
    String? hint,
    IconData? prefixIcon,
    Widget? suffixIcon,
    bool filled = true,
  }) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
        suffixIcon: suffixIcon,
        filled: filled,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: brandPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: error, width: 2),
        ),
        labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
          fontSize: 14,
        ),
      );
}
