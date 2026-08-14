/// Desktop Production Form View with full keyboard support and auto-calculations.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/production.dart';
import '../providers/settings_provider.dart';
import '../services/calculation_service.dart';
import '../utils/formatters.dart';
import 'machine_selector.dart';
import 'plant_selector.dart';
import 'product_selector.dart';

class DesktopInputView extends StatefulWidget {
  final Production? initialRecord;
  final ValueChanged<Production> onSubmit;
  final VoidCallback? onCancel;

  const DesktopInputView({
    super.key,
    this.initialRecord,
    required this.onSubmit,
    this.onCancel,
  });

  @override
  State<DesktopInputView> createState() => _DesktopInputViewState();
}

class _DesktopInputViewState extends State<DesktopInputView> {
  final _formKey = GlobalKey<FormState>();

  late String _machine;
  late String _plant;
  late String _productCode;
  late String _shift;

  late TextEditingController _goodController;
  late TextEditingController _rejectController;
  late TextEditingController _qaController;
  late TextEditingController _sampleController;

  final FocusNode _goodFocus = FocusNode();
  final FocusNode _rejectFocus = FocusNode();
  final FocusNode _qaFocus = FocusNode();
  final FocusNode _sampleFocus = FocusNode();

  double _calculatedTested = 0.0;
  double _calculatedGross = 0.0;
  double _calculatedRejectionPct = 0.0;

  @override
  void initState() {
    super.initState();
    final p = widget.initialRecord;
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final qcConstant = settings.qcConstant;

    _machine = p?.machine ?? (settings.machines.isNotEmpty ? settings.machines.first : 'A1');
    _plant = p?.plant ?? (settings.plants.isNotEmpty ? settings.plants.first : 'TTK');
    _productCode = p?.productCode ?? (settings.productCodes.isNotEmpty ? settings.productCodes.first : 'N53PM');
    _shift = p?.shift ?? 'Night';

    String formatQA(double savedQA) {
      if (savedQA == 0) return '0';
      if (savedQA % qcConstant == 0) return (savedQA / qcConstant).toInt().toString();
      return (savedQA / qcConstant).toString();
    }

    _goodController = TextEditingController(text: p != null ? (p.good == 0 ? '0' : p.good.toString()) : '0');
    _rejectController = TextEditingController(text: p != null ? (p.reject == 0 ? '0' : p.reject.toString()) : '0');
    _qaController = TextEditingController(text: p != null ? formatQA(p.qa) : '0');
    _sampleController = TextEditingController(text: p != null ? (p.sample == 0 ? '0' : p.sample.toString()) : '0');

    _updateCalculations();
  }

  @override
  void dispose() {
    _goodController.dispose();
    _rejectController.dispose();
    _qaController.dispose();
    _sampleController.dispose();
    _goodFocus.dispose();
    _rejectFocus.dispose();
    _qaFocus.dispose();
    _sampleFocus.dispose();
    super.dispose();
  }

  void _updateCalculations() {
    final qcConstant = Provider.of<SettingsProvider>(context, listen: false).qcConstant;
    final good = double.tryParse(_goodController.text) ?? 0.0;
    final reject = double.tryParse(_rejectController.text) ?? 0.0;
    final qaInput = double.tryParse(_qaController.text) ?? 0.0;
    final savedQA = qaInput * qcConstant;

    setState(() {
      _calculatedTested = CalculationService.calculateTested(good: good, reject: reject, qa: savedQA);
      _calculatedGross = CalculationService.calculateGross(_calculatedTested);
      _calculatedRejectionPct = CalculationService.calculateRejectionPercentage(
        reject: reject,
        tested: _calculatedTested,
      );
    });
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      final qcConstant = Provider.of<SettingsProvider>(context, listen: false).qcConstant;
      final good = double.tryParse(_goodController.text) ?? 0.0;
      final reject = double.tryParse(_rejectController.text) ?? 0.0;
      final qaInput = double.tryParse(_qaController.text) ?? 0.0;
      final sample = double.tryParse(_sampleController.text) ?? 0.0;

      if (good <= 0 && reject <= 0 && qaInput <= 0 && sample <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter production quantities before saving.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
        _goodFocus.requestFocus();
        return;
      }

      final savedQA = qaInput * qcConstant;

      final record = Production(
        id: widget.initialRecord?.id,
        machine: _machine,
        plant: _plant,
        productCode: _productCode,
        good: good,
        reject: reject,
        qa: savedQA,
        sample: sample,
        tested: _calculatedTested,
        shift: _shift,
        createdAt: widget.initialRecord?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      widget.onSubmit(record);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): _handleSave,
        if (widget.onCancel != null)
          const SingleActivator(LogicalKeyboardKey.escape): widget.onCancel!,
      },
      child: Focus(
        autofocus: true,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Selection Row
              Row(
                children: [
                  Expanded(
                    child: MachineSelector(
                      selectedMachine: _machine,
                      onChanged: (val) => setState(() => _machine = val),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: PlantSelector(
                      selectedPlant: _plant,
                      onChanged: (val) => setState(() => _plant = val),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ProductSelector(
                      selectedProductCode: _productCode,
                      onChanged: (val) => setState(() => _productCode = val),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _shift,
                      decoration: const InputDecoration(
                        labelText: 'Shift',
                        prefixIcon: Icon(Icons.wb_sunny_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Night', child: Text('Night Shift')),
                        DropdownMenuItem(value: 'Day', child: Text('Day Shift')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _shift = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Inputs Grid
              Row(
                children: [
                  Expanded(
                    child: _buildNumberField(
                      controller: _goodController,
                      focusNode: _goodFocus,
                      nextFocusNode: _rejectFocus,
                      label: 'Good Product (GP)',
                      icon: Icons.check_circle_outline,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildNumberField(
                      controller: _rejectController,
                      focusNode: _rejectFocus,
                      nextFocusNode: _qaFocus,
                      label: 'Rejected Product (RP)',
                      icon: Icons.cancel_outlined,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildNumberField(
                      controller: _qaController,
                      focusNode: _qaFocus,
                      nextFocusNode: _sampleFocus,
                      label: 'Q.A / QC',
                      icon: Icons.verified_outlined,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildNumberField(
                      controller: _sampleController,
                      focusNode: _sampleFocus,
                      label: 'Samples',
                      icon: Icons.science_outlined,
                      color: Colors.purple,
                      isLast: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Live Calculation Cards Row
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCalculatedItem(
                      context,
                      label: 'Tested (Calculated)',
                      value: AppFormatters.formatNumber(_calculatedTested),
                      subtext: 'Good + Reject + QA',
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 32, child: VerticalDivider()),
                    _buildCalculatedItem(
                      context,
                      label: 'Tested Gross',
                      value: '${AppFormatters.formatGross(_calculatedGross)} grs',
                      subtext: 'Quantity / 144 (Truncated)',
                      color: Colors.teal,
                    ),
                    const SizedBox(height: 32, child: VerticalDivider()),
                    _buildCalculatedItem(
                      context,
                      label: 'Rejection Rate',
                      value: '${AppFormatters.formatGross(_calculatedRejectionPct)}%',
                      subtext: '(Reject / Tested) * 100',
                      color: _calculatedRejectionPct >= 10.0 ? Colors.red : Colors.green,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (widget.onCancel != null) ...[
                    OutlinedButton.icon(
                      onPressed: widget.onCancel,
                      icon: const Icon(Icons.close),
                      label: const Text('Cancel (Esc)'),
                    ),
                    const SizedBox(width: 12),
                  ],
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                    onPressed: _handleSave,
                    icon: const Icon(Icons.save_rounded),
                    label: const Text(
                      'Save Production Entry (Ctrl+S)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocusNode,
    required String label,
    required IconData icon,
    required Color color,
    bool isLast = false,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: color),
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: const Icon(Icons.clear, size: 18),
          onPressed: () {
            controller.text = '0';
            _updateCalculations();
          },
        ),
      ),
      onChanged: (_) => _updateCalculations(),
      onFieldSubmitted: (_) {
        if (nextFocusNode != null) {
          nextFocusNode.requestFocus();
        } else if (isLast) {
          _handleSave();
        }
      },
      validator: (val) {
        if (val == null || val.trim().isEmpty) return 'Please enter a value';
        if (double.tryParse(val) == null) return 'Invalid numeric value';
        return null;
      },
    );
  }

  Widget _buildCalculatedItem(
    BuildContext context, {
    required String label,
    required String value,
    required String subtext,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtext,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
