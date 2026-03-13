import 'package:flutter/services.dart';

class NativeScannerController {
  final int viewId;
  late final MethodChannel _channel;
  final Function(String) onBarcodeDetected;
  final Function(String)? onError;

  NativeScannerController({
    required this.viewId,
    required this.onBarcodeDetected,
    this.onError,
  }) {
    _channel = MethodChannel('com.pos.pos_app/native_scanner_$viewId');
    _channel.setMethodCallHandler(_handleMethod);
  }

  Future<void> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case 'onBarcodeDetected':
        final String barcode = call.arguments as String;
        onBarcodeDetected(barcode);
        break;
      case 'onError':
        final String error = call.arguments as String;
        onError?.call(error);
        break;
      default:
        print('Unknown method ${call.method}');
    }
  }

  Future<void> pauseCamera() async {
    await _channel.invokeMethod('pauseCamera');
  }

  Future<void> resumeCamera() async {
    await _channel.invokeMethod('resumeCamera');
  }

  Future<void> toggleFlash(bool enabled) async {
    await _channel.invokeMethod('toggleFlash', {'enabled': enabled});
  }

  void dispose() {
    _channel.setMethodCallHandler(null);
  }
}
