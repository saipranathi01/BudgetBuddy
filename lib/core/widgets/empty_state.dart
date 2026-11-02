import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'finance_illustration.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final FinanceIllustrationType? illustrationType;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  const EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.illustrationType,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final compactLayout = compact || MediaQuery.sizeOf(context).height < 480;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (illustrationType != null) ...[
          FinanceIllustration(
            type: illustrationType!,
            width: compactLayout ? 82 : 132,
            height: compactLayout ? 64 : 104,
          ),
          SizedBox(height: compactLayout ? 6 : 12),
        ] else ...[
          Icon(
            icon,
            size: compactLayout ? 30 : 44,
            color: AppColors.navy.withValues(alpha: .7),
          ),
          SizedBox(height: compactLayout ? 6 : 12),
        ],
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary, height: 1.4),
          ),
        ],
        if (actionLabel != null && onAction != null) ...[
          SizedBox(height: compactLayout ? 8 : 14),
          FilledButton.tonalIcon(
            onPressed: onAction,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(actionLabel!),
            style: FilledButton.styleFrom(
              foregroundColor: AppColors.navy,
              backgroundColor: AppColors.lavender,
              minimumSize: Size(0, compactLayout ? 38 : 44),
            ),
          ),
        ],
      ],
    );

    if (compactLayout) {
      return Center(
        child: Padding(padding: const EdgeInsets.all(10), child: content),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 16,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: content,
        ),
      ),
    );
  }
}
