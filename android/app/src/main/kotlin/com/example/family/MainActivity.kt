package com.huluca.giadinh

import android.Manifest
import android.content.pm.PackageManager
import android.telephony.TelephonyManager
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.huluca.giadinh/sim_info"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "getSimSerial") {
                    val simSerial = getSimSerial()
                    if (simSerial != null) {
                        result.success(simSerial)
                    } else {
                        result.success(null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun getSimSerial(): String? {
        return try {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_PHONE_STATE)
                == PackageManager.PERMISSION_GRANTED
            ) {
                val tm = getSystemService(TELEPHONY_SERVICE) as TelephonyManager
                @Suppress("DEPRECATION")
                tm.simSerialNumber
            } else {
                null
            }
        } catch (e: Exception) {
            null
        }
    }
}
