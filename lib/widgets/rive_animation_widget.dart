import 'package:flutter/material.dart';
import 'package:flutter/painting.dart' as painting;
import 'package:rive/rive.dart' hide RadialGradient, LinearGradient;

/// A sophisticated Rive animation widget that runs animations off the UI thread
class RiveAnimationWidget extends StatefulWidget {
  final String assetPath;
  final String? animationName;
  final BoxFit fit;
  final double? width;
  final double? height;
  final bool autoplay;
  final VoidCallback? onInit;
  final VoidCallback? onPlay;
  final VoidCallback? onPause;
  final VoidCallback? onStop;

  const RiveAnimationWidget({
    super.key,
    required this.assetPath,
    this.animationName,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
    this.autoplay = true,
    this.onInit,
    this.onPlay,
    this.onPause,
    this.onStop,
  });

  @override
  State<RiveAnimationWidget> createState() => _RiveAnimationWidgetState();
}

class _RiveAnimationWidgetState extends State<RiveAnimationWidget> {
  Artboard? _riveArtboard;
  StateMachineController? _controller;
  SMIInput<bool>? _playInput;
  SMIInput<bool>? _pauseInput;

  @override
  void initState() {
    super.initState();
    _loadRiveFile();
  }

  void _loadRiveFile() async {
    try {
      final data = await RiveFile.asset(widget.assetPath);
      final artboard = data.mainArtboard;

      if (widget.animationName != null) {
        var controller = StateMachineController.fromArtboard(
          artboard,
          widget.animationName!,
        );

        if (controller != null) {
          artboard.addController(controller);
          _controller = controller;
          _playInput = controller.findInput<bool>('play');
          _pauseInput = controller.findInput<bool>('pause');
        }
      } else {
        // Use simple animation if no state machine is specified
        var controller = SimpleAnimation('idle');
        artboard.addController(controller);
      }

      setState(() {
        _riveArtboard = artboard;
      });

      if (widget.autoplay) {
        play();
      }

      widget.onInit?.call();
    } catch (e) {
      print('Error loading Rive file: $e');
      // Fallback to a simple animated container
      setState(() {
        _riveArtboard = null;
      });
    }
  }

  void play() {
    _playInput?.value = true;
    widget.onPlay?.call();
  }

  void pause() {
    _pauseInput?.value = true;
    widget.onPause?.call();
  }

  void stop() {
    _playInput?.value = false;
    widget.onStop?.call();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_riveArtboard != null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: Rive(
          artboard: _riveArtboard!,
          fit: widget.fit,
        ),
      );
    } else {
      // Fallback animation when Rive file is not available
      return _buildFallbackAnimation();
    }
  }

  Widget _buildFallbackAnimation() {
    return SizedBox(
      width: widget.width ?? 100,
      height: widget.height ?? 100,
      child: const _FallbackAnimation(),
    );
  }
}

/// Fallback animation when Rive files are not available
class _FallbackAnimation extends StatefulWidget {
  const _FallbackAnimation();

  @override
  State<_FallbackAnimation> createState() => _FallbackAnimationState();
}

class _FallbackAnimationState extends State<_FallbackAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: painting.RadialGradient(
              colors: [
                Colors.blue.withValues(alpha: _animation.value),
                Colors.blueAccent.withValues(alpha: _animation.value * 0.5),
              ],
            ),
          ),
          child: Transform.scale(
            scale: 0.5 + (_animation.value * 0.5),
            child: const Icon(
              Icons.sports_tennis,
              color: Colors.white,
              size: 40,
            ),
          ),
        );
      },
    );
  }
}

/// A sophisticated animated background widget
class AnimatedBackgroundWidget extends StatefulWidget {
  final Widget child;
  final Color primaryColor;
  final Color secondaryColor;
  final Duration duration;

  const AnimatedBackgroundWidget({
    super.key,
    required this.child,
    this.primaryColor = Colors.blue,
    this.secondaryColor = Colors.blueAccent,
    this.duration = const Duration(seconds: 10),
  });

  @override
  State<AnimatedBackgroundWidget> createState() => _AnimatedBackgroundWidgetState();
}

class _AnimatedBackgroundWidgetState extends State<AnimatedBackgroundWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: painting.LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.primaryColor.withValues(alpha: 0.1),
                widget.secondaryColor.withValues(alpha: 0.05),
                widget.primaryColor.withValues(alpha: 0.1),
              ],
              stops: [
                _animation.value * 0.3,
                0.5 + (_animation.value * 0.2),
                0.7 + (_animation.value * 0.3),
              ],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}

/// Interactive animated button with sophisticated effects
class InteractiveAnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const InteractiveAnimatedButton({
    super.key,
    required this.child,
    this.onPressed,
    this.backgroundColor,
    this.padding,
    this.borderRadius,
  });

  @override
  State<InteractiveAnimatedButton> createState() => _InteractiveAnimatedButtonState();
}

class _InteractiveAnimatedButtonState extends State<InteractiveAnimatedButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rippleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rippleAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _scaleController.forward();
    _rippleController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _scaleController.reverse();
  }

  void _handleTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: () {
        _rippleController.reset();
        widget.onPressed?.call();
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleAnimation, _rippleAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: widget.padding ?? const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: widget.backgroundColor ?? Colors.blue,
                borderRadius: widget.borderRadius ?? BorderRadius.circular(8.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1 * _rippleAnimation.value),
                    blurRadius: 10.0 * _rippleAnimation.value,
                    spreadRadius: 2.0 * _rippleAnimation.value,
                  ),
                ],
              ),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}
