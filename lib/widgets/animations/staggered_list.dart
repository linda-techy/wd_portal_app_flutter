import 'package:flutter/material.dart';
import '../../constants/app_motion.dart';
import 'entrance_animation.dart';

/// Staggered List Animation
/// Provides staggered entrance animations for list items
class StaggeredList extends StatelessWidget {
  final List<Widget> children;
  final Duration staggerDelay;
  final double slideOffset;

  const StaggeredList({
    super.key,
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 50),
    this.slideOffset = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    if (AppMotion.shouldDisableAnimations()) {
      return Column(
        children: children,
      );
    }

    return Column(
      children: children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;
        return EntranceAnimation(
          delay: staggerDelay * index,
          slideOffset: slideOffset,
          child: child,
        );
      }).toList(),
    );
  }
}

/// Staggered Grid Animation
class StaggeredGrid extends StatelessWidget {
  final List<Widget> children;
  final Duration staggerDelay;
  final double slideOffset;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;

  const StaggeredGrid({
    super.key,
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 50),
    this.slideOffset = 20.0,
    required this.crossAxisCount,
    this.crossAxisSpacing = 16.0,
    this.mainAxisSpacing = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    if (AppMotion.shouldDisableAnimations()) {
      return GridView.count(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        children: children,
      );
    }

    return GridView.count(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
      children: children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;
        return EntranceAnimation(
          delay: staggerDelay * index,
          slideOffset: slideOffset,
          child: child,
        );
      }).toList(),
    );
  }
}
