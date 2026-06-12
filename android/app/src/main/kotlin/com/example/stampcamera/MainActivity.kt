package com.nestorfar.stampcamera

import android.media.MediaScannerConnection
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "scan_file_channel"
    private val IMAGE_CHANNEL = "image_processor_channel"
    private val TAG = "StampCamera"

    // Un solo hilo: serializa el procesamiento de fotos (una ráfaga de capturas
    // se encola en vez de decodificar varios bitmaps de 2560px a la vez).
    private val imageExecutor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
    }

    override fun onDestroy() {
        imageExecutor.shutdown()
        super.onDestroy()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "scanFile") {
                val path = call.argument<String>("path")
                if (path != null) {
                    // Usar MediaScannerConnection (funciona en todas las versiones de Android)
                    MediaScannerConnection.scanFile(
                        applicationContext,
                        arrayOf(path),
                        arrayOf("image/jpeg")
                    ) { scannedPath, uri ->
                        Log.d(TAG, "Archivo escaneado: $scannedPath -> $uri")
                    }
                    result.success(null)
                } else {
                    result.error("INVALID_PATH", "Path is null", null)
                }
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, IMAGE_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "processAndSaveImage") {
                val inputPath = call.argument<String>("inputPath")
                val outputDir = call.argument<String>("outputDir")
                if (inputPath == null || outputDir == null) {
                    result.error("INVALID_ARGS", "inputPath y outputDir son requeridos", null)
                    return@setMethodCallHandler
                }
                val timestampText = call.argument<String>("timestampText")
                val locationText = call.argument<String>("locationText")
                val logoBytes = call.argument<ByteArray>("logoBytes")
                val logoSizeRatio = call.argument<Double>("logoSizeRatio") ?: 0.0
                val logoPosition = call.argument<String>("logoPosition") ?: "TOP_RIGHT"
                val timestampPosition = call.argument<String>("timestampPosition") ?: "BOTTOM_RIGHT"
                val locationPosition = call.argument<String>("locationPosition") ?: "BOTTOM_LEFT"
                val timestampFontSize = call.argument<String>("timestampFontSize") ?: "AUTO"
                val locationFontSize = call.argument<String>("locationFontSize") ?: "AUTO"
                val quality = call.argument<Int>("quality") ?: 90
                val maxFileSizeBytes = call.argument<Int>("maxFileSizeBytes") ?: 950_000
                val textColor = call.argument<String>("textColor") ?: "#FFFFFF"
                val outlineColor = call.argument<String>("outlineColor") ?: "#000000"

                imageExecutor.execute {
                    try {
                        val savedPath = NativeImageProcessor.processAndSave(
                            context = applicationContext,
                            inputPath = inputPath,
                            outputDir = outputDir,
                            timestampText = timestampText,
                            locationText = locationText,
                            logoBytes = logoBytes,
                            logoSizeRatio = logoSizeRatio,
                            logoPosition = logoPosition,
                            timestampPosition = timestampPosition,
                            locationPosition = locationPosition,
                            timestampFontSize = timestampFontSize,
                            locationFontSize = locationFontSize,
                            quality = quality,
                            maxFileSizeBytes = maxFileSizeBytes,
                            textColor = textColor,
                            outlineColor = outlineColor
                        )
                        mainHandler.post { result.success(savedPath) }
                    } catch (e: Exception) {
                        Log.e(TAG, "Error procesando imagen en nativo", e)
                        mainHandler.post { result.error("PROCESSING_ERROR", e.message, null) }
                    }
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
