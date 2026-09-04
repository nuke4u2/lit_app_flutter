package com.example.lit_reader

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var privacyEnabled = true
    private var contentVisible = false

    override fun onCreate(savedInstanceState: Bundle?) {
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.example.lit_reader/privacy",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "setPrivacyEnabled" -> {
                    privacyEnabled = call.argument<Boolean>("enabled") ?: true
                    if (!privacyEnabled) {
                        contentVisible = true
                    }
                    updateSecureFlag()
                    result.success(null)
                }

                "setContentVisible" -> {
                    contentVisible = call.argument<Boolean>("visible") ?: false
                    updateSecureFlag()
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onPause() {
        if (privacyEnabled) {
            contentVisible = false
            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        }
        super.onPause()
    }

    override fun onStop() {
        if (privacyEnabled) {
            contentVisible = false
            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        }
        super.onStop()
    }

    private fun updateSecureFlag() {
        runOnUiThread {
            if (privacyEnabled && !contentVisible) {
                window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
            } else {
                window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
            }
        }
    }
}
