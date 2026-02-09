import 'package:flutter/material.dart';
import 'cart_screen.dart';

class QrScanScreen extends StatelessWidget {
  const QrScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Scanner')),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.qr_code, size: 120, color: Colors.grey),
          const SizedBox(height: 16),
          ElevatedButton(
              onPressed: () {
                // In real app, open qr scanner then add to cart
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
              },
              child: const Text('Simulate Scan -> Add to Cart')),
        ]),
      ),
    );
  }
}
