/// TOTAL and PREVIOUS Total Display Widget positioned above Keypad.
library;

import 'package:flutter/material.dart';
import '../utils/formatters.dart';

class TotalPreviousDisplay extends StatelessWidget {
  final double currentTotal;
  final double previousTotal;

  const TotalPreviousDisplay({
    super.key,
    required this.currentTotal,
    required this.previousTotal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentGross = currentTotal / 144.0;
    final previousGross = previousTotal / 144.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withAlpha(100),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withAlpha(60),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 450;

          if (isNarrow) {
            return Column(
              children: [
                _buildValueBlock(
                  context,
                  label: 'TOTAL',
                  value: AppFormatters.formatNumber(currentTotal),
                  grossText: '${AppFormatters.formatGross(currentGross)} grs',
                  isPrimary: true,
                ),
                const SizedBox(height: 8),
                _buildValueBlock(
                  context,
                  label: 'PREVIOUS',
                  value: AppFormatters.formatNumber(previousTotal),
                  grossText: '${AppFormatters.formatGross(previousGross)} grs',
                  isPrimary: false,
                ),
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: _buildValueBlock(
                  context,
                  label: 'TOTAL',
                  value: AppFormatters.formatNumber(currentTotal),
                  grossText: '${AppFormatters.formatGross(currentGross)} grs',
                  isPrimary: true,
                ),
              ),
              const SizedBox(height: 36, child: VerticalDivider()),
              Expanded(
                child: _buildValueBlock(
                  context,
                  label: 'PREVIOUS',
                  value: AppFormatters.formatNumber(previousTotal),
                  grossText: '${AppFormatters.formatGross(previousGross)} grs',
                  isPrimary: false,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildValueBlock(
    BuildContext context, {
    required String label,
    required String value,
    required String grossText,
    required bool isPrimary,
  }) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isPrimary ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isPrimary ? Colors.teal.shade100 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                grossText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isPrimary ? Colors.teal.shade900 : Colors.grey.shade800,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
