import 'package:flutter/material.dart';
import '../../constants/app_motion.dart';
import '../../theme/design_tokens.dart';

/// Premium Page Transition
/// Custom page route transitions with consistent easing
class PremiumPageTransition<T> extends PageRouteBuilder<T> {
  final Widget child;
  final TransitionType transitionType;

  PremiumPageTransition({
    required this.child,
    this.transitionType = TransitionType.fadeSlide,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: AppMotion.getDuration(AppMotion.durationSlow),
          reverseTransitionDuration: AppMotion.getDuration(AppMotion.durationMedium),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            if (AppMotion.shouldDisableAnimations()) {
              return child;
            }

            switch (transitionType) {
              case TransitionType.fade:
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              case TransitionType.slide:
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: AppMotion.getCurve(AppMotion.curveEaseOutCubic),
                  )),
                  child: child,
                );
              case TransitionType.fadeSlide:
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.1),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: AppMotion.getCurve(AppMotion.curveEaseOutCubic),
                    )),
                    child: child,
                  ),
                );
              case TransitionType.scale:
                return ScaleTransition(
                  scale: Tween<double>(
                    begin: 0.95,
                    end: 1.0,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: AppMotion.getCurve(AppMotion.curveEaseOutCubic),
                  )),
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
            }
          },
        );
}

enum TransitionType { fade, slide, fadeSlide, scale }

/// Helper to create premium page route
PageRoute<T> createPremiumPageRoute<T>({
  required Widget page,
  TransitionType transitionType = TransitionType.fadeSlide,
}) {
  return PremiumPageTransition<T>(
    child: page,
    transitionType: transitionType,
  );
}
