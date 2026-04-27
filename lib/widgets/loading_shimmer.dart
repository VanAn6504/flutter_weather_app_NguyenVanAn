import 'package:flutter/material.dart';
import '../utils/constants.dart';

class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  const ShimmerBox.fill({
    super.key,
    required this.height,
    this.borderRadius = 8,
  }) : width = double.infinity;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: [
                Colors.white.withValues(alpha: 0.06),
                Colors.white.withValues(alpha: 0.15),
                Colors.white.withValues(alpha: 0.06),
              ],
            ),
          ),
        );
      },
    );
  }
}

class HomeScreenSkeleton extends StatelessWidget {
  const HomeScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDesign.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          // City name
          const ShimmerBox(width: 180, height: 28, borderRadius: 14),
          const SizedBox(height: 8),
          const ShimmerBox(width: 120, height: 18, borderRadius: 9),
          const SizedBox(height: 40),
          // Temperature
          const Center(
              child: ShimmerBox(width: 160, height: 80, borderRadius: 20)),
          const SizedBox(height: 12),
          const Center(
              child: ShimmerBox(width: 200, height: 24, borderRadius: 12)),
          const SizedBox(height: 40),
          // Detail row
          const ShimmerBox.fill(height: 100, borderRadius: 20),
          const SizedBox(height: 20),
          // Hourly list
          const ShimmerBox(width: 140, height: 22, borderRadius: 11),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) => const ShimmerBox(
                width: 70,
                height: 100,
                borderRadius: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
