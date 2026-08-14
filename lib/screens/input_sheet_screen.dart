/// Desktop Input Entry Screen with physical keyboard text entry, Q.C x 95 conversion, NO on-screen keypad, and automatic ENTER=SAVE flow.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/production.dart';
import '../providers/production_provider.dart';
import '../providers/settings_provider.dart';
import '../services/calculation_service.dart';
import '../utils/constants.dart';
import '../widgets/machine_selector.dart';
import '../widgets/plant_selector.dart';
import '../widgets/product_selector.dart';
import '../widgets/production_input_fields.dart';
import '../widgets/production_table.dart';
import '../widgets/total_previous_display.dart';

class InputSheetScreen extends StatefulWidget {
  final Production? editingRecord;
  final VoidCallback? onClearEditing;

  const InputSheetScreen({
    super.key,
    this.editingRecord,
    this.onClearEditing,
  });

  @override
  State<InputSheetScreen> createState() => _InputSheetScreenState();
}

class _InputSheetScreenState extends State<InputSheetScreen> {
  final TextEditingController _goodController = TextEditingController();
  final TextEditingController _rejectController = TextEditingController();
  final TextEditingController _qaController = TextEditingController();
  final TextEditingController _sampleController = TextEditingController();

  final FocusNode _goodFocusNode = FocusNode();
  final FocusNode _rejectFocusNode = FocusNode();
  final FocusNode _qaFocusNode = FocusNode();
  final FocusNode _sampleFocusNode = FocusNode();

  late String _machine;
  late String _plant;
  late String _productCode;
  late String _shift;

  double _previousTotal = 0.0;
  bool _isSaving = false;

  String _formatQAForInput(double savedQA) {
    final qcConstant = Provider.of<SettingsProvider>(context, listen: false).qcConstant;
    if (savedQA == 0) return '';
    if (savedQA % qcConstant == 0) {
      return (savedQA / qcConstant).toInt().toString();
    }
    return (savedQA / qcConstant).toString();
  }

  @override
  void initState() {
    super.initState();
    final p = widget.editingRecord;
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    _machine = p?.machine ?? (settings.machines.isNotEmpty ? settings.machines.first : AppConstants.defaultMachines.first);
    _plant = p?.plant ?? (settings.plants.isNotEmpty ? settings.plants.first : AppConstants.defaultPlants.first);
    _productCode = p?.productCode ?? (settings.productCodes.isNotEmpty ? settings.productCodes.first : AppConstants.productCodes.first);
    _shift = p?.shift ?? 'Night';

    if (p != null) {
      _goodController.text = p.good == 0 ? '' : p.good.toString();
      _rejectController.text = p.reject == 0 ? '' : p.reject.toString();
      _qaController.text = _formatQAForInput(p.qa);
      _sampleController.text = p.sample == 0 ? '' : p.sample.toString();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _goodFocusNode.requestFocus();
      }
    });
  }

  @override
  void didUpdateWidget(covariant InputSheetScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.editingRecord != oldWidget.editingRecord && widget.editingRecord != null) {
      final p = widget.editingRecord!;
      setState(() {
        _machine = p.machine;
        _plant = p.plant;
        _productCode = p.productCode;
        _shift = p.shift;
        _goodController.text = p.good == 0 ? '' : p.good.toString();
        _rejectController.text = p.reject == 0 ? '' : p.reject.toString();
        _qaController.text = _formatQAForInput(p.qa);
        _sampleController.text = p.sample == 0 ? '' : p.sample.toString();
        _goodFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _goodController.dispose();
    _rejectController.dispose();
    _qaController.dispose();
    _sampleController.dispose();
    _goodFocusNode.dispose();
    _rejectFocusNode.dispose();
    _qaFocusNode.dispose();
    _sampleFocusNode.dispose();
    super.dispose();
  }

  double get _goodVal => double.tryParse(_goodController.text.trim()) ?? 0.0;
  double get _rejectVal => double.tryParse(_rejectController.text.trim()) ?? 0.0;
  double get _qaInputVal => double.tryParse(_qaController.text.trim()) ?? 0.0;
  double get _sampleVal => double.tryParse(_sampleController.text.trim()) ?? 0.0;

  /// Saved Q.C = Entered Q.C x qcConstant
  double get _savedQA {
    final qcConstant = Provider.of<SettingsProvider>(context, listen: false).qcConstant;
    return _qaInputVal * qcConstant;
  }

  /// Tested = Good + Reject + Saved Q.C (Samples NOT included in Tested!)
  double get _currentTested => CalculationService.calculateTested(
        good: _goodVal,
        reject: _rejectVal,
        qa: _savedQA,
      );

  Future<void> _handleSaveRecord() async {
    if (_isSaving) return; // Debounce save

    // Validation: Require at least one non-zero entry
    if (_goodVal <= 0 && _rejectVal <= 0 && _qaInputVal <= 0 && _sampleVal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter production quantities before saving.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      _goodFocusNode.requestFocus();
      return;
    }

    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    final prodProvider = Provider.of<ProductionProvider>(context, listen: false);

    final savedQA = _savedQA;
    final currentTested = _currentTested;

    final record = Production(
      id: widget.editingRecord?.id,
      machine: _machine,
      plant: _plant,
      productCode: _productCode,
      good: _goodVal,
      reject: _rejectVal,
      qa: savedQA,
      sample: _sampleVal,
      tested: currentTested,
      shift: _shift,
      createdAt: widget.editingRecord?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    bool success;
    if (record.id != null) {
      success = await prodProvider.updateProduction(record);
    } else {
      success = await prodProvider.addProduction(record);
    }

    if (success && mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Saved Record: Machine $_machine | Tested: ${currentTested.toStringAsFixed(0)} (Good: ${_goodVal.toStringAsFixed(0)}, Rej: ${_rejectVal.toStringAsFixed(0)}, Q.C: ${savedQA.toStringAsFixed(0)})',
          ),
          backgroundColor: Colors.teal,
          duration: const Duration(seconds: 2),
        ),
      );

      setState(() {
        _previousTotal = currentTested;
        // ONLY clear the four numeric input fields
        _goodController.clear();
        _rejectController.clear();
        _qaController.clear();
        _sampleController.clear();
        // Keep Machine, Product Code, and Plant selected
        widget.onClearEditing?.call();
      });
    } else if (mounted) {
      final errorMsg = prodProvider.errorMessage ?? 'Failed to save production data.';
      debugPrint('SAVE FAILED: $errorMsg');
      messenger.showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }

    setState(() => _isSaving = false);
    // Focus automatically returns to GOOD field for continuous data entry
    _goodFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prodProvider = Provider.of<ProductionProvider>(context);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): _handleSaveRecord,
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): _handleSaveRecord,
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Input Entry Sheet',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Desktop physical keyboard entry with automatic ENTER=SAVE flow and Q.C x 95 conversion',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (widget.editingRecord != null)
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _goodController.clear();
                      _rejectController.clear();
                      _qaController.clear();
                      _sampleController.clear();
                      widget.onClearEditing?.call();
                    });
                    _goodFocusNode.requestFocus();
                  },
                  icon: const Icon(Icons.close),
                  label: const Text('Cancel Editing'),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Main Entry Form Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. TOP ROW: Machine Selector + > Stepper Button + Product Code Selector
                  Row(
                    children: [
                      // Machine Selector + > Button
                      Expanded(
                        child: MachineSelector(
                          selectedMachine: _machine,
                          onChanged: (val) => setState(() => _machine = val),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Product Code Selector
                      Expanded(
                        child: ProductSelector(
                          selectedProductCode: _productCode,
                          onChanged: (val) => setState(() => _productCode = val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 2. PLANT CHECKLIST CHIPS
                  PlantSelector(
                    selectedPlant: _plant,
                    onChanged: (val) => setState(() => _plant = val),
                  ),
                  const SizedBox(height: 20),

                  // 3. FOUR EDITABLE INPUT FIELDS (GOOD, REJ, Q.C, SAMPLES)
                  ProductionInputFields(
                    goodController: _goodController,
                    rejectController: _rejectController,
                    qaController: _qaController,
                    sampleController: _sampleController,
                    goodFocusNode: _goodFocusNode,
                    rejectFocusNode: _rejectFocusNode,
                    qaFocusNode: _qaFocusNode,
                    sampleFocusNode: _sampleFocusNode,
                    onSubmitted: _handleSaveRecord,
                  ),
                  const SizedBox(height: 20),

                  // 4. TOTAL AND PREVIOUS TOTAL DISPLAY (Located directly below 4 inputs, NO KEYPAD!)
                  TotalPreviousDisplay(
                    currentTotal: _currentTested,
                    previousTotal: _previousTotal,
                  ),
                  const SizedBox(height: 20),

                  // 5. SAVE BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      key: const Key('save_production_button'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      onPressed: _isSaving ? null : _handleSaveRecord,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_rounded, size: 24),
                      label: Text(
                        _isSaving ? 'Saving Production Data...' : 'Save Production Data (Enter / Ctrl+S)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // 5. PRODUCTION DATA SHEET TABLE
          Text(
            'Production Data Sheet (${prodProvider.records.length} entries)',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          ProductionTable(
            records: prodProvider.records,
            onEdit: (rec) {
              setState(() {
                _machine = rec.machine;
                _plant = rec.plant;
                _productCode = rec.productCode;
                _shift = rec.shift;
                _goodController.text = rec.good == 0 ? '' : rec.good.toString();
                _rejectController.text = rec.reject == 0 ? '' : rec.reject.toString();
                _qaController.text = _formatQAForInput(rec.qa);
                _sampleController.text = rec.sample == 0 ? '' : rec.sample.toString();
              });
              _goodFocusNode.requestFocus();
            },
            onDelete: (rec) {
              if (rec.id != null) {
                prodProvider.deleteProduction(rec.id!);
              }
            },
          ),
        ],
      ),
    ),
  );
}
}
