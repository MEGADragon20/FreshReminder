import 'package:flutter/material.dart';

class LabelingScreen extends StatelessWidget {
  const LabelingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Labeling')),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.label, size: 120, color: Colors.grey),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: () {}, child: const Text('Scan Barcode')),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: () {}, child: const Text('Create Lot')),
        ]),
      ),
    );
  }
}
