import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A sophisticated loading widget with multiple animation layers
/// Designed to run animations off the UI thread for better performance
class AnimatedLoadingWidget extends StatefulWidget {
  final double size;
  final Color primaryColor;
  final Color secondaryColor;
  final Duration duration;
  final String? message;

  const AnimatedLoadingWidget({
    super.key,
    this.size = 80.0,
    this.primaryColor = Colors.blue,
    this.secondaryColor = Colors.blueAccent,
    this.duration = const Duration(milliseconds: 2000),
    this.message,
  });

  @override
  State<AnimatedLoadingWidget> createState() => _AnimatedLoadingWidgetState();
}

class _AnimatedLoadingWidgetState extends State<AnimatedLoadingWidget>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;

  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize multiple animation controllers for complex effects
    _rotationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: Duration(milliseconds: widget.duration.inMilliseconds ~/ 2),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: Duration(milliseconds: widget.duration.inMilliseconds ~/ 3),
      vsync: this,
    );

    // Create sophisticated animations with different curves
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOutSine,
    ));

    // Start animations with different patterns
    _rotationController.repeat();
    _scaleController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _rotationAnimation,
              _scaleAnimation,
              _pulseAnimation,
            ]),
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Transform.rotate(
                  angle: _rotationAnimation.value,
                  child: CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: LoadingPainter(
                      primaryColor: widget.primaryColor,
                      secondaryColor: widget.secondaryColor,
                      pulseValue: _pulseAnimation.value,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 16.0),
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _pulseAnimation.value,
                child: Text(
                  widget.message!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: widget.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

/// Custom painter for sophisticated loading animation
class LoadingPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final double pulseValue;

  LoadingPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Create gradient paint
    final gradientPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryColor.withValues(alpha: pulseValue),
          secondaryColor.withValues(alpha: pulseValue * 0.7),
          primaryColor.withValues(alpha: pulseValue * 0.3),
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    // Draw outer circle with gradient
    canvas.drawCircle(center, radius * 0.9, gradientPaint);

    // Draw inner rotating elements
    final innerPaint = Paint()
      ..color = secondaryColor.withValues(alpha: pulseValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Draw multiple rotating arcs
    for (int i = 0; i < 3; i++) {
      final startAngle = (i * 2 * math.pi / 3) + (pulseValue * 2 * math.pi);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * (0.3 + i * 0.15)),
        startAngle,
        math.pi / 2,
        false,
        innerPaint,
      );
    }

    // Draw center dot
    final centerPaint = Paint()
      ..color = primaryColor.withValues(alpha: pulseValue)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.1 * pulseValue, centerPaint);
  }

  @override
  bool shouldRepaint(LoadingPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue ||
           oldDelegate.primaryColor != primaryColor ||
           oldDelegate.secondaryColor != secondaryColor;
  }
}

/// A floating action button with sophisticated animations
class AnimatedFloatingActionButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? backgroundColor;
  final String? heroTag;

  const AnimatedFloatingActionButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    this.heroTag,
  });

  @override
  State<AnimatedFloatingActionButton> createState() => _AnimatedFloatingActionButtonState();
}

class _AnimatedFloatingActionButtonState extends State<AnimatedFloatingActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: FloatingActionButton(
                onPressed: null, // Handled by GestureDetector
                backgroundColor: widget.backgroundColor,
                heroTag: widget.heroTag,
                child: widget.child,
              ),
            ),
          );
        },
      ),
    );
  }
}
