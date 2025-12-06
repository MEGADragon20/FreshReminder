import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../models/scanned_product.dart';
import '../providers/cloud_cart_provider.dart';
import '../widgets/scan_error_dialog.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({Key? key}) : super(key: key);

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  late final TextEditingController _manualInput;
  bool _useManualInput = Platform.isLinux || Platform.isWindows;
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    _manualInput = TextEditingController();
  }

  @override
  void dispose() {
    _manualInput.dispose();
    super.dispose();
  }

  void _processQRData(String scannedData) {
    if (!_isScanning) return;
    if (scannedData.isEmpty) return;

    _isScanning = false;

    try {
      final product = ScannedProduct.fromQRCode(scannedData);
      context.read<CloudCartProvider>().addProduct(product);

      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hinzugefügt: ${product.name}'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );

      // Clear input and resume scanning
      _manualInput.clear();
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

  Widget _buildManualInputUI() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FRKassa - QR Scanner'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_2, size: 64, color: Colors.blue[300]),
                    const SizedBox(height: 24),
                    Text(
                      'Manuelles Eingeben',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _manualInput,
                      decoration: InputDecoration(
                        hintText: 'Format: Produktname|YYYY-MM-DD|Kategorie',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.edit),
                      ),
                      onSubmitted: _processQRData,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _processQRData(_manualInput.text),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: const Text('Hinzufügen'),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Format:\nProduktname|YYYY-MM-DD|Kategorie\n\nBeispiel:\nMilch|2025-12-15|Milchprodukte',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey[200],
            child: Column(
              children: [
                Text(
                  'Gescannte Produkte: ${context.watch<CloudCartProvider>().productCount}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<CloudCartProvider>().clearCart();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Warenkorb geleert'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete),
                  label: const Text('Warenkorb Löschen'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_useManualInput) {
      return _buildManualInputUI();
    }

    // Mobile camera scanner (Android/iOS)
    return _buildCameraScannerUI();
  }

  Widget _buildCameraScannerUI() {
    // This would be the mobile_scanner version for Android/iOS
    return Scaffold(
      appBar: AppBar(
        title: const Text('FRKassa - QR Scanner'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Kamera-Scanner nicht verfügbar'),
            const SizedBox(height: 8),
            const Text('Manuelle Eingabe verwenden'),
          ],
        ),
      ),
    );
  }
}
