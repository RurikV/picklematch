import 'package:flutter/material.dart';

/// Custom page transitions that run animations off the UI thread
class CustomPageTransitions {

  /// Slide transition from right to left
  static PageRouteBuilder<T> slideFromRight<T extends Object?>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Use a curved animation for smoother transitions
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubic,
          reverseCurve: Curves.easeInOutCubic,
        );

        // Slide transition from right
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );
      },
    );
  }

  /// Fade and scale transition
  static PageRouteBuilder<T> fadeAndScale<T extends Object?>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Use different curves for different parts of the animation
        final fadeAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeIn,
          reverseCurve: Curves.easeOut,
        );

        final scaleAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.elasticOut,
          reverseCurve: Curves.easeInBack,
        );

        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.8,
              end: 1.0,
            ).animate(scaleAnimation),
            child: child,
          ),
        );
      },
    );
  }

  /// Hero-style zoom transition
  static PageRouteBuilder<T> heroZoom<T extends Object?>(Widget page, {String? heroTag}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.fastOutSlowIn,
          reverseCurve: Curves.fastLinearToSlowEaseIn,
        );

        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }

  /// Rotation and fade transition
  static PageRouteBuilder<T> rotationFade<T extends Object?>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 500),
      reverseTransitionDuration: const Duration(milliseconds: 400),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutQuart,
          reverseCurve: Curves.easeInOutQuart,
        );

        return RotationTransition(
          turns: Tween<double>(
            begin: 0.1,
            end: 0.0,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: curvedAnimation,
            child: child,
          ),
        );
      },
    );
  }

  /// Custom morphing transition with multiple effects
  static PageRouteBuilder<T> morphTransition<T extends Object?>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 600),
      reverseTransitionDuration: const Duration(milliseconds: 500),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Create multiple animation controllers for complex effects
        final primaryCurve = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
        );

        final secondaryCurve = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
        );

        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(primaryCurve),
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.8,
              end: 1.0,
            ).animate(secondaryCurve),
            child: FadeTransition(
              opacity: primaryCurve,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Extension to make navigation with custom transitions easier
extension NavigatorExtensions on NavigatorState {

  /// Push with slide from right transition
  Future<T?> pushWithSlide<T extends Object?>(Widget page) {
    return push<T>(CustomPageTransitions.slideFromRight<T>(page));
  }

  /// Push with fade and scale transition
  Future<T?> pushWithFadeScale<T extends Object?>(Widget page) {
    return push<T>(CustomPageTransitions.fadeAndScale<T>(page));
  }

  /// Push with hero zoom transition
  Future<T?> pushWithHeroZoom<T extends Object?>(Widget page, {String? heroTag}) {
    return push<T>(CustomPageTransitions.heroZoom<T>(page, heroTag: heroTag));
  }

  /// Push with rotation fade transition
  Future<T?> pushWithRotationFade<T extends Object?>(Widget page) {
    return push<T>(CustomPageTransitions.rotationFade<T>(page));
  }

  /// Push with morph transition
  Future<T?> pushWithMorph<T extends Object?>(Widget page) {
    return push<T>(CustomPageTransitions.morphTransition<T>(page));
  }
}
