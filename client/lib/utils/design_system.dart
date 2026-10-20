import 'package:flutter/material.dart';

/// Monaco Corp design system — consistent colors, typography, spacing, and shapes.
/// Premium monochrome black-and-white theme: charcoal surfaces, subtle borders,
/// refined typography, restrained highlights, Batman–Alfred-inspired atmosphere.
class MonacoDesign {
  // ── Monochrome brand palette ────────────────────────────────────────────
  static const Color inkBlack = Color(0xFF0A0A0A);       // Near-black text
  static const Color charcoalDeep = Color(0xFF121212);   // Deep charcoal background
  static const Color charcoalSurface = Color(0xFF1E1E1E); // Charcoal cards
  static const Color charcoalCard = Color(0xFF252525);   // Slightly lighter cards
  static const Color charcoalElevated = Color(0xFF2D2D2D); // Elevated surfaces
  static const Color borderSubtle = Color(0xFF333333);   // Subtle borders
  static const Color borderMuted = Color(0xFF2A2A2A);    // Muted borders
  static const Color textInk = Color(0xFF0A0A0A);        // Near-black primary text
  static const Color textBody = Color(0xFF222222);       // Body text
  static const Color textSecondary = Color(0xFF555555);  // Secondary text
  static const Color textMuted = Color(0xFF777777);      // Muted text
  static const Color accentSoft = Color(0xFFD9D9D9);     // Soft highlight
  static const Color accentBright = Color(0xFFFFFFFF);   // Pure white highlight

  // ── Semantic colors (monochrome variants) ──────────────────────────────
  static const Color success = Color(0xFFD9D9D9); // Soft gray-green
  static const Color warning = Color(0xFFB3B3B3); // Muted amber-gray
  static const Color error = Color(0xFF8A8A8A);   // Subtle red-gray

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
        color: textInk,
        letterSpacing: -0.8,
      ) ??
      const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: inkBlack);

  static TextStyle headlineLarge(BuildContext context) =>
      Theme.of(context).textTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w800,
        color: textInk,
        letterSpacing: -1.0,
      ) ??
      const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: inkBlack);

  static TextStyle headlineMedium(BuildContext context) =>
      Theme.of(context).textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: textInk,
        letterSpacing: -0.4,
      ) ??
      const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: inkBlack);

  static TextStyle titleLarge(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: textInk,
      ) ??
      const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: inkBlack);

  static TextStyle bodyLarge(BuildContext context) =>
      Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: textBody,
        height: 1.5,
      ) ??
      const TextStyle(fontSize: 16, color: textBody, height: 1.5);

  static TextStyle bodyMedium(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: textSecondary,
        height: 1.5,
      ) ??
      const TextStyle(fontSize: 14, color: textSecondary, height: 1.5);

  static TextStyle labelMedium(BuildContext context) =>
      Theme.of(context).textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: textMuted,
        letterSpacing: 0.5,
      ) ??
      const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textMuted);

  // ── Button style helpers (monochrome) ──────────────────────────────────
  static ButtonStyle primaryButton(BuildContext context) => FilledButton.styleFrom(
    backgroundColor: inkBlack,
    foregroundColor: accentBright,
    elevation: 0,
    shadowColor: inkBlack.withOpacity(0.2),
    minimumSize: const Size(double.infinity, 52),
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  );

  static ButtonStyle secondaryButton(BuildContext context) => OutlinedButton.styleFrom(
    foregroundColor: inkBlack,
    minimumSize: const Size(double.infinity, 52),
    padding: const EdgeInsets.symmetric(vertical: 16),
    side: BorderSide(color: borderSubtle, width: 1.5),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  );

  static ButtonStyle textButton(BuildContext context) => TextButton.styleFrom(
    foregroundColor: inkBlack,
    minimumSize: const Size(double.infinity, 48),
    padding: const EdgeInsets.symmetric(vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
  );

  // ── Input decoration (monochrome) ──────────────────────────────────────
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
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20, color: textMuted) : null,
        suffixIcon: suffixIcon,
        filled: filled,
        fillColor: charcoalSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: borderMuted, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: borderMuted, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: inkBlack, width: 1.5),
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
          color: textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          color: textMuted.withOpacity(0.7),
          fontSize: 14,
        ),
        style: TextStyle(
          color: accentBright,
          fontSize: 14,
        ),
      );
}
