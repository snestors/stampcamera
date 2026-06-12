package com.nestorfar.stampcamera

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Matrix
import android.graphics.Paint
import android.media.ExifInterface
import android.media.MediaScannerConnection
import android.util.Log
import java.io.ByteArrayOutputStream
import java.io.File
import kotlin.math.max

/**
 * Motor nativo de watermark portado del proyecto KMP (D:\AyG KMP,
 * shared/androidMain ImageProcessor.android.kt).
 *
 * Diferencias con el original KMP:
 * - Recibe el PATH del archivo en vez de ByteArray (el JPEG de la cámara nunca
 *   cruza el platform channel; se decodifica directo del disco con inSampleSize).
 * - El timestamp y la ubicación llegan como texto ya formateado desde Dart
 *   (se conserva el formato exacto del pipeline Flutter, incluidos los segundos).
 * - Si timestamp y ubicación comparten posición, el timestamp se desplaza una
 *   línea para no superponerse (comportamiento del pipeline Dart que el KMP
 *   no necesitaba porque sus presets usan posiciones distintas).
 *
 * Debe ejecutarse SIEMPRE en un hilo de fondo (ver MainActivity).
 */
object NativeImageProcessor {

    private const val TAG = "A&G_Diagnostics"
    private const val TARGET_SIZE = 2560

    // Compresión adaptativa: cuánto baja la calidad por reintento y el piso
    // por debajo del cual no se baja (para no degradar la evidencia).
    private const val QUALITY_STEP = 7
    private const val QUALITY_FLOOR = 60

    fun processAndSave(
        context: Context,
        inputPath: String,
        outputDir: String,
        timestampText: String?,
        locationText: String?,
        logoBytes: ByteArray?,
        logoSizeRatio: Double,
        logoPosition: String,
        timestampPosition: String,
        locationPosition: String,
        timestampFontSize: String,
        locationFontSize: String,
        quality: Int,
        maxFileSizeBytes: Int,
        textColor: String,
        outlineColor: String
    ): String {
        val startTime = System.currentTimeMillis()

        // 1. Rotación física según EXIF del archivo original
        val rotation = try {
            when (
                ExifInterface(inputPath).getAttributeInt(
                    ExifInterface.TAG_ORIENTATION,
                    ExifInterface.ORIENTATION_NORMAL
                )
            ) {
                ExifInterface.ORIENTATION_ROTATE_90 -> 90
                ExifInterface.ORIENTATION_ROTATE_180 -> 180
                ExifInterface.ORIENTATION_ROTATE_270 -> 270
                else -> 0
            }
        } catch (e: Exception) {
            0
        }

        // 2. Dimensiones sin decodificar píxeles
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(inputPath, bounds)
        val origWidth = bounds.outWidth
        val origHeight = bounds.outHeight
        if (origWidth <= 0 || origHeight <= 0) {
            throw IllegalArgumentException("No se pudo leer la imagen: $inputPath")
        }
        val maxOrigDim = max(origWidth, origHeight)

        // 3. inSampleSize en potencias de 2 hacia el tamaño objetivo
        var inSampleSize = 1
        if (maxOrigDim > TARGET_SIZE) {
            val halfHeight = origHeight / 2
            val halfWidth = origWidth / 2
            while ((halfHeight / inSampleSize) >= TARGET_SIZE && (halfWidth / inSampleSize) >= TARGET_SIZE) {
                inSampleSize *= 2
            }
        }

        // 4. Decodificación eficiente desde disco
        val decodeStart = System.currentTimeMillis()
        val decodeOptions = BitmapFactory.Options().apply {
            this.inSampleSize = inSampleSize
            inMutable = true
        }
        val decodedBitmap = BitmapFactory.decodeFile(inputPath, decodeOptions)
            ?: throw IllegalArgumentException("No se pudo decodificar la imagen: $inputPath")
        val decodeTime = System.currentTimeMillis() - decodeStart

        // 5. Escalado preciso si la potencia de 2 no fue suficiente
        val scaleStart = System.currentTimeMillis()
        val maxDecodedDim = max(decodedBitmap.width, decodedBitmap.height)
        var mutableBitmap = if (maxDecodedDim > TARGET_SIZE) {
            val scale = TARGET_SIZE.toFloat() / maxDecodedDim
            val scaled = Bitmap.createScaledBitmap(
                decodedBitmap,
                (decodedBitmap.width * scale).toInt(),
                (decodedBitmap.height * scale).toInt(),
                true
            )
            decodedBitmap.recycle()
            scaled
        } else {
            if (decodedBitmap.isMutable) decodedBitmap
            else decodedBitmap.copy(Bitmap.Config.ARGB_8888, true)
        }
        val scaleTime = System.currentTimeMillis() - scaleStart

        // 6. Rotación física si corresponde
        val rotationStart = System.currentTimeMillis()
        if (rotation != 0) {
            val matrix = Matrix().apply { postRotate(rotation.toFloat()) }
            val rotated = Bitmap.createBitmap(
                mutableBitmap, 0, 0, mutableBitmap.width, mutableBitmap.height, matrix, true
            )
            mutableBitmap.recycle()
            mutableBitmap = rotated
        }
        val rotationTime = System.currentTimeMillis() - rotationStart

        // 7. Marca de agua
        val drawingStart = System.currentTimeMillis()
        val canvas = Canvas(mutableBitmap)
        val canvasWidth = mutableBitmap.width
        val canvasHeight = mutableBitmap.height
        val padding = resolveTextSize("AUTO", canvasWidth) * 0.8f

        if (logoBytes != null) {
            try {
                val ratio = if (logoSizeRatio > 0.0) logoSizeRatio else 0.12
                val targetWidth = (canvasWidth * ratio).toInt()
                val scaledLogo = getCachedScaledLogo(logoBytes, targetWidth)
                if (scaledLogo != null) {
                    val left = anchorX(logoPosition, scaledLogo.width.toFloat(), canvasWidth.toFloat(), padding)
                    val top = anchorTopY(logoPosition, scaledLogo.height.toFloat(), canvasHeight.toFloat(), padding)
                    canvas.drawBitmap(scaledLogo, left, top, null)
                    // NO se recicla: el logo cacheado se reutiliza entre fotos.
                }
            } catch (e: Exception) {
                Log.w(TAG, "No se pudo estampar el logo", e)
            }
        }

        // Si comparten posición, el timestamp sube/baja una línea para no taparse.
        var timestampExtraOffset = 0f
        if (timestampText != null && locationText != null && timestampPosition == locationPosition) {
            timestampExtraOffset = resolveTextSize(timestampFontSize, canvasWidth) + 8f
        }

        if (locationText != null) {
            drawWatermarkText(
                canvas, locationText, locationPosition,
                resolveTextSize(locationFontSize, canvasWidth),
                canvasWidth, canvasHeight, padding, textColor, outlineColor
            )
        }

        if (timestampText != null) {
            drawWatermarkText(
                canvas, timestampText, timestampPosition,
                resolveTextSize(timestampFontSize, canvasWidth),
                canvasWidth, canvasHeight, padding, textColor, outlineColor,
                extraOffset = timestampExtraOffset
            )
        }
        val drawingTime = System.currentTimeMillis() - drawingStart

        // 8. Compresión JPEG adaptativa: arranca en la calidad pedida y baja
        //    hasta entrar en maxFileSizeBytes (0 = sin techo), sin pasar el piso.
        val compressStart = System.currentTimeMillis()
        var currentQuality = quality.coerceIn(1, 100)
        var resultBytes: ByteArray
        var attempts = 0
        while (true) {
            val outputStream = ByteArrayOutputStream()
            mutableBitmap.compress(Bitmap.CompressFormat.JPEG, currentQuality, outputStream)
            resultBytes = outputStream.toByteArray()
            attempts++
            if (maxFileSizeBytes <= 0 || resultBytes.size <= maxFileSizeBytes || currentQuality <= QUALITY_FLOOR) break
            currentQuality = (currentQuality - QUALITY_STEP).coerceAtLeast(QUALITY_FLOOR)
        }
        val compressTime = System.currentTimeMillis() - compressStart
        mutableBitmap.recycle()

        // 9. Guardar y registrar en MediaStore
        val dir = File(outputDir)
        if (!dir.exists()) dir.mkdirs()
        val outFile = File(dir, "IMG_${System.currentTimeMillis()}.jpg")
        outFile.writeBytes(resultBytes)
        MediaScannerConnection.scanFile(
            context.applicationContext,
            arrayOf(outFile.absolutePath),
            arrayOf("image/jpeg"),
            null
        )

        Log.d(TAG, "[Nativo] Decodificación (inSampleSize=$inSampleSize): ${decodeTime}ms")
        Log.d(TAG, "[Nativo] Escalado preciso: ${scaleTime}ms")
        Log.d(TAG, "[Nativo] Rotación física ($rotation°): ${rotationTime}ms")
        Log.d(TAG, "[Nativo] Marca de agua: ${drawingTime}ms")
        Log.d(TAG, "[Nativo] Compresión JPEG $currentQuality% -> ${resultBytes.size / 1024}KB ($attempts intento(s)): ${compressTime}ms")
        Log.d(TAG, "[Nativo] TOTAL: ${System.currentTimeMillis() - startTime}ms -> ${outFile.absolutePath}")

        return outFile.absolutePath
    }

    // ──────────────────────────────────────────────────────────────────────
    // Helpers de posicionamiento y dibujado
    // ──────────────────────────────────────────────────────────────────────

    /** Tamaño de fuente en px, calibrado para la resolución de salida (≤ 2560px). */
    private fun resolveTextSize(fontSize: String, canvasWidth: Int): Float = when (fontSize) {
        "SMALL" -> 36f
        "MEDIUM" -> 54f
        "LARGE" -> 72f
        else -> when { // AUTO
            canvasWidth < 1280 -> 24f
            canvasWidth < 1920 -> 36f
            canvasWidth < 3000 -> 48f
            else -> 64f
        }
    }

    /** X (esquina superior-izquierda del contenido) según el anclaje. */
    private fun anchorX(pos: String, contentW: Float, canvasW: Float, pad: Float): Float =
        when (pos) {
            "TOP_LEFT", "LEFT_CENTER", "BOTTOM_LEFT" -> pad
            "TOP_CENTER", "CENTER", "BOTTOM_CENTER" -> (canvasW - contentW) / 2f
            else -> canvasW - contentW - pad // TOP_RIGHT, RIGHT_CENTER, BOTTOM_RIGHT
        }

    /** Y (esquina superior-izquierda del contenido) según el anclaje. */
    private fun anchorTopY(pos: String, contentH: Float, canvasH: Float, pad: Float): Float =
        when (pos) {
            "TOP_LEFT", "TOP_CENTER", "TOP_RIGHT" -> pad
            "LEFT_CENTER", "CENTER", "RIGHT_CENTER" -> (canvasH - contentH) / 2f
            else -> canvasH - contentH - pad // BOTTOM_*
        }

    /** Dibuja texto con contorno + relleno, anclado en [position]. */
    private fun drawWatermarkText(
        canvas: Canvas,
        text: String,
        position: String,
        textSizePx: Float,
        canvasWidth: Int,
        canvasHeight: Int,
        padding: Float,
        fillColor: String,
        strokeColor: String,
        extraOffset: Float = 0f
    ) {
        val fillPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = parseColorSafe(fillColor, Color.WHITE)
            textSize = textSizePx
            style = Paint.Style.FILL
            isFakeBoldText = true
        }
        val strokePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = parseColorSafe(strokeColor, Color.BLACK)
            textSize = textSizePx
            style = Paint.Style.STROKE
            strokeWidth = textSizePx * 0.15f
            isFakeBoldText = true
        }

        val textWidth = fillPaint.measureText(text)
        val fm = fillPaint.fontMetrics
        val textHeight = fm.descent - fm.ascent

        val left = anchorX(position, textWidth, canvasWidth.toFloat(), padding)
        var top = anchorTopY(position, textHeight, canvasHeight.toFloat(), padding)

        if (extraOffset > 0f) {
            val isBottom = position == "BOTTOM_LEFT" || position == "BOTTOM_CENTER" || position == "BOTTOM_RIGHT"
            top = if (isBottom) top - extraOffset else top + extraOffset
        }

        // drawText usa la baseline como coordenada Y; ascent es negativo.
        val baseline = top - fm.ascent
        canvas.drawText(text, left, baseline, strokePaint)
        canvas.drawText(text, left, baseline, fillPaint)
    }

    private fun parseColorSafe(hex: String, fallback: Int): Int = try {
        Color.parseColor(hex)
    } catch (e: Exception) {
        fallback
    }

    // Cache del logo corporativo. Decodificar el PNG y escalarlo en CADA foto
    // es desperdicio puro: se decodifica una vez y se reutiliza el bitmap
    // escalado (clave = ancho destino).
    @Volatile
    private var decodedLogo: Bitmap? = null
    private var decodedLogoKey: Int = -1

    @Volatile
    private var scaledLogo: Bitmap? = null
    private var scaledLogoWidth: Int = -1

    @Synchronized
    private fun getCachedScaledLogo(logoBytes: ByteArray, targetWidth: Int): Bitmap? {
        val width = targetWidth.coerceAtLeast(1)
        if (decodedLogo == null || decodedLogoKey != logoBytes.size) {
            decodedLogo = BitmapFactory.decodeByteArray(logoBytes, 0, logoBytes.size)
            decodedLogoKey = logoBytes.size
            scaledLogo = null
            scaledLogoWidth = -1
        }
        val base = decodedLogo ?: return null
        if (scaledLogo == null || scaledLogoWidth != width) {
            val targetHeight = (base.height * (width.toDouble() / base.width)).toInt().coerceAtLeast(1)
            scaledLogo = Bitmap.createScaledBitmap(base, width, targetHeight, true)
            scaledLogoWidth = width
        }
        return scaledLogo
    }
}
