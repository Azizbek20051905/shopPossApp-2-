import 'package:flutter/material.dart';
import '../models/product.dart';

class ScanQuantityDialog extends StatefulWidget {
  final Product product;
  const ScanQuantityDialog({super.key, required this.product});

  @override
  State<ScanQuantityDialog> createState() => _ScanQuantityDialogState();
}

class _ScanQuantityDialogState extends State<ScanQuantityDialog> {
  late double _quantity;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _quantity = 1.0;
    _controller = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _controller.dispose();
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

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF2FA7A4);
    const Color textColor = Color(0xFF2C3E50);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: widget.product.imagePath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(widget.product.imagePath!, fit: BoxFit.cover),
                        )
                      : const Icon(Icons.inventory_2_outlined, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: textColor),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.product.salePrice.toStringAsFixed(0)} UZS',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primaryColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'ENTER QUANTITY',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.grey, letterSpacing: 1),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildRoundBtn(Icons.remove, _decrement),
                const SizedBox(width: 24),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _controller,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: textColor),
                    decoration: const InputDecoration(border: InputBorder.none),
                    onChanged: (v) {
                      final val = double.tryParse(v);
                      if (val != null) _quantity = val;
                    },
                  ),
                ),
                const SizedBox(width: 24),
                _buildRoundBtn(Icons.add, _increment),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, _quantity),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('CONFIRM', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundBtn(IconData icon, VoidCallback onPressed) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: const Color(0xFFF1F5F9),
        foregroundColor: const Color(0xFF2C3E50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size(56, 56),
      ),
    );
  }
}
