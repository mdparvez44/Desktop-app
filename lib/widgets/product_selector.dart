/// Searchable / Dropdown selector for Product Codes.
library;

import 'package:flutter/material.dart';
import '../utils/constants.dart';

class ProductSelector extends StatelessWidget {
  final String selectedProductCode;
  final ValueChanged<String> onChanged;

  const ProductSelector({
    super.key,
    required this.selectedProductCode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final codes = AppConstants.productCodes;
    final value = codes.contains(selectedProductCode) ? selectedProductCode : codes.first;

    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Product Code',
        prefixIcon: Icon(Icons.qr_code_2_outlined),
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      items: codes
          .map((c) => DropdownMenuItem(
                value: c,
                child: Text(c, style: const TextStyle(fontWeight: FontWeight.w600)),
              ))
          .toList(),
      onChanged: (val) {
        if (val != null) onChanged(val);
      },
    );
  }
}
