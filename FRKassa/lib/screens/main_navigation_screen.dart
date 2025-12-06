import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cloud_cart_provider.dart';
import 'scanner_screen.dart';
import 'cart_overview_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const ScannerScreen(),
          const CartOverviewScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.qr_code_scanner),
            label: 'Scan',
            tooltip: 'Scan QR Codes',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.shopping_cart),
            label: 'Cart (${context.watch<CloudCartProvider>().productCount})',
            tooltip: 'View Cart',
          ),
        ],
      ),
    );
  }
}
