import 'package:flutter/material.dart';

class ListaSkeleton extends StatefulWidget {
  final int itemCount;
  final double height;

  const ListaSkeleton({
    super.key,
    this.itemCount = 5,
    this.height = 80.0,
  });

  @override
  State<ListaSkeleton> createState() => _ListaSkeletonState();
}

class _ListaSkeletonState extends State<ListaSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.8).animate(
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
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: widget.itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final colorSkeleton =
            isDark ? const Color(0xFF3D3D3D) : const Color(0xFFE5E7EB);
        return FadeTransition(
          opacity: _animation,
          child: Container(
            height: widget.height,
            decoration: BoxDecoration(
              color: colorSkeleton,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
    );
  }
}
