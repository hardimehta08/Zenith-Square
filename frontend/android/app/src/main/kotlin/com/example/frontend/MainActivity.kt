package com.example.frontend

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.IOException

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            PDF_DOWNLOADS_CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method != "savePdfToDownloads") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val fileName = call.argument<String>("fileName")
            val bytes = call.argument<ByteArray>("bytes")
            if (fileName.isNullOrBlank() || bytes == null) {
                result.error("invalid_pdf", "A filename and PDF data are required.", null)
                return@setMethodCallHandler
            }

            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                result.success(null)
                return@setMethodCallHandler
            }

            try {
                result.success(savePdfToDownloads(fileName, bytes))
            } catch (error: Exception) {
                result.error("pdf_save_failed", error.localizedMessage, null)
            }
        }
    }

    private fun savePdfToDownloads(fileName: String, bytes: ByteArray): Boolean {
        val safeName = fileName
            .substringAfterLast('/')
            .substringAfterLast('\\')
            .replace(Regex("[\\p{Cntrl}:*?\"<>|]"), "_")
            .ifBlank { "report.pdf" }
        val resolver = applicationContext.contentResolver
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, safeName)
            put(MediaStore.MediaColumns.MIME_TYPE, "application/pdf")
            put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }
        val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
            ?: throw IOException("Could not create the PDF in Downloads.")

        try {
            resolver.openOutputStream(uri)?.use { output ->
                output.write(bytes)
            } ?: throw IOException("Could not open the PDF in Downloads.")
            val published = ContentValues().apply {
                put(MediaStore.MediaColumns.IS_PENDING, 0)
            }
            if (resolver.update(uri, published, null, null) == 0) {
                throw IOException("Could not publish the PDF in Downloads.")
            }
        } catch (error: Exception) {
            resolver.delete(uri, null, null)
            throw error
        }
        return true
    }

    companion object {
        private const val PDF_DOWNLOADS_CHANNEL = "com.example.frontend/pdf_downloads"
    }
}
