import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../providers/cart_provider.dart';
import '../services/native_scanner_controller.dart';
import 'package:permission_handler/permission_handler.dart';

class NativeScannerScreen extends ConsumerStatefulWidget {
  final bool isFormMode;
  const NativeScannerScreen({super.key, this.isFormMode = false});

  @override
  ConsumerState<NativeScannerScreen> createState() => _NativeScannerScreenState();
}

class _NativeScannerScreenState extends ConsumerState<NativeScannerScreen> with SingleTickerProviderStateMixin {
  NativeScannerController? _controller;
  final _productService = ProductService();
  bool _isProcessing = false;
  bool _scanned = false; 
  bool _hasPermission = false;
  bool _isCheckingPermission = true;

  Product? _selectedProduct;
  double _quantity = 1.0;
  final TextEditingController _quantityController = TextEditingController(text: '1');

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);
    _checkPermission();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _quantityController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.request();
    if (mounted) {
      setState(() {
        _hasPermission = status.isGranted;
        _isCheckingPermission = false;
      });
    }
  }

  void _increment() {
    setState(() {
      _quantity += 1;
      _quantityController.text = _quantity.toStringAsFixed(_selectedProduct?.isWeighted ?? false ? 2 : 0);
    });
  }

  void _decrement() {
    if (_quantity > 1) {
      setState(() {
        _quantity -= 1;
        _quantityController.text = _quantity.toStringAsFixed(_selectedProduct?.isWeighted ?? false ? 2 : 0);
      });
    }
  }

  Future<void> _onBarcodeDetected(String barcode) async {
    if (!mounted || _scanned || _isProcessing) return;
    
    if (widget.isFormMode) {
      HapticFeedback.mediumImpact();
      SystemSound.play(SystemSoundType.click);
      _scanned = true;
      Navigator.of(context).pop(barcode);
      return;
    }

    setState(() {
      _isProcessing = true;
      _scanned = true; 
      _selectedProduct = null;
    });

    try {
      await _controller?.pauseCamera();
      final product = await _productService.getProductByBarcode(barcode);

      if (!mounted) return;

      if (product != null) {
        HapticFeedback.mediumImpact();
        SystemSound.play(SystemSoundType.click);
        
        setState(() {
          _selectedProduct = product;
          _quantity = 1.0;
          _quantityController.text = '1';
          _isProcessing = false;
        });
      } else {
        HapticFeedback.lightImpact();
        _showErrorSnackBar('Product not found: $barcode');
        await Future.delayed(const Duration(seconds: 1));
        await _resumeScanner();
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Scanner error. Please try again.');
      await _resumeScanner();
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _resumeScanner() async {
    if (!mounted) return;
    try {
      await _controller?.resumeCamera();
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _selectedProduct = null;
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) setState(() => _scanned = false);
      });
    });
  }

  void _addToCart() {
    if (!mounted || _selectedProduct == null) return;
    final qty = double.tryParse(_quantityController.text) ?? _quantity;
    ref.read(cartProvider).addToCart(_selectedProduct!, quantity: qty);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${_selectedProduct!.name} x${qty.toStringAsFixed(_selectedProduct!.isWeighted ? 2 : 0)}'),
        backgroundColor: Colors.green,
        duration: const Duration(milliseconds: 1000),
        behavior: SnackBarBehavior.floating,
      ),
    );
    _resumeScanner();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isCheckingPermission
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : !_hasPermission
              ? _buildPermissionDeniedView()
              : Column(
                  children: [
                    // TOP: Camera Area (60%)
                    Expanded(
                      flex: 6, 
                      child: Stack(
                        children: [
                          AndroidView(
                            viewType: 'com.pos.pos_app/native_scanner',
                            onPlatformViewCreated: (id) {
                              _controller = NativeScannerController(
                                viewId: id,
                                onBarcodeDetected: _onBarcodeDetected,
                                onError: (error) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(error), backgroundColor: Colors.red),
                                  );
                                },
                              );
                            },
                            creationParamsCodec: const StandardMessageCodec(),
                          ),
                          _buildProfessionalOverlay(context),
                          
                          // Positioned scan status
                          Positioned(
                            top: 50,
                            left: 0, right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8, height: 8,
                                      decoration: BoxDecoration(
                                        color: _isProcessing ? Colors.orange : Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isProcessing ? 'PROCESSING...' : 'READY TO SCAN',
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // BOTTOM: Action Panel (40%)
                    Expanded(
                      flex: 4,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                        ),
                        child: _buildBottomPanel(),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildBottomPanel() {
    if (_isProcessing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
            SizedBox(height: 24),
            Text('FETCHING PRODUCT...', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
          ],
        ),
      );
    }

    if (_selectedProduct == null) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_scanner, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'SCAN BARCODE',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
            const SizedBox(height: 8),
            Text(
              'Align the barcode within the frame above\nto automatically search for the product.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 13, height: 1.5),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _selectedProduct!.imagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(_selectedProduct!.imagePath!, fit: BoxFit.cover),
                      )
                    : Icon(Icons.inventory_2_outlined, color: Colors.grey[400]),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedProduct!.name.toUpperCase(),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_selectedProduct!.salePrice.toStringAsFixed(0)} UZS',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Stock: ${_selectedProduct!.stockDisplay}',
                      style: TextStyle(fontSize: 12, color: _selectedProduct!.isLowStock ? Colors.orange : Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          // Quantity Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildQtyBtn(Icons.remove, _decrement),
              const SizedBox(width: 32),
              Text(
                _quantityController.text,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
              ),
              const SizedBox(width: 32),
              _buildQtyBtn(Icons.add, _increment),
            ],
          ),
          const Spacer(),
          // Buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _resumeScanner,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('CANCEL', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _selectedProduct!.isOutOfStock ? null : _addToCart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('ADD TO CART', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onPressed) {
    return IconButton.filled(
      onPressed: onPressed,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: Colors.grey[100],
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size(56, 56),
      ),
    );
  }

  Widget _buildPermissionDeniedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.white24),
          const SizedBox(height: 24),
          const Text('Permission Required', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () => openAppSettings(), child: const Text('Open Settings')),
        ],
      ),
    );
  }

  Widget _buildProfessionalOverlay(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double scanWidth = size.width * 0.8;
    final double scanHeight = 180;
    
    return Stack(
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.srcOut),
          child: Stack(
            children: [
              Container(decoration: const BoxDecoration(color: Colors.black, backgroundBlendMode: BlendMode.dstOut)),
              Center(
                child: Container(
                  width: scanWidth,
                  height: scanHeight,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                ),
              ),
            ],
          ),
        ),
        Center(
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, (-scanHeight / 2) + (scanHeight * _animation.value)),
                child: Container(
                  width: scanWidth - 40,
                  height: 2,
                  decoration: BoxDecoration(
                    boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.8), blurRadius: 10, spreadRadius: 2)],
                    gradient: LinearGradient(colors: [Colors.red.withOpacity(0), Colors.red, Colors.red.withOpacity(0)]),
                  ),
                ),
              );
            },
          ),
        ),
        Center(
          child: SizedBox(
            width: scanWidth,
            height: scanHeight,
            child: CustomPaint(painter: ScannerCornersPainter()),
          ),
        ),
      ],
    );
  }
}

class ScannerCornersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white..strokeWidth = 4..style = PaintingStyle.stroke;
    const double cornerSize = 24;
    canvas.drawLine(const Offset(0, 0), const Offset(0, cornerSize), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(cornerSize, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - cornerSize, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerSize), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - cornerSize), paint);
    canvas.drawLine(Offset(0, size.height), Offset(cornerSize, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - cornerSize, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, cornerSize == 0 ? 0 : size.height - cornerSize), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
