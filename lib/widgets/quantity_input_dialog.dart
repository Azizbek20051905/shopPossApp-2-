import 'package:flutter/material.dart';

class QuantityInputDialog extends StatefulWidget {
  final String productName;
  final double price;
  final bool isWeighted;

  const QuantityInputDialog({
    super.key,
    required this.productName,
    required this.price,
    this.isWeighted = false,
  });

  @override
  State<QuantityInputDialog> createState() => _QuantityInputDialogState();
}

class _QuantityInputDialogState extends State<QuantityInputDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '1');
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 4),
          Text('\$${widget.price.toStringAsFixed(2)} per ${widget.isWeighted ? "kg" : "pc"}', 
              style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.numberWithOptions(decimal: widget.isWeighted),
            decoration: InputDecoration(
              labelText: widget.isWeighted ? 'Weight (kg)' : 'Quantity',
              border: const OutlineInputBorder(),
              suffixText: widget.isWeighted ? 'kg' : 'pcs',
            ),
            onSubmitted: (_) => Navigator.of(context).pop(double.tryParse(_controller.text) ?? 1.0),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(double.tryParse(_controller.text) ?? 1.0),
          child: const Text('ADD TO CART'),
        ),
      ],
    );
  }
}

Future<double?> showQuantityInputDialog(
  BuildContext context, {
  required String productName,
  required double price,
  bool isWeighted = false,
}) {
  return showDialog<double>(
    context: context,
    barrierDismissible: false,
    builder: (context) => QuantityInputDialog(
      productName: productName,
      price: price,
      isWeighted: isWeighted,
    ),
  );
}
