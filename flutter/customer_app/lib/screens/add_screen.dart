import 'package:flutter/material.dart';
import '../core/fridge_service.dart';
import 'qr_scan_screen.dart';

class AddScreen extends StatefulWidget {
  const AddScreen({super.key});

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  final FridgeService _service = FridgeService();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _quantityCtrl = TextEditingController(text: '1');
  DateTime? _bbd;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _bbd ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _bbd = picked);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(labelText: 'Product name'),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _quantityCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantity'),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today),
            label: Text(_bbd == null ? 'Pick BBD' : _bbd!.toIso8601String().split('T').first),
          )
        ]),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add Item'),
          onPressed: () async {
            final name = _nameCtrl.text.trim();
            final qty = int.tryParse(_quantityCtrl.text.trim()) ?? 1;
            final bbd = _bbd ?? DateTime.now().add(const Duration(days: 7));
            if (name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide a name')));
              return;
            }
            final body = {
              'product_name': name,
              'quantity': qty,
              'best_before_date': bbd.toIso8601String().split('T').first,
            };
            final ok = await _service.addFridgeItem(body);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Added' : 'Failed to add')));
            if (ok) {
              _nameCtrl.clear();
              _quantityCtrl.text = '1';
              setState(() => _bbd = null);
            }
          },
        ),
        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 8),
        ElevatedButton.icon(
            onPressed: () async {
              final code = await Navigator.push<String?>(context, MaterialPageRoute(builder: (_) => const QrScanScreen()));
              if (code != null && code.isNotEmpty) {
                final ok = await _service.addFridgeItemByCode(code);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Added' : 'Failed to add')));
              }
            },
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan to Add'))
      ]),
    );
  }
}
