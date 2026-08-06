/// Responsive 4 real editable text fields (GOOD, REJ, Q.C, SAMPLES) for desktop physical keyboard entry.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProductionInputFields extends StatelessWidget {
  final TextEditingController goodController;
  final TextEditingController rejectController;
  final TextEditingController qaController;
  final TextEditingController sampleController;

  final FocusNode goodFocusNode;
  final FocusNode rejectFocusNode;
  final FocusNode qaFocusNode;
  final FocusNode sampleFocusNode;

  final VoidCallback onSubmitted;

  const ProductionInputFields({
    super.key,
    required this.goodController,
    required this.rejectController,
    required this.qaController,
    required this.sampleController,
    required this.goodFocusNode,
    required this.rejectFocusNode,
    required this.qaFocusNode,
    required this.sampleFocusNode,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 650;

        if (isNarrow) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildTextFieldCard(
                      context,
                      label: 'GOOD',
                      controller: goodController,
                      focusNode: goodFocusNode,
                      nextFocusNode: rejectFocusNode,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextFieldCard(
                      context,
                      label: 'REJ',
                      controller: rejectController,
                      focusNode: rejectFocusNode,
                      nextFocusNode: qaFocusNode,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildTextFieldCard(
                      context,
                      label: 'Q.C',
                      controller: qaController,
                      focusNode: qaFocusNode,
                      nextFocusNode: sampleFocusNode,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextFieldCard(
                      context,
                      label: 'SAMPLES',
                      controller: sampleController,
                      focusNode: sampleFocusNode,
                      nextFocusNode: null, // Final field triggers submission
                      isFinalField: true,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _buildTextFieldCard(
                context,
                label: 'GOOD',
                controller: goodController,
                focusNode: goodFocusNode,
                nextFocusNode: rejectFocusNode,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextFieldCard(
                context,
                label: 'REJ',
                controller: rejectController,
                focusNode: rejectFocusNode,
                nextFocusNode: qaFocusNode,
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextFieldCard(
                context,
                label: 'Q.C',
                controller: qaController,
                focusNode: qaFocusNode,
                nextFocusNode: sampleFocusNode,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextFieldCard(
                context,
                label: 'SAMPLES',
                controller: sampleController,
                focusNode: sampleFocusNode,
                nextFocusNode: null,
                isFinalField: true,
                color: Colors.purple,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextFieldCard(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocusNode,
    bool isFinalField = false,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: focusNode,
      builder: (context, _) {
        final isFocused = focusNode.hasFocus;

        return Card(
          elevation: isFocused ? 4 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isFocused ? color : theme.colorScheme.outlineVariant,
              width: isFocused ? 2.5 : 1.0,
            ),
          ),
          color: isFocused ? color.withAlpha(18) : theme.colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: isFocused ? color : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (isFocused)
                      Icon(
                        Icons.edit_note,
                        size: 18,
                        color: color,
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: isFinalField ? TextInputAction.done : TextInputAction.next,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isFocused ? color : theme.colorScheme.onSurface,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    hintText: '0',
                  ),
                  onSubmitted: (_) {
                    if (nextFocusNode != null) {
                      nextFocusNode.requestFocus();
                    } else {
                      onSubmitted();
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
