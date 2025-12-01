package com.example.fastnews

import android.content.Intent
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "MainActivity"
        private const val NOTIFICATION_CHANNEL = "com.example.fastnews/notification"
    }

    private var methodChannel: MethodChannel? = null
    private var pendingNotificationPayload: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "🚀 MainActivity onCreate called")
        handleNotificationIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        Log.d(TAG, "🔔 MainActivity onNewIntent called")
        handleNotificationIntent(intent)
        setIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: io.flutter.embedding.engine.FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.d(TAG, "🔧 Configuring Flutter Engine and Method Channel")

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_CHANNEL)

        pendingNotificationPayload?.let { payload ->
            Log.d(TAG, "📤 Sending pending notification to Flutter")
            methodChannel?.invokeMethod("onNotificationTapped", payload)
            pendingNotificationPayload = null
        }
    }

    private fun handleNotificationIntent(intent: Intent?) {
        if (intent == null) {
            Log.d(TAG, "❌ Intent is null")
            return
        }

        Log.d(TAG, "📦 Intent received:")
        Log.d(TAG, "   - Action: ${intent.action}")
        Log.d(TAG, "   - Data: ${intent.data}")
        Log.d(TAG, "   - Extras: ${intent.extras?.keySet()?.joinToString()}")

        val isNotificationIntent = intent.action == "SELECT_NOTIFICATION" ||
                                   intent.hasExtra("notificationId") ||
                                   intent.hasExtra("payload")

        if (isNotificationIntent) {
            Log.d(TAG, "✅ This is a NOTIFICATION INTENT!")
            val payload = intent.getStringExtra("payload")
            Log.d(TAG, "📦 Payload: ${payload?.substring(0, minOf(50, payload.length ?: 0))}...")

            if (payload != null) {
                if (methodChannel != null) {
                    Log.d(TAG, "📤 Sending notification to Flutter immediately")
                    methodChannel?.invokeMethod("onNotificationTapped", payload)
                } else {
                    Log.d(TAG, "⏳ Method channel not ready, storing payload")
                    pendingNotificationPayload = payload
                }
            } else {
                Log.e(TAG, "❌ Notification payload is null!")
            }
        } else {
            Log.d(TAG, "ℹ️ Normal app launch")
        }
    }
}
