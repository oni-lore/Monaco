import 'package:flutter/material.dart';
import '../utils/design_system.dart';

/// Monaco Corp branded loading experience.
///
/// Displays a premium, animated loading state with the message
/// "You'll be in Monaco Corp ASAP." Used for app-entry and
/// session-initialization waiting states.
class MonacoLoader extends StatefulWidget {
  /// Whether the loader should allow retry on failure.
  final bool allowRetry;

  /// Optional error to display instead of the loader.
  final String? error;

  /// Callback when the user taps retry.
  final VoidCallback? onRetry;

  const MonacoLoader({
    super.key,
    this.allowRetry = false,
    this.error,
    this.onRetry,
  });

  @override
  State<MonacoLoader> createState() => _MonacoLoaderState();
}

class _MonacoLoaderState extends State<MonacoLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _rotateController;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _rotateAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (widget.error != null) {
      return _buildErrorState(colors);
    }

    return Scaffold(
      backgroundColor: MonacoDesign.brandSurface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Monaco Corp brand mark
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [MonacoDesign.brandPrimary, MonacoDesign.brandPrimaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(MonacoDesign.radiusXl),
                      boxShadow: [
                        BoxShadow(
                          color: MonacoDesign.brandPrimary.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: RotationTransition(
                        turns: _rotateAnimation,
                        child: const Icon(
                          Icons.lock_outline_rounded,
                          size: 52,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: MonacoDesign.lg),
            Text(
              'Monaco Corp',
              style: MonacoDesign.headlineLarge(context).copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -1.2,
                color: MonacoDesign.brandTextPrimary,
              ),
            ),
            const SizedBox(height: MonacoDesign.sm),
            Text(
              'You\u2019ll be in Monaco Corp ASAP.',
              style: MonacoDesign.bodyLarge(context).copyWith(
                color: MonacoDesign.brandTextSecondary,
                fontSize: 17,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: MonacoDesign.xxl),
            // Subtle progress indicator (no fake percentages)
            SizedBox(
              width: 200,
              height: 4,
              child: LinearProgressIndicator(
                backgroundColor: MonacoDesign.brandPrimary.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation<Color>(MonacoDesign.brandPrimary),
              ),
            ),
            if (widget.allowRetry && widget.onRetry != null) ...[
              const SizedBox(height: MonacoDesign.lg),
              TextButton(
                onPressed: widget.onRetry,
                style: MonacoDesign.textButton(context),
                child: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ColorScheme colors) {
    return Scaffold(
      backgroundColor: MonacoDesign.brandSurface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: MonacoDesign.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: MonacoDesign.error,
                size: 36,
              ),
            ),
            const SizedBox(height: MonacoDesign.lg),
            Text(
              'Something went wrong',
              style: MonacoDesign.headlineMedium(context).copyWith(
                fontWeight: FontWeight.w800,
                color: MonacoDesign.brandTextPrimary,
              ),
            ),
            const SizedBox(height: MonacoDesign.sm),
            Text(
              widget.error ?? 'An unexpected error occurred.',
              style: MonacoDesign.bodyMedium(context).copyWith(
                color: MonacoDesign.brandTextSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.onRetry != null) ...[
              const SizedBox(height: MonacoDesign.xl),
              FilledButton.icon(
                onPressed: widget.onRetry,
                style: MonacoDesign.primaryButton(context).copyWith(
                backgroundColor: WidgetStateProperty.resolveWith<Color>(
                  (states) => states.contains(WidgetState.disabled)
                      ? MonacoDesign.error.withOpacity(0.6)
                      : MonacoDesign.error,
                ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
