package com.example.fastnews

import io.flutter.embedding.android.FlutterActivity
import android.content.pm.PackageManager
import android.os.Bundle
import android.util.Base64
import android.util.Log
import java.security.MessageDigest

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        printKeyHash()
    }

    private fun printKeyHash() {
        try {
            val info = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
                packageManager.getPackageInfo(
                    packageName,
                    PackageManager.GET_SIGNING_CERTIFICATES
                )
            } else {
                @Suppress("DEPRECATION")
                packageManager.getPackageInfo(
                    packageName,
                    PackageManager.GET_SIGNATURES
                )
            }

            val signatures = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
                info.signingInfo?.apkContentsSigners
            } else {
                @Suppress("DEPRECATION")
                info.signatures
            }

            signatures?.forEach { signature ->
                val md = MessageDigest.getInstance("SHA")
                md.update(signature.toByteArray())
                val keyHash = Base64.encodeToString(md.digest(), Base64.DEFAULT)
                Log.e("FACEBOOK_KEY_HASH", "Key Hash: $keyHash")
                println("========================================")
                println("FACEBOOK KEY HASH FOR YOUR APP:")
                println(keyHash.trim())
                println("========================================")
                println("Copy this Key Hash and add it to Facebook Developer Console:")
                println("https://developers.facebook.com/apps/836088289403124/settings/basic/")
                println("========================================")
            }
        } catch (e: Exception) {
            Log.e("FACEBOOK_KEY_HASH", "Error getting key hash", e)
            e.printStackTrace()
        }
    }
}
