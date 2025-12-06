import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/scanned_product.dart';

class ProductListItem extends StatelessWidget {
  final ScannedProduct product;
  final bool isExpired;
  final bool isExpiringToday;
  final VoidCallback onRemove;

  const ProductListItem({
    Key? key,
    required this.product,
    required this.isExpired,
    required this.isExpiringToday,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('dd.MM.yyyy');
    final formattedDate = dateFormatter.format(product.expirationDate);

    Color statusColor = Colors.grey;
    String statusLabel = '';

    if (isExpired) {
      statusColor = Colors.red;
      statusLabel = 'ABGELAUFEN';
    } else if (isExpiringToday) {
      statusColor = Colors.orange;
      statusLabel = 'HEUTE ABLAUFEND';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isExpired ? Icons.warning : Icons.shopping_basket,
            color: statusColor,
          ),
        ),
        title: Text(
          product.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Verfallsdatum: $formattedDate',
              style: TextStyle(
                color: statusColor,
                fontWeight: isExpired || isExpiringToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (product.category != null && product.category!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  product.category!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
            if (statusLabel.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onRemove,
          tooltip: 'Produkt entfernen',
        ),
      ),
    );
  }
}
