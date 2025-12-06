import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../models/scanned_product.dart';
import '../providers/cloud_cart_provider.dart';
import '../widgets/scan_error_dialog.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({Key? key}) : super(key: key);

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  late MobileScannerController _scannerController;
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      autoStart: true,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _handleBarcodeDetect(BarcodeCapture barcode) {
    if (!_isScanning) return;

    final scannedData = barcode.barcodes.first.rawValue;
    if (scannedData == null || scannedData.isEmpty) return;

    _isScanning = false;

    try {
      final product = ScannedProduct.fromQRCode(scannedData);
      context.read<CloudCartProvider>().addProduct(product);

      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added: ${product.name}'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );

      // Resume scanning after delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _isScanning = true;
          });
        }
      });
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => ScanErrorDialog(error: e.toString()),
      ).then((_) {
        if (mounted) {
          setState(() {
            _isScanning = true;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FRKassa - QR Scanner'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              controller: _scannerController,
              onDetect: _handleBarcodeDetect,
              placeholderBuilder: (context) {
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey[200],
            child: Column(
              children: [
                Text(
                  'Scanned Products: ${context.watch<CloudCartProvider>().productCount}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        _scannerController.toggleTorch();
                      },
                      icon: const Icon(Icons.flashlight_on),
                      label: const Text('Torch'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<CloudCartProvider>().clearCart();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Cart cleared'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Clear Cart'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
