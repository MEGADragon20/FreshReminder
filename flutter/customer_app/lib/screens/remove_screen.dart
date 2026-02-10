import 'package:flutter/material.dart';
import '../core/fridge_service.dart';
import 'qr_scan_screen.dart';

class RemoveScreen extends StatefulWidget {
  const RemoveScreen({super.key});

  @override
  State<RemoveScreen> createState() => _RemoveScreenState();
}

class _RemoveScreenState extends State<RemoveScreen> {
  final FridgeService _service = FridgeService();
  final TextEditingController _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          TextField(
            controller: _ctrl,
            decoration: const InputDecoration(labelText: 'Enter item code to remove'),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remove by Code'),
                onPressed: () async {
                  final code = _ctrl.text.trim();
                  if (code.isEmpty) return;
                  final ok = await _service.removeFridgeItem(code);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Removed' : 'Failed to remove')));
                },
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
                onPressed: () async {
                  final code = await Navigator.push<String?>(context, MaterialPageRoute(builder: (_) => const QrScanScreen()));
                  if (code != null && code.isNotEmpty) {
                    final ok = await _service.removeFridgeItem(code);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Removed' : 'Failed to remove')));
                  }
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan'))
          ])
        ],
      ),
    );
  }
}
