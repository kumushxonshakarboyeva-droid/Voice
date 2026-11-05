import 'dart:math' as math;

import 'package:flutter/material.dart';

class SoundWave extends StatefulWidget {
  const SoundWave({super.key, required this.active, this.color});

  final bool active;
  final Color? color;

  @override
  State<SoundWave> createState() => _SoundWaveState();
}

class _SoundWaveState extends State<SoundWave>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant SoundWave oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.active) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => SizedBox(
        width: 34,
        height: 24,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(5, (index) {
            final phase = widget.active
                ? (_controller.value + index * .17) * math.pi * 2
                : math.pi / 2;
            final height = widget.active
                ? 5 + (math.sin(phase).abs() * 16)
                : 5.0;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 3.5,
              height: height,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }),
        ),
      ),
    );
  }
}
