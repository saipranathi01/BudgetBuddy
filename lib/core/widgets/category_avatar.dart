import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({
    super.key,
    required this.category,
    this.size = 44,
  });

  final String category;
  final double size;

  static const _categoryIcons = <String, IconData>{
    'Food': Icons.restaurant_rounded,
    'Transport': Icons.directions_bus_rounded,
    'Shopping': Icons.shopping_bag_rounded,
    'Education': Icons.menu_book_rounded,
    'Entertainment': Icons.movie_rounded,
    'Health': Icons.favorite_rounded,
    'Bills': Icons.receipt_long_rounded,
    'Other': Icons.category_rounded,
  };

  static const _categoryColors = <String, Color>{
    'Food': AppColors.orange,
    'Transport': AppColors.teal,
    'Shopping': Color(0xFF7359A6),
    'Education': AppColors.navy,
    'Entertainment': Color(0xFFD36B52),
    'Health': AppColors.red,
    'Bills': AppColors.navySecondary,
    'Other': AppColors.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    final color = _categoryColors[category] ?? AppColors.textSecondary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(size * .32),
      ),
      child: Icon(
        _categoryIcons[category] ?? Icons.category_rounded,
        color: color,
        size: size * .5,
      ),
    );
  }
}
