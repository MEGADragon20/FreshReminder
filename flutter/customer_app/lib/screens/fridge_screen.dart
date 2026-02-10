import 'package:flutter/material.dart';
import '../core/fridge_service.dart';
import 'qr_scan_screen.dart';

Color _bgForDays(int daysLeft) {
  if (daysLeft < 0) return Colors.red.shade100;
  if (daysLeft <= 3) return Colors.orange.shade100;
  if (daysLeft <= 7) return Colors.yellow.shade100;
  if (daysLeft <= 14) return Colors.green.shade50;
  return Colors.green.shade100;
}

class FridgeScreen extends StatefulWidget {
  const FridgeScreen({super.key});

  @override
  State<FridgeScreen> createState() => _FridgeScreenState();
}

class _FridgeScreenState extends State<FridgeScreen> {
  final FridgeService _service = FridgeService();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await _service.getFridgeItems();
      setState(() {
        _items = items;
      });
    } catch (_) {
      setState(() {
        _items = [];
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fridge'),
        actions: [
          IconButton(
              onPressed: () async {
                final code = await Navigator.push<String?>(
                    context, MaterialPageRoute(builder: (_) => const QrScanScreen()));
                if (code != null && code.isNotEmpty) {
                  // treat scanned code as remove command by default in fridge view
                  final ok = await _service.removeFridgeItem(code);
                  if (ok) _load();
                }
              },
              icon: const Icon(Icons.qr_code_scanner)),
        ],
      ),
      body: _items.isEmpty
          ? const Center(child: Text('No items in your fridge'))
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, i) {
                final it = _items[i];
                final bbdStr = it['best_before_date'] as String? ?? '';
                DateTime? bbd;
                try {
                  bbd = DateTime.parse(bbdStr);
                } catch (_) {
                  bbd = null;
                }
                final daysLeft = bbd != null ? bbd.difference(DateTime.now()).inDays : 9999;
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  color: _bgForDays(daysLeft),
                  child: ListTile(
                    title: Text(it['product_name'] ?? 'Unnamed', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Qty: ${it['quantity']} • BBD: ${bbdStr.split('T').first}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        final ok = await _service.removeFridgeItem(it['fridge_item_id']);
                        if (ok) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed')));
                          _load();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to remove')));
                        }
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}

