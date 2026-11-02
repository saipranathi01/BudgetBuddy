import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class FinanceBackground extends StatelessWidget {
  const FinanceBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFF8F7FF),
                Color(0xFFF0F6FF),
                Color(0xFFFFF7FA),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        const IgnorePointer(
          child: CustomPaint(painter: _FinanceBackgroundPainter()),
        ),
        child,
      ],
    );
  }
}

class _FinanceBackgroundPainter extends CustomPainter {
  const _FinanceBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final shortest = size.shortestSide;
    final circlePaint = Paint()..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width + shortest * .09, shortest * -.08),
      shortest * .35,
      circlePaint..color = AppColors.lavender.withValues(alpha: .54),
    );
    canvas.drawCircle(
      Offset(shortest * -.11, size.height * .50),
      shortest * .27,
      circlePaint..color = const Color(0xFFDDF5FF).withValues(alpha: .45),
    );

    final wave = Path()
      ..moveTo(0, size.height * .92)
      ..cubicTo(
        size.width * .22,
        size.height * .86,
        size.width * .31,
        size.height * .99,
        size.width * .55,
        size.height * .94,
      )
      ..cubicTo(
        size.width * .77,
        size.height * .89,
        size.width * .88,
        size.height * .96,
        size.width,
        size.height * .90,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      wave,
      Paint()..color = const Color(0xFFE7E6FF).withValues(alpha: .42),
    );

    final dotPaint = Paint()..color = AppColors.pink.withValues(alpha: .26);
    for (final point in <Offset>[
      Offset(size.width * .10, size.height * .15),
      Offset(size.width * .90, size.height * .34),
      Offset(size.width * .88, size.height * .78),
      Offset(size.width * .16, size.height * .88),
    ]) {
      canvas.drawCircle(point, shortest * .008, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FinanceBackgroundPainter oldDelegate) => false;
}
