package com.pos.pos_app

import android.content.Context
import android.util.Log
import android.view.View
import android.widget.FrameLayout
import androidx.annotation.OptIn
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import com.google.mlkit.vision.barcode.BarcodeScanner
import com.google.mlkit.vision.barcode.BarcodeScannerOptions
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class NativeScannerView(
    private val context: Context,
    private val id: Int,
    private val channel: MethodChannel
) : PlatformView {

    private val container: FrameLayout = FrameLayout(context)
    private val previewView: PreviewView = PreviewView(context)
    private var cameraProvider: ProcessCameraProvider? = null
    private var cameraExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    private val scanner: BarcodeScanner
    
    private var lastScannedBarcode: String? = null
    private var lastScanTime: Long = 0
    private val scanCooldown = 1000L // 1 second debounce to prevent rapid scans of the same item

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "pauseCamera" -> {
                    pauseCamera()
                    result.success(null)
                }
                "resumeCamera" -> {
                    resumeCamera()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        val options = BarcodeScannerOptions.Builder()
            .setBarcodeFormats(
                Barcode.FORMAT_EAN_13,
                Barcode.FORMAT_EAN_8,
                Barcode.FORMAT_CODE_128
            )
            .build()
        scanner = BarcodeScanning.getClient(options)
        
        previewView.layoutParams = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT
        )
        container.addView(previewView)
        
        startCamera()
    }

    private var preview: Preview? = null
    private var imageAnalysis: ImageAnalysis? = null
    private val cameraSelector = CameraSelector.DEFAULT_BACK_CAMERA

    private fun startCamera() {
        val cameraProviderFuture = ProcessCameraProvider.getInstance(context)
        cameraProviderFuture.addListener({
            try {
                cameraProvider = cameraProviderFuture.get()
                Log.d("NativeScannerView", "Camera provider obtained successfully")
                bindCameraUseCases()
            } catch (e: Exception) {
                Log.e("NativeScannerView", "Failed to get camera provider", e)
                channel.invokeMethod("onError", "Camera initialization failed: ${e.message}")
            }
        }, ContextCompat.getMainExecutor(context))
    }

    @OptIn(ExperimentalGetImage::class)
    private fun bindCameraUseCases() {
        val cameraProvider = cameraProvider ?: return
        
        preview = Preview.Builder().build()
        preview?.setSurfaceProvider(previewView.surfaceProvider)

        imageAnalysis = ImageAnalysis.Builder()
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            .setTargetResolution(android.util.Size(1280, 720))
            .build()

        imageAnalysis?.setAnalyzer(cameraExecutor) { imageProxy ->
            processImageProxy(imageProxy)
        }

        try {
            cameraProvider.unbindAll()
            
            val lifecycleOwner = findLifecycleOwner()
            if (lifecycleOwner != null) {
                cameraProvider.bindToLifecycle(
                    lifecycleOwner,
                    cameraSelector,
                    preview,
                    imageAnalysis
                )
            }
        } catch (exc: Exception) {
            Log.e("NativeScannerView", "Use case binding failed", exc)
        }
    }

    private fun findLifecycleOwner(): LifecycleOwner? {
        var context = this.context
        while (context is android.content.ContextWrapper) {
            if (context is LifecycleOwner) return context
            context = context.baseContext
        }
        return null
    }

    @OptIn(ExperimentalGetImage::class)
    private fun processImageProxy(imageProxy: ImageProxy) {
        val mediaImage = imageProxy.image
        if (mediaImage != null) {
            val image = InputImage.fromMediaImage(mediaImage, imageProxy.imageInfo.rotationDegrees)
            scanner.process(image)
                .addOnSuccessListener { barcodes ->
                    for (barcode in barcodes) {
                        val rawValue = barcode.rawValue
                        if (rawValue != null) {
                            handleBarcode(rawValue)
                        }
                    }
                }
                .addOnCompleteListener {
                    imageProxy.close()
                }
        } else {
            imageProxy.close()
        }
    }

    private fun handleBarcode(barcode: String) {
        val now = System.currentTimeMillis()
        if (barcode == lastScannedBarcode && now - lastScanTime < scanCooldown) {
            return
        }
        
        lastScannedBarcode = barcode
        lastScanTime = now
        
        ContextCompat.getMainExecutor(context).execute {
            channel.invokeMethod("onBarcodeDetected", barcode)
        }
    }

    private fun pauseCamera() {
        // Only unbind analysis to keep preview running
        val cp = cameraProvider ?: return
        val ia = imageAnalysis ?: return
        try {
            cp.unbind(ia)
        } catch (e: Exception) {
            Log.e("NativeScannerView", "Pause failed", e)
        }
    }

    private fun resumeCamera() {
        // Re-bind only analysis
        val cp = cameraProvider ?: return
        val preview = preview ?: return
        val ia = imageAnalysis ?: return
        val lifecycleOwner = findLifecycleOwner() ?: return
        
        try {
            // Re-binding only analysis while preview is already bound
            cp.bindToLifecycle(lifecycleOwner, cameraSelector, ia)
        } catch (e: Exception) {
            // If it fails, try re-binding everything
            bindCameraUseCases()
        }
    }

    override fun getView(): View {
        return container
    }

    override fun dispose() {
        channel.setMethodCallHandler(null)
        cameraExecutor.shutdown()
        cameraProvider?.unbindAll()
        scanner.close()
    }
}
