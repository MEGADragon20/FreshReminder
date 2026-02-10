import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  MobileScannerController? _controller;
  final TextEditingController _manualCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final unsupported = kIsWeb || Platform.isLinux || Platform.isMacOS || Platform.isWindows;

    if (!unsupported && _controller == null) {
      _controller = MobileScannerController();
    }

    if (unsupported) {
      // Fallback UI for platforms where mobile_scanner plugin isn't implemented
      return Scaffold(
        appBar: AppBar(title: const Text('QR Scanner')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.qr_code, size: 120, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('Camera scanning is not available on this platform.'),
              const SizedBox(height: 12),
              TextField(
                controller: _manualCtrl,
                decoration: const InputDecoration(labelText: 'Paste or type QR code'),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: ElevatedButton(
                      onPressed: () {
                        final code = _manualCtrl.text.trim();
                        if (code.isNotEmpty) Navigator.of(context).pop(code);
                      },
                      child: const Text('Submit')),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                    onPressed: () => Navigator.of(context).pop('SIMULATED_QR'),
                    child: const Text('Simulate'))
              ])
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('QR Scanner')),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: MobileScanner(
              controller: _controller,
              onDetect: (capture) {
                if (capture.barcodes.isEmpty) return;
                final barcode = capture.barcodes.first;
                final String? code = barcode.rawValue;
                if (code != null && mounted) {
                  _controller?.stop();
                  Navigator.of(context).pop(code);
                }
              },
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.close),
                label: const Text('Cancel'),
                onPressed: () {
                  _controller?.stop();
                  Navigator.of(context).pop();
                },
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _manualCtrl.dispose();
    super.dispose();
  }
}
