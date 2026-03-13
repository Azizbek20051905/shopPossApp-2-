import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../providers/cart_provider.dart';
import 'product_form_screen.dart';

class BarcodeScannerScreen extends ConsumerStatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  ConsumerState<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends ConsumerState<BarcodeScannerScreen> {
  final ProductService _productService = ProductService();
  final TextEditingController _barcodeCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;
  Product? _found;

  @override
  void dispose() {
    _barcodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final barcode = _barcodeCtrl.text.trim();
    if (barcode.isEmpty) return;
    setState(() { _isLoading = true; _error = null; _found = null; });
    try {
      final product = await _productService.getProductByBarcode(barcode);
      setState(() {
        _found = product;
        _isLoading = false;
        if (product == null) _error = 'Product not found for barcode: $barcode';
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Barcode Search')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _barcodeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Enter Barcode',
                      prefixIcon: Icon(Icons.qr_code),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _search, child: const Text('Search')),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading) const CircularProgressIndicator(),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            if (_found != null) Card(
              child: ListTile(
                title: Text(_found!.name),
                subtitle: Text('${_found!.salePrice.toStringAsFixed(0)} UZS  |  Stock: ${_found!.stock}'),
                trailing: ElevatedButton(
                  onPressed: () {
                    ref.read(cartProvider).addToCart(_found!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${_found!.name} added to cart')),
                    );
                  },
                  child: const Text('Add to Cart'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
