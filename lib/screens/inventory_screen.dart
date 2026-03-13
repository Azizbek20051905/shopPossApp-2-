import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/inventory_service.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final ProductService _productService = ProductService();
  final InventoryService _inventoryService = InventoryService();
  
  List<Product> _products = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final products = await _productService.fetchProducts();
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  void _showAddStockDialog() {
    Product? selectedProduct;
    final quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add Inventory Stock', style: TextStyle(fontWeight: FontWeight.w900)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Product>(
                  decoration: InputDecoration(
                    labelText: 'Select Product',
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  items: _products.map((p) {
                    return DropdownMenuItem(
                      value: p,
                      child: Text(p.name, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) => setDialogState(() => selectedProduct = val),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: quantityController,
                  decoration: InputDecoration(
                    labelText: 'Quantity to add',
                    hintText: 'e.g. 50',
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedProduct == null || quantityController.text.isEmpty) return;
                  final qty = double.tryParse(quantityController.text);
                  if (qty == null || qty <= 0) return;

                  try {
                    final success = await _inventoryService.addStock(selectedProduct!.id!, qty);
                    if (success && mounted) {
                      Navigator.pop(context);
                      _loadInventory();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Stock updated successfully'), backgroundColor: Colors.green),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('ADD STOCK'),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('INVENTORY', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showAddStockDialog,
            icon: const Icon(Icons.add_circle_outline, size: 28),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadInventory,
        color: Colors.black,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
            : _error != null
                ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
                : _products.isEmpty
                    ? const Center(child: Text('No products tracked.'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          final isOut = product.isOutOfStock;
                          final isLow = product.isLowStock;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isOut ? Colors.red.withOpacity(0.2) : isLow ? Colors.orange.withOpacity(0.2) : Colors.transparent,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: Container(
                                width: 50, height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: product.imagePath != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(product.imagePath!, fit: BoxFit.cover),
                                      )
                                    : Icon(Icons.inventory_2_outlined, color: Colors.grey[300]),
                              ),
                              title: Text(
                                product.name.toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.2),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Current: ${product.stockDisplay}  |  Min: ${product.minStock.toStringAsFixed(0)}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ),
                              trailing: _buildStockBadge(isOut, isLow),
                            ),
                          );
                        },
                      ),
      ),
    );
  }

  Widget _buildStockBadge(bool isOut, bool isLow) {
    if (!isOut && !isLow) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOut ? Colors.red[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isOut ? 'OUT' : 'LOW',
        style: TextStyle(
          color: isOut ? Colors.red[700] : Colors.orange[800],
          fontWeight: FontWeight.w900,
          fontSize: 10,
        ),
      ),
    );
  }
}
