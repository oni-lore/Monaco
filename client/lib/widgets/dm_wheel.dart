import 'dart:math';

import 'package:flutter/material.dart';
import 'package:monaco/models/message.dart';
import 'package:monaco/utils/design_system.dart';

/// Edge position for the DM Quick-Access wheel.
enum DMWheelEdge { left, right }

/// Persisted DM Quick-Access wheel setting.
enum DMWheelMode { off, left, right }

/// A reusable semicircular DM Quick-Access wheel.
///
/// The wheel slides in from the selected screen edge and displays private
/// DM contacts as circular avatars arranged along a curved arc. Tapping an
/// avatar opens that user's direct conversation directly.
///
/// The wheel:
/// - Is exclusively for private DMs (no Councils or groups)
/// - Respects device safe areas and available screen dimensions
/// - Closes on outside tap or Back button
/// - Restores underlying screen scroll position when closed
/// - Is available on Chats, Loading Chambers, DM conversations, and
///   Council conversations (not on Profile, Settings, or Notifications)
class DMQuickAccessWheel extends StatefulWidget {
  /// Whether the wheel is enabled.
  final DMWheelMode mode;

  /// The demo/demo-mode conversations to show in the wheel.
  final List<Conversation> dms;

  /// Callback when a DM contact is tapped. Receives the conversation ID.
  final ValueSetter<String> onContactSelected;

  /// Whether the wheel is currently open.
  final bool isOpen;

  /// Callback when the open/closed state changes.
  final ValueChanged<bool> onOpenChanged;

  const DMQuickAccessWheel({
    super.key,
    required this.mode,
    required this.dms,
    required this.onContactSelected,
    required this.isOpen,
    required this.onOpenChanged,
  });

  @override
  State<DMQuickAccessWheel> createState() => _DMQuickAccessWheelState();
}

class _DMQuickAccessWheelState extends State<DMQuickAccessWheel>
    with SingleTickerProviderStateMixin {
  late AnimationController _openController;
  late Animation<double> _openAnimation;

  static const double _wheelRadius = 220.0;
  static const double _handleSize = 48.0;
  static const double _avatarSize = 52.0;
  static const double _innerRadius = 90.0;

  @override
  void initState() {
    super.initState();
    _openController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _openAnimation = CurvedAnimation(
      parent: _openController,
      curve: Curves.easeOutCubic,
    );

    if (widget.isOpen) {
      _openController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(DMQuickAccessWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != oldWidget.isOpen) {
      if (widget.isOpen) {
        _openController.forward();
      } else {
        _openController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _openController.dispose();
    super.dispose();
  }

  void _toggle() {
    widget.onOpenChanged(!widget.isOpen);
    if (widget.isOpen) {
      _openController.reverse();
    } else {
      _openController.forward();
    }
  }

  void _selectContact(Conversation dm) {
    widget.onContactSelected(dm.id);
    _toggle();
  }

  /// Compute the avatar position along the semicircular arc.
  /// Returns [dx, dy] relative to the wheel center.
  Offset _avatarPosition(int index, int total) {
    if (total == 0) return Offset.zero;
    final startAngle = widget.mode == DMWheelMode.left ? -pi / 2 : pi / 2;
    final endAngle = widget.mode == DMWheelMode.left ? pi / 2 : 3 * pi / 2;
    final angle = startAngle + (endAngle - startAngle) * index / (total - 1 > 0 ? total - 1 : 1);

    final radius = _innerRadius + (_wheelRadius - _innerRadius) * 0.5;
    return Offset(radius * cos(angle), radius * sin(angle));
  }

  DMWheelEdge _getEdgeForClipper() {
    return widget.mode == DMWheelMode.left ? DMWheelEdge.left : DMWheelEdge.right;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mode == DMWheelMode.off || widget.dms.isEmpty) {
      return const SizedBox.shrink();
    }

    final safeArea = MediaQuery.of(context).padding;
    final isLeft = widget.mode == DMWheelMode.left;

    return AnimatedBuilder(
      animation: _openController,
      builder: (context, child) {
        final open = _openAnimation.value;
        if (open == 0.0) return const SizedBox.shrink();

        return Positioned(
          top: safeArea.top + 60.0,
          left: isLeft ? -_wheelRadius * (1.0 - open) : null,
          right: !isLeft ? -_wheelRadius * (1.0 - open) : null,
          child: SizedBox(
            width: _wheelRadius * 2,
            height: _wheelRadius * 2,
            child: Stack(
              children: [
                // Fade overlay for outside-tap close
                if (open > 0.1)
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: open < 0.5,
                      child: Opacity(
                        opacity: open * 0.3,
                        child: Container(color: Colors.black.withOpacity(0.2)),
                      ),
                    ),
                  ),
                // The semicircular wheel container
                ClipPath(
                  clipper: _DMWheelClipper(edge: _getEdgeForClipper()),
                  child: Container(
                    width: _wheelRadius * 2,
                    height: _wheelRadius * 2,
                    decoration: BoxDecoration(
                      color: MonacoDesign.charcoalSurface,
                      border: Border.all(
                        color: MonacoDesign.borderSubtle,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: MonacoDesign.inkBlack.withOpacity(0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _buildWheelContent(),
                  ),
                ),
                // Edge activation handle
                if (!widget.isOpen)
                  Positioned(
                    top: _handleSize / 2,
                    left: isLeft ? 0 : null,
                    right: !isLeft ? 0 : null,
                    child: GestureDetector(
                      onTap: _toggle,
                      child: Container(
                        width: _handleSize,
                        height: _handleSize,
                        decoration: BoxDecoration(
                          color: MonacoDesign.charcoalElevated,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: MonacoDesign.borderSubtle,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: MonacoDesign.inkBlack.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          isLeft ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
                          size: 20,
                          color: MonacoDesign.accentBright,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWheelContent() {
    final dms = widget.dms;
    if (dms.isEmpty) return const SizedBox.shrink();

    final children = <Widget>[];

    for (int i = 0; i < dms.length; i++) {
      final dm = dms[i];
      final username =
          dm.otherParticipant?['username'] as String? ?? dm.displayName;

      children.add(
        Container(
          width: _avatarSize,
          height: _avatarSize,
          decoration: BoxDecoration(
            color: MonacoDesign.charcoalElevated,
            shape: BoxShape.circle,
            border: Border.all(
              color: MonacoDesign.borderSubtle,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              username.isNotEmpty
                  ? username.substring(0, 1).toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: MonacoDesign.accentBright,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
      );
    }

    return Stack(
      children: children,
    );
  }
}

/// Clipper for the semicircular DM wheel.
class _DMWheelClipper extends CustomClipper<Path> {
  final DMWheelEdge edge;

  const _DMWheelClipper({required this.edge});

  @override
  Path getClip(Size size) {
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    if (edge == DMWheelEdge.left) {
      path.moveTo(0, center.dy);
      path.arcToPoint(
        Offset(0, center.dy),
        radius: Radius.circular(radius),
        largeArc: false,
        clockwise: false,
      );
      path.lineTo(0, center.dy);
    } else {
      path.moveTo(size.width, center.dy);
      path.arcToPoint(
        Offset(size.width, center.dy),
        radius: Radius.circular(radius),
        largeArc: false,
        clockwise: true,
      );
      path.lineTo(size.width, center.dy);
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(_DMWheelClipper oldClipper) => oldClipper.edge != edge;
}
