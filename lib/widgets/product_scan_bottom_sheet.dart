import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductScanBottomSheet extends StatefulWidget {
  final Product product;
  final Function(double) onConfirm;

  const ProductScanBottomSheet({
    super.key,
    required this.product,
    required this.onConfirm,
  });

  @override
  State<ProductScanBottomSheet> createState() => _ProductScanBottomSheetState();
}

class _ProductScanBottomSheetState extends State<ProductScanBottomSheet> {
  late double _quantity;
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _quantity = 1.0;
    _controller = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _increment() {
    setState(() {
      _quantity += 1;
      _controller.text = _quantity.toStringAsFixed(widget.product.isWeighted ? 2 : 0);
    });
  }

  void _decrement() {
    if (_quantity > 1) {
      setState(() {
        _quantity -= 1;
        _controller.text = _quantity.toStringAsFixed(widget.product.isWeighted ? 2 : 0);
      });
    }
  }

  void _updateFromText(String value) {
    final parsed = double.tryParse(value);
    if (parsed != null && parsed > 0) {
      setState(() {
        _quantity = parsed;
      });
    }
  }

  void _submit() {
    _updateFromText(_controller.text);
    if (_quantity > 0) {
      widget.onConfirm(_quantity);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 20,
        right: 20,
        top: 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 1),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImage(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name.toUpperCase(),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.product.barcode ?? 'No Barcode',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600], fontFamily: 'monospace'),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '\$${widget.product.price.toStringAsFixed(2)} / ${widget.product.isWeighted ? "kg" : "pc"}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const Divider(height: 40),
          
          const Text(
            'SELECT QUANTITY',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
          ),
          const SizedBox(height: 16),
          
          // Professional Stepper
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStepperButton(Icons.remove, _decrement),
              const SizedBox(width: 20),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.numberWithOptions(decimal: widget.product.isWeighted),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: _updateFromText,
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(width: 20),
              _buildStepperButton(Icons.add, _increment),
            ],
          ),
          
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text(
                'ADD TO CART',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepperButton(IconData icon, VoidCallback onPressed) {
    return Material(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: Icon(icon, size: 28, color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: widget.product.imagePath != null
            ? Image.network(
                widget.product.imagePath!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 40),
              )
            : const Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 40),
      ),
    );
  }
}

Future<void> showProductScanBottomSheet({
  required BuildContext context,
  required Product product,
  required Function(double) onConfirm,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ProductScanBottomSheet(
      product: product,
      onConfirm: onConfirm,
    ),
  );
}
