import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../providers/cloud_cart_provider.dart';
import '../widgets/product_list_item.dart';

class CartOverviewScreen extends StatefulWidget {
  const CartOverviewScreen({Key? key}) : super(key: key);

  @override
  State<CartOverviewScreen> createState() => _CartOverviewScreenState();
}

class _CartOverviewScreenState extends State<CartOverviewScreen> {
  bool _isSubmitting = false;

  void _generateAndSubmitCart() async {
    final products = context.read<CloudCartProvider>().products;
    
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Warenkorb ist leer'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Prepare products for backend
      final productsData = products.map((p) => p.toJson()).toList();
      
      // Generate shopping trip token on backend
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/import/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'products': productsData,
          'store_name': 'Supermarkt',
        }),
      ).timeout(ApiConfig.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final expiresAt = DateTime.parse(data['expires_at']);
        
        // Store token in provider
        context.read<CloudCartProvider>().setToken(token, expiresAt: expiresAt);
        
        // Show success with QR code info
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Warenkorb erstellt'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Token: $token'),
                  const SizedBox(height: 16),
                  Text('Verfällt um: ${expiresAt.toLocal()}'),
                  const SizedBox(height: 16),
                  const Text('QR-Code wurde in der Kasse generiert'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.read<CloudCartProvider>().clearCart();
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        throw Exception('Server-Fehler: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CloudCartProvider>();
    final products = cartProvider.products;
    final expiredProducts = cartProvider.getExpiredProducts();
    final expiringToday = cartProvider.getExpiringToday();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Warenkorb-Übersicht'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Info Banner
          if (cartProvider.currentToken != null)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.green[100],
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Warenkorb erstellt',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Token: ${cartProvider.currentToken}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Product List
          Expanded(
            child: products.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Keine Produkte gescannt',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final isExpired = expiredProducts.contains(product);
                      final isExpiringToday = expiringToday.contains(product);

                      return ProductListItem(
                        product: product,
                        isExpired: isExpired,
                        isExpiringToday: isExpiringToday,
                        onRemove: () {
                          context.read<CloudCartProvider>().removeProductAt(index);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Entfernt: ${product.name}'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),

          // Summary and Submit Section
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Summary Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat('Gesamt', products.length.toString()),
                    if (expiredProducts.isNotEmpty)
                      _buildStat(
                        'Abgelaufen',
                        expiredProducts.length.toString(),
                        color: Colors.red,
                      ),
                    if (expiringToday.isNotEmpty)
                      _buildStat(
                        'Heute',
                        expiringToday.length.toString(),
                        color: Colors.orange,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Submit Button
                ElevatedButton.icon(
                  onPressed: _isSubmitting || products.isEmpty ? null : _generateAndSubmitCart,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload),
                  label: Text(_isSubmitting ? 'Wird übermittelt...' : 'Warenkorb erstellen'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.blue,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
