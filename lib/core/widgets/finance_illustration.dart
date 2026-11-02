import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum FinanceIllustrationType { expenses, savings, budget, analytics }

class FinanceIllustration extends StatelessWidget {
  const FinanceIllustration({
    super.key,
    required this.type,
    this.width = 132,
    this.height = 104,
  });

  final FinanceIllustrationType type;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: _FinanceIllustrationPainter(type),
        ),
      ),
    );
  }
}

class _FinanceIllustrationPainter extends CustomPainter {
  const _FinanceIllustrationPainter(this.type);

  final FinanceIllustrationType type;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 132;
    canvas.save();
    canvas.scale(scale, size.height / 104);

    final backgroundPaint = Paint()..color = AppColors.lavender;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(8, 7, 116, 90),
        const Radius.circular(32),
      ),
      backgroundPaint,
    );
    canvas.drawCircle(
      const Offset(106, 21),
      10,
      Paint()..color = const Color(0xFFD8F7F2),
    );
    canvas.drawCircle(
      const Offset(24, 79),
      7,
      Paint()..color = const Color(0xFFFFE9C7),
    );

    switch (type) {
      case FinanceIllustrationType.expenses:
        _drawReceipt(canvas);
        _drawWallet(canvas, left: 50, top: 42);
        break;
      case FinanceIllustrationType.savings:
        _drawSavingsJar(canvas);
        break;
      case FinanceIllustrationType.budget:
        _drawWallet(canvas, left: 29, top: 35);
        _drawTarget(canvas);
        break;
      case FinanceIllustrationType.analytics:
        _drawAnalytics(canvas);
        break;
    }

    canvas.restore();
  }

  void _drawReceipt(Canvas canvas) {
    final paper = Paint()..color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(36, 18, 47, 64),
        const Radius.circular(8),
      ),
      paper,
    );
    final linePaint = Paint()
      ..color = AppColors.navy.withValues(alpha: .22)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final y = 34.0 + i * 11;
      canvas.drawLine(Offset(45, y), Offset(72, y), linePaint);
    }
    canvas.drawCircle(
      const Offset(72, 69),
      7,
      Paint()..color = const Color(0xFFFFE5B5),
    );
    canvas.drawCircle(
      const Offset(72, 69),
      3,
      Paint()..color = AppColors.orange,
    );
  }

  void _drawWallet(Canvas canvas, {required double left, required double top}) {
    final walletPaint = Paint()..color = AppColors.navy;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, 60, 40),
        const Radius.circular(10),
      ),
      walletPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left + 27, top + 11, 39, 19),
        const Radius.circular(7),
      ),
      Paint()..color = AppColors.blue,
    );
    canvas.drawCircle(
      Offset(left + 55, top + 20.5),
      2.5,
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left + 8, top + 7, 26, 4),
        const Radius.circular(2),
      ),
      Paint()..color = AppColors.teal,
    );
  }

  void _drawSavingsJar(Canvas canvas) {
    final jar = RRect.fromRectAndRadius(
      const Rect.fromLTWH(36, 36, 60, 47),
      const Radius.circular(13),
    );
    canvas.drawRRect(jar, Paint()..color = const Color(0xFFBDEFE8));
    canvas.drawRRect(
      jar,
      Paint()
        ..color = AppColors.teal
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(34, 31, 64, 10),
        const Radius.circular(5),
      ),
      Paint()..color = AppColors.teal,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(52, 27, 28, 5),
        const Radius.circular(3),
      ),
      Paint()..color = AppColors.navy,
    );
    for (var i = 0; i < 3; i++) {
      final x = 49.0 + i * 13;
      canvas.drawCircle(
        Offset(x, 61 - (i % 2) * 9),
        8,
        Paint()..color = AppColors.orange,
      );
      canvas.drawCircle(
        Offset(x, 61 - (i % 2) * 9),
        5,
        Paint()
          ..color = const Color(0xFFFFF1D7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  void _drawTarget(Canvas canvas) {
    const center = Offset(99, 29);
    for (final entry in <(double, Color)>[
      (14, AppColors.teal),
      (9, Colors.white),
      (4, AppColors.orange),
    ]) {
      canvas.drawCircle(center, entry.$1, Paint()..color = entry.$2);
    }
    final arrow = Paint()
      ..color = AppColors.navy
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(83, 44), const Offset(96, 31), arrow);
    canvas.drawLine(const Offset(91, 31), const Offset(96, 31), arrow);
    canvas.drawLine(const Offset(96, 31), const Offset(96, 36), arrow);
  }

  void _drawAnalytics(Canvas canvas) {
    final barPaints = [
      Paint()..color = const Color(0xFFB9B5FF),
      Paint()..color = AppColors.blue,
      Paint()..color = AppColors.teal,
      Paint()..color = const Color(0xFF86DED2),
    ];
    const heights = [27.0, 42.0, 34.0, 54.0];
    for (var i = 0; i < heights.length; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(31 + i * 18, 77 - heights[i], 11, heights[i]),
          const Radius.circular(5),
        ),
        barPaints[i],
      );
    }
    canvas.drawLine(
      const Offset(25, 79),
      const Offset(105, 79),
      Paint()
        ..color = AppColors.navy.withValues(alpha: .3)
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      const Offset(96, 24),
      11,
      Paint()..color = const Color(0xFFFFE9C7),
    );
    canvas.drawLine(
      const Offset(91, 28),
      const Offset(96, 23),
      Paint()
        ..color = AppColors.orange
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      const Offset(96, 23),
      const Offset(101, 26),
      Paint()
        ..color = AppColors.orange
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _FinanceIllustrationPainter oldDelegate) =>
      oldDelegate.type != type;
}
