import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

void main() {
  runApp(const FreshReminderApp());
}

class FreshReminderApp extends StatelessWidget {
  const FreshReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FreshReminder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // Dummy-Produkte für die Demo
  final List<Product> _products = [
    Product(
      name: 'Milch',
      expirationDate: DateTime.now().add(const Duration(days: 2)),
      category: 'Milchprodukte',
    ),
    Product(
      name: 'Joghurt',
      expirationDate: DateTime.now().add(const Duration(days: 5)),
      category: 'Milchprodukte',
    ),
    Product(
      name: 'Salat',
      expirationDate: DateTime.now().add(const Duration(days: 1)),
      category: 'Gemüse',
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _addProductsFromScan(List<Product> newProducts) {
    setState(() {
      _products.addAll(newProducts);
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      ProductListPage(products: _products),
      ScannerPage(onProductsScanned: _addProductsFromScan),
      const ProfilePage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('FreshReminder'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.kitchen),
            label: 'Produkte',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Scannen',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                _showAddProductDialog(context);
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showAddProductDialog(BuildContext context) {
    final nameController = TextEditingController();
    final categoryController = TextEditingController(text: 'Sonstiges');
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Produkt hinzufügen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Produktname',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Kategorie',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Ablaufdatum'),
                subtitle: Text(_formatDate(selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setDialogState(() {
                      selectedDate = picked;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    _products.add(Product(
                      name: nameController.text,
                      expirationDate: selectedDate,
                      category: categoryController.text,
                    ));
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${nameController.text} hinzugefügt'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Hinzufügen'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}

// Produktliste
class ProductListPage extends StatelessWidget {
  final List<Product> products;

  const ProductListPage({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    final sortedProducts = List<Product>.from(products)
      ..sort((a, b) => a.expirationDate.compareTo(b.expirationDate));

    return sortedProducts.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Keine Produkte vorhanden',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Scanne einen Kassenbon oder füge\nProdukte manuell hinzu',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          )
        : ListView.builder(
            itemCount: sortedProducts.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              return ProductCard(product: sortedProducts[index]);
            },
          );
  }
}

// Produkt-Karte
class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  Color _getExpirationColor() {
    final daysLeft = product.expirationDate.difference(DateTime.now()).inDays;
    if (daysLeft <= 1) return Colors.red;
    if (daysLeft <= 3) return Colors.orange;
    return Colors.green;
  }

  String _getExpirationText() {
    final daysLeft = product.expirationDate.difference(DateTime.now()).inDays;
    if (daysLeft < 0) return 'Abgelaufen';
    if (daysLeft == 0) return 'Läuft heute ab';
    if (daysLeft == 1) return 'Läuft morgen ab';
    return 'Noch $daysLeft Tage';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getExpirationColor().withOpacity(0.2),
          child: Icon(
            Icons.shopping_basket,
            color: _getExpirationColor(),
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(product.category),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _getExpirationText(),
              style: TextStyle(
                color: _getExpirationColor(),
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _formatDate(product.expirationDate),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}

// QR-Code Scanner mit Live-Preview
class ScannerPage extends StatefulWidget {
  final Function(List<Product>) onProductsScanned;

  const ScannerPage({super.key, required this.onProductsScanned});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  MobileScannerController? cameraController;
  bool _isScanning = false;
  bool _scannerActive = false;
  bool _torchEnabled = false;
  late final bool _scannerSupported;

  @override
  void initState() {
    super.initState();
    _scannerSupported = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    if (_scannerSupported) {
      cameraController = MobileScannerController();
    }
  }

  @override
  void dispose() {
    cameraController?.dispose();
    super.dispose();
  }

  void _toggleTorch() async {
    if (!_scannerActive || cameraController == null) return;

    try {
      await cameraController!.toggleTorch();
      setState(() {
        _torchEnabled = !_torchEnabled;
      });
    } catch (e) {
      print('Torch nicht verfügbar: $e');
    }
  }

  Future<void> _startScanner() async {
    if (!_scannerSupported) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Scanner auf diesem Gerät nicht verfügbar'),
        ));
      }
      return;
    }

    setState(() {
      _scannerActive = true;
      _isScanning = false;
    });

    // Warte kurz bis Scanner bereit ist
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      await cameraController?.start();
    } catch (e) {
      print('Scanner Start Fehler: $e');
    }
  }

  void _stopScanner() async {
    try {
      await cameraController?.stop();
    } catch (e) {
      print('Scanner Stop Fehler: $e');
    }
    setState(() {
      _scannerActive = false;
      _torchEnabled = false;
    });
  }

  Future<void> _handleQRCode(String code) async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
    });

    _stopScanner();

    // Simuliere API-Call zum Backend
    await Future.delayed(const Duration(seconds: 1));

    // Demo: Generiere Produkte aus dem QR-Code
    final newProducts = _simulateProductImport(code);

    widget.onProductsScanned(newProducts);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${newProducts.length} Produkte importiert!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // Wechsle zur Produktliste
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        DefaultTabController.of(context).animateTo(0);
      }
    }
  }

  List<Product> _simulateProductImport(String qrCode) {
    // Simuliere Import von Produkten basierend auf QR-Code
    // In Realität würde hier ein API-Call stattfinden
    return [
      Product(
        name: 'Schokolade',
        expirationDate: DateTime.now().add(const Duration(days: 30)),
        category: 'Süßwaren',
      ),
      Product(
        name: 'Butter',
        expirationDate: DateTime.now().add(const Duration(days: 14)),
        category: 'Milchprodukte',
      ),
      Product(
        name: 'Äpfel',
        expirationDate: DateTime.now().add(const Duration(days: 7)),
        category: 'Obst',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (!_scannerActive) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_scanner,
              size: 100,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            const Text(
              'QR-Code Scanner',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _scannerSupported
                    ? 'Scanne den QR-Code auf deinem Kassenbon, um Produkte automatisch zu importieren'
                    : 'Der QR-Code Scanner ist auf diesem Gerät nicht verfügbar',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _scannerSupported ? _startScanner : null,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Scanner starten'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        MobileScanner(
          controller: cameraController!,
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            if (barcodes.isNotEmpty && !_isScanning) {
              final String? code = barcodes.first.rawValue;
              if (code != null) {
                _handleQRCode(code);
              }
            }
          },
        ),
        // Overlay mit Scanbereich
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
          ),
          child: Column(
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'QR-Code in den Rahmen halten',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: _scannerActive ? _toggleTorch : null,
                      icon: Icon(
                        _torchEnabled ? Icons.flash_on : Icons.flash_off,
                        color: _scannerActive ? Colors.white : Colors.grey,
                        size: 32,
                      ),
                    ),
                    FilledButton(
                      onPressed: _stopScanner,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: const Text('Abbrechen'),
                    ),
                    IconButton(
                      onPressed: () => cameraController?.switchCamera(),
                      icon: const Icon(
                        Icons.cameraswitch,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_isScanning)
          Container(
            color: Colors.black87,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Lade Produkte...',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// Profil-Seite
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const CircleAvatar(
          radius: 50,
          child: Icon(Icons.person, size: 50),
        ),
        const SizedBox(height: 16),
        const Text(
          'Demo User',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'demo@freshreminder.de',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 32),
        ListTile(
          leading: const Icon(Icons.notifications),
          title: const Text('Benachrichtigungen'),
          trailing: Switch(
            value: true,
            onChanged: (value) {},
          ),
        ),
        ListTile(
          leading: const Icon(Icons.delete_outline),
          title: const Text('Abgelaufene Produkte'),
          subtitle: const Text('Automatisch nach 7 Tagen entfernen'),
          trailing: Switch(
            value: true,
            onChanged: (value) {},
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('Über FreshReminder'),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Abmelden'),
          onTap: () {},
        ),
      ],
    );
  }
}

// Produkt-Model
class Product {
  final String name;
  final DateTime expirationDate;
  final String category;

  Product({
    required this.name,
    required this.expirationDate,
    required this.category,
  });
}