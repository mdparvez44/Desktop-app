/// Professional Plant & Product Code-wise Daily Production Report Screen upgraded with Monthly Report Totals and Filter Navbar.
library;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/plant_product_report.dart';
import '../providers/production_provider.dart';
import '../services/calculation_service.dart';
import '../utils/formatters.dart';
import '../utils/truncate_utils.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  // Filter navbar state
  bool _isDateRangeMode = false;
  DateTime? _selectedSingleDate;
  DateTimeRange? _selectedDateRange;

  String _selectedShift = 'All Shifts';
  String _selectedPlant = 'All Plants';
  String _selectedProductCode = 'All Product Codes';
  final TextEditingController _moreRejectionController =
      TextEditingController();

  @override
  void dispose() {
    _moreRejectionController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _isDateRangeMode = false;
      _selectedSingleDate = null;
      _selectedDateRange = null;
      _selectedShift = 'All Shifts';
      _selectedPlant = 'All Plants';
      _selectedProductCode = 'All Product Codes';
      _moreRejectionController.clear();
    });
  }

  Future<void> _handleImportExcel(
    BuildContext context,
    ProductionProvider prodProvider,
  ) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        final fileName = file.name;
        final bytes = file.bytes;

        if (bytes != null) {
          final importResult = await prodProvider.importExcel(
            bytes,
            fileName: fileName,
          );

          if (importResult.validRecords.isNotEmpty) {
            if (context.mounted) {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Successfully imported ${importResult.validRecords.length} records.',
                  ),
                  backgroundColor: Colors.teal,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import Excel file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prodProvider = Provider.of<ProductionProvider>(context);
    final records = prodProvider.records;

    // Available dynamic filter dropdown options
    final plantOptions = [
      'All Plants',
      ...records.map((r) => r.plant).toSet().toList()..sort(),
    ];
    final productOptions = [
      'All Product Codes',
      ...records.map((r) => r.productCode).toSet().toList()..sort(),
    ];
    const shiftOptions = ['All Shifts', 'First', 'Second', 'Night'];

    // Filter production records based on active navbar selections
    final filteredRecords = records.where((r) {
      // 1. Date Filter
      if (!_isDateRangeMode && _selectedSingleDate != null) {
        final sameDate =
            r.createdAt.year == _selectedSingleDate!.year &&
            r.createdAt.month == _selectedSingleDate!.month &&
            r.createdAt.day == _selectedSingleDate!.day;
        if (!sameDate) return false;
      } else if (_isDateRangeMode && _selectedDateRange != null) {
        final start = DateTime(
          _selectedDateRange!.start.year,
          _selectedDateRange!.start.month,
          _selectedDateRange!.start.day,
        );
        final end = DateTime(
          _selectedDateRange!.end.year,
          _selectedDateRange!.end.month,
          _selectedDateRange!.end.day,
          23,
          59,
          59,
        );
        if (r.createdAt.isBefore(start) || r.createdAt.isAfter(end)) {
          return false;
        }
      }

      // 2. Shift Filter
      if (_selectedShift != 'All Shifts' && _selectedShift.isNotEmpty) {
        if (r.shift.toLowerCase() != _selectedShift.toLowerCase()) {
          return false;
        }
      }

      // 3. Plant Filter
      if (_selectedPlant != 'All Plants' && _selectedPlant.isNotEmpty) {
        if (r.plant != _selectedPlant) return false;
      }

      // 4. Product Code Filter
      if (_selectedProductCode != 'All Product Codes' &&
          _selectedProductCode.isNotEmpty) {
        if (r.productCode != _selectedProductCode) return false;
      }

      // 5. More Rejection Filter (Rejection >= threshold)
      final rejInput = _moreRejectionController.text.trim();
      if (rejInput.isNotEmpty) {
        final threshold = double.tryParse(rejInput);
        if (threshold != null) {
          final rejGross = truncateTo2(r.reject / 144.0);
          if (rejGross < threshold && r.reject < threshold) {
            return false;
          }
        }
      }

      return true;
    }).toList();

    // Compute Plant and Product Code-wise aggregated report from filtered records
    final reportSummary = CalculationService.computePlantProductReport(
      filteredRecords,
    );
    final productWiseRows = CalculationService.computeProductWiseDailyReport(
      filteredRecords,
    );

    final overall = reportSummary.overallTotal;
    final iml = reportSummary.imlTotal;
    final ttk = reportSummary.ttkTotal;

    final hasActiveFilters =
        _selectedSingleDate != null ||
        _selectedDateRange != null ||
        _selectedShift != 'All Shifts' ||
        _selectedPlant != 'All Plants' ||
        _selectedProductCode != 'All Product Codes' ||
        _moreRejectionController.text.trim().isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Header with Import Action Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Production Reports',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Plant-wise, Product Code-wise, and Monthly Summary Totals (Overall, IML, TTK)',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () => _handleImportExcel(context, prodProvider),
                icon: const Icon(Icons.file_upload_outlined),
                label: const Text('Import Excel'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // REPORT FILTER NAVBAR
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Date Mode Switcher (Single Date / Range)
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: false,
                        label: Text('Single Date'),
                        icon: Icon(Icons.event_outlined, size: 16),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text('Date Range'),
                        icon: Icon(Icons.date_range_outlined, size: 16),
                      ),
                    ],
                    selected: {_isDateRangeMode},
                    onSelectionChanged: (val) {
                      setState(() {
                        _isDateRangeMode = val.first;
                      });
                    },
                  ),

                  // Date Picker Button
                  if (!_isDateRangeMode)
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedSingleDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => _selectedSingleDate = picked);
                        }
                      },
                      icon: const Icon(Icons.calendar_month_outlined, size: 18),
                      label: Text(
                        _selectedSingleDate == null
                            ? 'Date: All'
                            : 'Date: ${AppFormatters.formatDate(_selectedSingleDate!)}',
                      ),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          initialDateRange: _selectedDateRange,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => _selectedDateRange = picked);
                        }
                      },
                      icon: const Icon(Icons.date_range_rounded, size: 18),
                      label: Text(
                        _selectedDateRange == null
                            ? 'Range: All'
                            : '${AppFormatters.formatDate(_selectedDateRange!.start)} - ${AppFormatters.formatDate(_selectedDateRange!.end)}',
                      ),
                    ),

                  // Shift Dropdown Filter
                  DropdownButton<String>(
                    value: _selectedShift,
                    underline: const SizedBox(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedShift = val);
                    },
                    items: shiftOptions.map((s) {
                      return DropdownMenuItem(
                        value: s,
                        child: Text(
                          'Shift: $s',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      );
                    }).toList(),
                  ),

                  // Plant Dropdown Filter
                  DropdownButton<String>(
                    value: plantOptions.contains(_selectedPlant)
                        ? _selectedPlant
                        : 'All Plants',
                    underline: const SizedBox(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedPlant = val);
                    },
                    items: plantOptions.map((p) {
                      return DropdownMenuItem(
                        value: p,
                        child: Text(
                          p == 'All Plants' ? 'Plant: All' : 'Plant: $p',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      );
                    }).toList(),
                  ),

                  // Product Code Dropdown Filter
                  DropdownButton<String>(
                    value: productOptions.contains(_selectedProductCode)
                        ? _selectedProductCode
                        : 'All Product Codes',
                    underline: const SizedBox(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedProductCode = val);
                      }
                    },
                    items: productOptions.map((code) {
                      return DropdownMenuItem(
                        value: code,
                        child: Text(
                          code == 'All Product Codes'
                              ? 'Product: All'
                              : 'Product: $code',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      );
                    }).toList(),
                  ),

                  // More Rejection Input Filter
                  SizedBox(
                    width: 150,
                    child: TextField(
                      controller: _moreRejectionController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'More Rej >=',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),

                  // Reset Filters Button
                  if (hasActiveFilters)
                    TextButton.icon(
                      onPressed: _resetFilters,
                      icon: const Icon(
                        Icons.clear_all_rounded,
                        color: Colors.red,
                      ),
                      label: const Text(
                        'Reset Filters',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 1. MONTHLY SUMMARY TOTALS (THREE REQUIRED TOTALS: OVERALL, IML, TTK)
          Text(
            'Monthly Summary Totals',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  theme.colorScheme.surfaceContainerHigh,
                ),
                columns: const [
                  DataColumn(
                    label: Text(
                      'TOTAL CATEGORY',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'TESTED GROSS',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text(
                      'GOOD GROSS',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text(
                      'REJECTION GROSS',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text(
                      'Q.C GROSS',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text(
                      'REJECTION %',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    numeric: true,
                  ),
                ],
                rows: [
                  // TOTAL 1 - Overall Total
                  DataRow(
                    cells: [
                      const DataCell(
                        Text(
                          'Overall Total',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(
                        Text(AppFormatters.formatGross(overall.testedGross)),
                      ),
                      DataCell(
                        Text(AppFormatters.formatGross(overall.goodGross)),
                      ),
                      DataCell(
                        Text(AppFormatters.formatGross(overall.rejectionGross)),
                      ),
                      DataCell(
                        Text(AppFormatters.formatGross(overall.totalQCGross)),
                      ),
                      DataCell(
                        Text(
                          '${overall.rejectionPercentage.toStringAsFixed(2)}%',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  // TOTAL 2 - IML Total (Excluding TTK)
                  DataRow(
                    cells: [
                      const DataCell(
                        Text(
                          'IML Total ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(
                        Text(AppFormatters.formatGross(iml.testedGross)),
                      ),
                      DataCell(Text(AppFormatters.formatGross(iml.goodGross))),
                      DataCell(
                        Text(AppFormatters.formatGross(iml.rejectionGross)),
                      ),
                      DataCell(
                        Text(AppFormatters.formatGross(iml.totalQCGross)),
                      ),
                      DataCell(
                        Text(
                          '${iml.rejectionPercentage.toStringAsFixed(2)}%',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  // TOTAL 3 - TTK Total (Only TTK)
                  DataRow(
                    cells: [
                      const DataCell(
                        Text(
                          'TTK Total ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(
                        Text(AppFormatters.formatGross(ttk.testedGross)),
                      ),
                      DataCell(Text(AppFormatters.formatGross(ttk.goodGross))),
                      DataCell(
                        Text(AppFormatters.formatGross(ttk.rejectionGross)),
                      ),
                      DataCell(
                        Text(AppFormatters.formatGross(ttk.totalQCGross)),
                      ),
                      DataCell(
                        Text(
                          '${ttk.rejectionPercentage.toStringAsFixed(2)}%',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // 2. PRODUCT CODE-WISE PERFORMANCE TABLE
          Text(
            'Product Code Performance Table',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: productWiseRows.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: Text('No product code data found.')),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        theme.colorScheme.surfaceContainerHigh,
                      ),
                      columns: const [
                        DataColumn(
                          label: Text(
                            'Product Code',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Tested',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          numeric: true,
                        ),
                        DataColumn(
                          label: Text(
                            'Good',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          numeric: true,
                        ),
                        DataColumn(
                          label: Text(
                            'Rejection',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          numeric: true,
                        ),
                        DataColumn(
                          label: Text(
                            'Q.C',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          numeric: true,
                        ),
                        DataColumn(
                          label: Text(
                            'Rejection Percentage',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          numeric: true,
                        ),
                      ],
                      rows: [
                        ...productWiseRows.map((r) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  r.displayProductCode,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(AppFormatters.formatGross(r.testedGross)),
                              ),
                              DataCell(
                                Text(AppFormatters.formatGross(r.goodGross)),
                              ),
                              DataCell(
                                Text(
                                  AppFormatters.formatGross(r.rejectionGross),
                                ),
                              ),
                              DataCell(
                                Text(AppFormatters.formatGross(r.totalQCGross)),
                              ),
                              DataCell(
                                Text(
                                  '${r.rejectionPercentage.toStringAsFixed(2)}%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: r.rejectionPercentage >= 10.0
                                        ? Colors.red
                                        : Colors.green.shade700,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 32),

          // 3. PLANT PERFORMANCE TABLE
          Text(
            'Plant Performance Table',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: reportSummary.plantGroups.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: Text('No production data found.')),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        theme.colorScheme.surfaceContainerHigh,
                      ),
                      columns: const [
                        DataColumn(
                          label: Text(
                            'Plant',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Code',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Tested',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          numeric: true,
                        ),
                        DataColumn(
                          label: Text(
                            'Good',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          numeric: true,
                        ),
                        DataColumn(
                          label: Text(
                            'Rejection',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          numeric: true,
                        ),
                        DataColumn(
                          label: Text(
                            'QC',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          numeric: true,
                        ),
                        DataColumn(
                          label: Text(
                            'Rejection Percentage',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          numeric: true,
                        ),
                      ],
                      rows: _buildReportDataRows(theme, reportSummary),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  List<DataRow> _buildReportDataRows(
    ThemeData theme,
    OverallReportSummary summary,
  ) {
    final List<DataRow> rows = [];

    for (final group in summary.plantGroups) {
      for (final r in group.rows) {
        rows.add(
          DataRow(
            cells: [
              DataCell(
                Text(
                  r.plant,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataCell(
                Text(
                  r.productCode,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              DataCell(Text(AppFormatters.formatGross(r.testedGross))),
              DataCell(Text(AppFormatters.formatGross(r.goodGross))),
              DataCell(Text(AppFormatters.formatGross(r.rejectionGross))),
              DataCell(Text(AppFormatters.formatGross(r.totalQCGross))),
              DataCell(
                Text(
                  '${r.rejectionPercentage.toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: r.rejectionPercentage >= 10.0
                        ? Colors.red
                        : Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }

    // Overall Total Row
    rows.add(
      DataRow(
        color: WidgetStateProperty.all(theme.colorScheme.surfaceContainerHigh),
        cells: [
          const DataCell(
            Text(
              'OVERALL TOTAL',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          const DataCell(Text('-')),
          DataCell(
            Text(
              AppFormatters.formatGross(summary.testedGross),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          DataCell(
            Text(
              AppFormatters.formatGross(summary.goodGross),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          DataCell(
            Text(
              AppFormatters.formatGross(summary.rejectionGross),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          DataCell(
            Text(
              AppFormatters.formatGross(summary.totalQCGross),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          DataCell(
            Text(
              '${summary.rejectionPercentage.toStringAsFixed(2)}%',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ],
      ),
    );

    return rows;
  }
}
