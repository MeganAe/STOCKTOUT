package com.stocktout.stocktout

import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity : requis par local_auth (empreinte digitale).
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Option « masquer le contenu dans les applications récentes » :
        // FLAG_SECURE bloque aussi les captures d'écran.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "stocktout/secure")
            .setMethodCallHandler { call, result ->
                if (call.method == "setSecure") {
                    val on = call.argument<Boolean>("secure") ?: false
                    runOnUiThread {
                        if (on) {
                            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        } else {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        }
                    }
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }
}
