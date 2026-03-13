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

    final double targetHeight = widget.mode == ScannerMode.fullscreen ? 420.0 : 220.0;

    return Container(
      width: double.infinity,
      height: targetHeight,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 1. CAMERA PREVIEW
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: OverflowBox(
                alignment: Alignment.center,
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: AndroidView(
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
                ),
              ),
            ),
          ),

          // 2. SCANNING FRAME
          _buildScanningFrame(),

          // 3. OVERLAY CONTROLS (Floating on top of camera)
          Positioned(
            top: 12,
            right: 12,
            child: Row(
              children: [
                _buildControlBtn(
                  icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
                  onPressed: () {
                    setState(() => _isFlashOn = !_isFlashOn);
                    _controller?.toggleFlash(_isFlashOn);
                  },
                ),
                const SizedBox(width: 8),
                _buildControlBtn(
                  icon: widget.mode == ScannerMode.fullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                  onPressed: () {
                    widget.onModeChanged(
                      widget.mode == ScannerMode.fullscreen ? ScannerMode.mini : ScannerMode.fullscreen
                    );
                  },
                ),
                const SizedBox(width: 8),
                _buildControlBtn(
                  icon: Icons.close,
                  onPressed: widget.onClose,
                  color: Colors.redAccent,
                ),
              ],
            ),
          ),

          // 4. STATUS INDICATOR
          Positioned(
            bottom: 12,
            left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'READY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningFrame() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double frameWidth = constraints.maxWidth * 0.65;
        final double frameHeight = constraints.maxHeight * 0.45;

        return Stack(
          children: [
            // Frame rectangle
            Center(
              child: Container(
                width: frameWidth,
                height: frameHeight,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            // Laser Line
            Center(
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, (-frameHeight / 2) + (frameHeight * _animation.value)),
                    child: Container(
                      width: frameWidth - 10,
                      height: 2,
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.redAccent.withOpacity(0.5),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
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

  Widget _buildControlBtn({required IconData icon, required VoidCallback onPressed, Color? color}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Icon(icon, size: 20, color: color ?? Colors.white),
        ),
      ),
    );
  }
}
