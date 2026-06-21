import 'package:flutter/material.dart';
import '../models/work_ticket.dart';
import '../theme/app_theme.dart';

class PriorityIndicator extends StatefulWidget {
  final TicketPriority priority;
  final Widget child;

  const PriorityIndicator({
    super.key,
    required this.priority,
    required this.child,
  });

  @override
  State<PriorityIndicator> createState() => _PriorityIndicatorState();
}

class _PriorityIndicatorState extends State<PriorityIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.15, end: 0.7).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.priority == TicketPriority.critical) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant PriorityIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.priority == TicketPriority.critical) {
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color indicatorColor;
    switch (widget.priority) {
      case TicketPriority.low:
        indicatorColor = AppColors.priorityLow;
        break;
      case TicketPriority.medium:
        indicatorColor = AppColors.priorityMedium;
        break;
      case TicketPriority.high:
        indicatorColor = AppColors.priorityHigh;
        break;
      case TicketPriority.critical:
        indicatorColor = AppColors.priorityCritical;
        break;
    }

    // Wrap the child with a left colored border
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final double glowAlpha =
            widget.priority == TicketPriority.critical ? _animation.value : 0.0;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: widget.priority == TicketPriority.critical
                ? [
                    BoxShadow(
                      color: indicatorColor.withValues(alpha: glowAlpha * 0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.priority == TicketPriority.critical
                    ? indicatorColor.withValues(alpha: glowAlpha)
                    : AppColors.border,
                width: widget.priority == TicketPriority.critical ? 1.5 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Row(
                children: [
                  // Left color bar indicator
                  Container(
                    width: 6,
                    height: 96, // Matches standard card height
                    color: indicatorColor,
                  ),
                  // Child content area
                  Expanded(
                    child: widget.child,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
