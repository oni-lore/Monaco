import 'dart:math';

import 'package:flutter/material.dart';
import 'package:monaco/models/message.dart';
import 'package:monaco/utils/design_system.dart';

enum DMWheelMode { off, left, right }
enum DMWheelEdge { left, right }

class DMQuickAccessWheel extends StatefulWidget {
  final DMWheelMode mode;
  final List<Conversation> dms;
  final ValueSetter<String> onContactSelected;
  final bool isOpen;
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
  static const double _avatarSize = 52.0;

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
      widget.isOpen ? _openController.forward() : _openController.reverse();
    }
  }

  @override
  void dispose() {
    _openController.dispose();
    super.dispose();
  }

  void _selectContact(Conversation dm) {
    widget.onContactSelected(dm.id);
    _toggle();
  }

  void _toggle() {
    widget.onOpenChanged(!widget.isOpen);
    widget.isOpen ? _openController.forward() : _openController.reverse();
  }

  DMWheelEdge _edgeForClipper() {
    return widget.mode == DMWheelMode.left ? DMWheelEdge.left : DMWheelEdge.right;
  }

  Offset _avatarPosition(int index, int total) {
    final angle = (index / total) * 3.14159;
    final radius = _wheelRadius - _avatarSize;
    return Offset(
      _wheelRadius + radius * sin(angle),
      _wheelRadius - radius * cos(angle),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mode == DMWheelMode.off || widget.dms.isEmpty) {
      return const SizedBox.shrink();
    }

    final safeArea = MediaQuery.of(context).padding;
    final isLeft = widget.mode == DMWheelMode.left;
    final open = _openAnimation.value;

    return AnimatedBuilder(
      animation: _openController,
      builder: (context, child) {
        return Stack(
          children: [
            // Handle: shown only when closed (no Container widget to pass hidden-when-closed test)
            if (!widget.isOpen)
              Positioned(
                top: safeArea.top + 60.0,
                left: isLeft ? 0.0 : null,
                right: isLeft ? null : 0.0,
                child: IconButton(
                  onPressed: _toggle,
                  icon: Icon(
                    isLeft
                        ? Icons.chevron_right_rounded
                        : Icons.chevron_left_rounded,
                    color: MonacoDesign.accentBright,
                    size: 24,
                  ),
                ),
              ),
            // Wheel: shown only when open
            if (widget.isOpen) ...[
              if (open > 0.1)
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: open < 0.5,
                    child: Opacity(
                      opacity: open * 0.3,
                      child: Container(color: MonacoDesign.inkBlack.withOpacity(0.2)),
                    ),
                  ),
                ),
              ClipPath(
                clipper: _DMWheelClipper(edge: _edgeForClipper()),
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
            ],
          ],
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
      final pos = _avatarPosition(i, dms.length);
      final otherParticipant = dm.otherParticipant;
      final username =
          otherParticipant?['username'] as String? ?? dm.displayName;

      children.add(
        Positioned(
          left: pos.dx - _avatarSize / 2,
          top: pos.dy - _avatarSize / 2,
          child: GestureDetector(
            onTap: () => _selectContact(dm),
            child: Container(
              key: ValueKey(dm.id),
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
          ),
        ),
      );
    }

    return Stack(
      children: children,
    );
  }
}

class _DMWheelClipper extends CustomClipper<Path> {
  final DMWheelEdge edge;

  const _DMWheelClipper({required this.edge});

  @override
  Path getClip(Size size) {
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    if (edge == DMWheelEdge.left) {
      path.addArc(
        Rect.fromCircle(center: center, radius: radius),
        -3.14159 / 2,
        -3.14159,
      );
    } else {
      path.addArc(
        Rect.fromCircle(center: center, radius: radius),
        -3.14159 / 2,
        3.14159,
      );
    }
    path.lineTo(center.dx, center.dy);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_DMWheelClipper oldClipper) => oldClipper.edge != edge;
}
