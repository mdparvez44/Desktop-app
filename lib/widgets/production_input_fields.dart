import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

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
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final enabledGoodOptions = settingsProvider.goodOptions
        .where((o) => o.enabled)
        .map((o) => o.value)
        .toList();
    final rejectionOptions = settingsProvider.rejectionOptions;
    final qcConstant = settingsProvider.qcConstant;
    final qcLabelStr = qcConstant.truncateToDouble() == qcConstant
        ? qcConstant.toInt().toString()
        : qcConstant.toString();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 650;

        if (isNarrow) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextFieldCard(
                      context,
                      label: 'GOOD',
                      controller: goodController,
                      focusNode: goodFocusNode,
                      nextFocusNode: rejectFocusNode,
                      color: Colors.green,
                      options: enabledGoodOptions,
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
                      options: rejectionOptions,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextFieldCard(
                      context,
                      label: 'Q.C (x$qcLabelStr)',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildTextFieldCard(
                context,
                label: 'GOOD',
                controller: goodController,
                focusNode: goodFocusNode,
                nextFocusNode: rejectFocusNode,
                color: Colors.green,
                options: enabledGoodOptions,
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
                options: rejectionOptions,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextFieldCard(
                context,
                label: 'Q.C (x$qcLabelStr)',
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
    List<String>? options,
  }) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: Listenable.merge([focusNode, controller]),
      builder: (context, _) {
        final isFocused = focusNode.hasFocus;
        final currentText = controller.text.trim();

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
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              focusNode.requestFocus();
            },
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
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
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
                  if (options != null && options.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: options.map((opt) {
                        final isCstm = opt.toUpperCase() == 'CSTM';
                        final isSelected = isCstm
                            ? (currentText.isNotEmpty &&
                                !options.where((o) => o != 'CSTM').contains(currentText))
                            : (currentText == opt);

                        return ChoiceChip(
                          visualDensity: VisualDensity.compact,
                          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          label: Text(
                            opt,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: color,
                          onSelected: (selected) {
                            if (isCstm) {
                              focusNode.requestFocus();
                              if (options.where((o) => o != 'CSTM').contains(controller.text.trim())) {
                                controller.clear();
                              }
                            } else {
                              controller.text = opt;
                              if (nextFocusNode != null) {
                                nextFocusNode.requestFocus();
                              }
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
