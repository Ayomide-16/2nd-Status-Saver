package com.statussaver.status_saver

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.annotation.NonNull
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.statussaver.status_saver/saf"
    private val REQUEST_CODE_OPEN_DOCUMENT_TREE = 42
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openDocumentTree" -> {
                    pendingResult = result
                    openDocumentTree()
                }
                "listFiles" -> {
                    val uriString = call.argument<String>("uri")
                    if (uriString != null) {
                        val files = listFilesFromUri(uriString)
                        result.success(files)
                    } else {
                        result.error("INVALID_URI", "URI is null", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun openDocumentTree() {
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
        }
        
        // Try to start at WhatsApp status folder
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val initialUri = Uri.parse("content://com.android.externalstorage.documents/document/primary%3AAndroid%2Fmedia%2Fcom.whatsapp%2FWhatsApp%2FMedia%2F.Statuses")
            intent.putExtra("android.provider.extra.INITIAL_URI", initialUri)
        }
        
        startActivityForResult(intent, REQUEST_CODE_OPEN_DOCUMENT_TREE)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (requestCode == REQUEST_CODE_OPEN_DOCUMENT_TREE) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val uri = data.data
                if (uri != null) {
                    // Persist permission
                    contentResolver.takePersistableUriPermission(
                        uri,
                        Intent.FLAG_GRANT_READ_URI_PERMISSION
                    )
                    pendingResult?.success(uri.toString())
                } else {
                    pendingResult?.error("NO_URI", "No URI returned", null)
                }
            } else {
                pendingResult?.success(null)
            }
            pendingResult = null
        }
    }

    private fun listFilesFromUri(uriString: String): List<String> {
        val files = mutableListOf<String>()
        
        try {
            val uri = Uri.parse(uriString)
            val documentFile = DocumentFile.fromTreeUri(this, uri)
            
            documentFile?.listFiles()?.forEach { file ->
                if (file.isFile) {
                    val filePath = getPathFromUri(file.uri)
                    if (filePath != null) {
                        files.add(filePath)
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        
        return files
    }

    private fun getPathFromUri(uri: Uri): String? {
        // Create a temporary copy for access
        // For SAF URIs, we return the URI string itself
        // The app should use content resolver to read the file
        return uri.toString()
    }
}
