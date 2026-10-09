package com.example.kuyyai

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.kuyyai/direct_call"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "makeDirectCall") {
                val phoneNumber = call.argument<String>("phone")
                if (!phoneNumber.isNullOrEmpty()) {
                    try {
                        val intent = Intent(Intent.ACTION_CALL).apply {
                            data = Uri.parse("tel:$phoneNumber")
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("CALL_FAILED", e.message, null)
                    }
                } else {
                    result.error("INVALID_PHONE", "Phone number is empty", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
