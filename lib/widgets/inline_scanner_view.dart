import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/native_scanner_controller.dart';

enum ScannerMode { hidden, mini, fullscreen }

class InlineScannerView extends StatefulWidget {
  final ScannerMode mode;
  final Function(String) onBarcodeDetected;
  final VoidCallback onClose;
  final Function(ScannerMode) onModeChanged;

  const InlineScannerView({
    super.key,
    required this.mode,
    required this.onBarcodeDetected,
    required this.onClose,
    required this.onModeChanged,
  });

  @override
  State<InlineScannerView> createState() => _InlineScannerViewState();
}

class _InlineScannerViewState extends State<InlineScannerView> with SingleTickerProviderStateMixin {
  NativeScannerController? _controller;
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        duration: const Duration(seconds: 2), vsync: this)
      ..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mode == ScannerMode.hidden) return const SizedBox.shrink();

    final double targetHeight = widget.mode == ScannerMode.fullscreen ? 450.0 : 250.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        height: targetHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand, // CRITICAL: Force children to fill the container
            children: [
              // 1. CAMERA PREVIEW - The base layer
              AndroidView(
                viewType: 'com.pos.pos_app/native_scanner',
                onPlatformViewCreated: (id) {
                  _controller = NativeScannerController(
                    viewId: id,
                    onBarcodeDetected: widget.onBarcodeDetected,
                    onError: (error) => print('Scanner Error: $error'),
                  );
                },
                creationParamsCodec: const StandardMessageCodec(),
              ),

              // 2. TRANSPARENT DARK OVERLAY
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.35),
                ),
              ),

              // 3. SCANNER FRAME
              _buildCenteredScannerOverlay(),

              // 4. SCANNER CONTROL BUTTONS
              
              // Top Left: Flash
              Positioned(
                top: 16,
                left: 16,
                child: _buildCornerIconButton(
                  icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
                  onPressed: () {
                    setState(() => _isFlashOn = !_isFlashOn);
                    _controller?.toggleFlash(_isFlashOn);
                  },
                ),
              ),

              // Top Right: Close
              Positioned(
                top: 16,
                right: 16,
                child: _buildCornerIconButton(
                  icon: Icons.close,
                  onPressed: widget.onClose,
                ),
              ),

              // Bottom Left: Resize
              Positioned(
                bottom: 16,
                left: 16,
                child: _buildCornerIconButton(
                  icon: widget.mode == ScannerMode.fullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                  onPressed: () {
                    widget.onModeChanged(
                      widget.mode == ScannerMode.fullscreen ? ScannerMode.mini : ScannerMode.fullscreen
                    );
                  },
                ),
              ),

              // Bottom Right: 1x Info
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '1x',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // BOTTOM BRANDING
              Positioned(
                bottom: 12,
                left: 0, right: 0,
                child: Center(
                  child: Text(
                    'POS SCANNER',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenteredScannerOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double frameWidth = constraints.maxWidth * 0.75;
        final double frameHeight = constraints.maxHeight * 0.45;

        return Stack(
          children: [
            // Frame rectangle
            Center(
              child: Container(
                width: frameWidth,
                height: frameHeight,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            // Laser animation
            Center(
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, (-frameHeight / 2) + (frameHeight * _animation.value)),
                    child: Container(
                      width: frameWidth - 30,
                      height: 1.2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.redAccent.withOpacity(0.0),
                            Colors.redAccent.withOpacity(0.6),
                            Colors.redAccent.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCornerIconButton({required IconData icon, required VoidCallback onPressed}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withAlpha(25)),
          ),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
      ),
    );
  }
}
