package com.nestorfar.stampcamera

import android.media.MediaScannerConnection
import android.os.Build
import android.util.Log
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "scan_file_channel"
    private val TAG = "StampCamera"

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
    }
}
