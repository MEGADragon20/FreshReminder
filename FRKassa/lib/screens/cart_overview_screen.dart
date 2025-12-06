import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cloud_cart_provider.dart';
import '../widgets/product_list_item.dart';

class CartOverviewScreen extends StatefulWidget {
  const CartOverviewScreen({Key? key}) : super(key: key);

  @override
  State<CartOverviewScreen> createState() => _CartOverviewScreenState();
}

class _CartOverviewScreenState extends State<CartOverviewScreen> {
  final TextEditingController _cloudCartIdController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _cloudCartIdController.dispose();
    super.dispose();
  }

  void _submitCart() {
    final cloudCartId = _cloudCartIdController.text.trim();
    if (cloudCartId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a CloudCart ID'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final products = context.read<CloudCartProvider>().products;
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cart is empty'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // TODO: Implement API call to submit cart to backend
    // For now, simulate submission
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        // Clear cart after successful submission
        context.read<CloudCartProvider>().clearCart();
        _cloudCartIdController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cart submitted successfully to CloudCart: $cloudCartId'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CloudCartProvider>();
    final products = cartProvider.products;
    final expiredProducts = cartProvider.getExpiredProducts();
    final expiringToday = cartProvider.getExpiringToday();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart Overview'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // CloudCart ID Input
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _cloudCartIdController,
              decoration: InputDecoration(
                labelText: 'CloudCart ID',
                hintText: 'Enter the CloudCart ID from the QR code',
                prefixIcon: const Icon(Icons.tag),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              enabled: !_isSubmitting,
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
                          'No products scanned yet',
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
                              content: Text('Removed: ${product.name}'),
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
                    _buildStat('Total', products.length.toString()),
                    if (expiredProducts.isNotEmpty)
                      _buildStat(
                        'Expired',
                        expiredProducts.length.toString(),
                        color: Colors.red,
                      ),
                    if (expiringToday.isNotEmpty)
                      _buildStat(
                        'Today',
                        expiringToday.length.toString(),
                        color: Colors.orange,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Submit Button
                ElevatedButton.icon(
                  onPressed: _isSubmitting || products.isEmpty ? null : _submitCart,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload),
                  label: Text(_isSubmitting ? 'Submitting...' : 'Submit Cart'),
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
