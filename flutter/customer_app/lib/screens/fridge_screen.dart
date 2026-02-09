import 'package:flutter/material.dart';
import '../core/fridge_service.dart';

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
    if (_items.isEmpty) return const Center(child: Text('No items in your fridge'));

    return ListView.builder(
      itemCount: _items.length,
      itemBuilder: (context, i) {
        final it = _items[i];
        return ListTile(
          title: Text(it['product_name'] ?? 'Unnamed'),
          subtitle: Text('Qty: ${it['quantity']} • BBD: ${it['best_before_date']}'),
        );
      },
    );
  }
}

