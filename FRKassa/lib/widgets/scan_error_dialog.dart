import 'package:flutter/material.dart';

class ScanErrorDialog extends StatelessWidget {
  final String error;

  const ScanErrorDialog({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Scan Error'),
      content: Text(error),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
