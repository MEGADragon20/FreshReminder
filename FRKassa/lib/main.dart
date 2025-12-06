import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/cloud_cart_provider.dart';
import 'providers/scanner_provider.dart';
import 'screens/main_navigation_screen.dart';

void main() {
  runApp(const FRKassaApp());
}

class FRKassaApp extends StatelessWidget {
  const FRKassaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CloudCartProvider()),
        ChangeNotifierProvider(create: (_) => ScannerProvider()),
      ],
      child: MaterialApp(
        title: 'FRKassa',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const MainNavigationScreen(),
      ),
    );
  }
}
