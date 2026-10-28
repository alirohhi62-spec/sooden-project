package ir.sooden.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.os.Build
import android.provider.Telephony
import android.telephony.SmsManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/** پیامک برای پنل سیمکارتی: فرستادن فرمان و گرفتن جواب پنل (وقتی وای‌فای در دسترس نیست) */
class MainActivity : FlutterActivity() {
    private var sink: EventChannel.EventSink? = null
    private var receiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "sooden/sms").setMethodCallHandler { call, result ->
            if (call.method == "send") {
                val to = call.argument<String>("to") ?: ""
                val text = call.argument<String>("text") ?: ""
                try {
                    val sm: SmsManager = if (Build.VERSION.SDK_INT >= 31) {
                        getSystemService(SmsManager::class.java)
                    } else {
                        @Suppress("DEPRECATION")
                        SmsManager.getDefault()
                    }
                    sm.sendTextMessage(to, null, text, null, null)
                    result.success(true)
                } catch (e: Exception) {
                    result.success(false)
                }
            } else if (call.method == "autoTime") {
                // اجازه‌ی جواب خودکار به «برق پنل وصل شد» برای شماره‌ی این پنل (PowerSmsReceiver)
                PowerSmsReceiver.set(applicationContext, call.argument<String>("number") ?: "", call.argument<Boolean>("on") ?: false)
                result.success(true)
            } else if (call.method == "bindWifi") {
                // وای‌فای پنل اینترنت ندارد: اندروید ارتباط را از داده‌ی همراه می‌فرستد. فقط این اپ به وای‌فای بسته می‌شود
                // (بقیه‌ی برنامه‌ها مثل همیشه). وای‌فای قطع و دوباره وصل شود (ماژول پنل کانال عوض می‌کند، یا گوشی
                // به وای‌فای دیگری می‌رود): به وای‌فای تازه بسته می‌شود؛ on=false: آزاد
                wantWifi = call.argument<Boolean>("on") ?: false
                result.success(applyBind())
            } else if (call.method == "wifiSettings") {
                // صفحه‌ی وای‌فای گوشی (برای وصل شدن به وای‌فای پنل)
                try {
                    startActivity(Intent(android.provider.Settings.ACTION_WIFI_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                    result.success(true)
                } catch (e: Exception) {
                    result.success(false)
                }
            } else {
                result.notImplemented()
            }
        }
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "sooden/sms_in").setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                sink = events
                startReceiver()
            }

            override fun onCancel(arguments: Any?) {
                sink = null
                stopReceiver()
            }
        })
    }

    private var wantWifi = false
    private var bound: Network? = null
    private var wifiCb: ConnectivityManager.NetworkCallback? = null

    private fun cm() = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

    private fun wifiNow(): Network? {
        val c = cm()
        var wifi: Network? = null
        @Suppress("DEPRECATION")
        for (n in c.allNetworks) {
            val cap = c.getNetworkCapabilities(n)
            if (cap != null && cap.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)) wifi = n
        }
        return wifi
    }

    private fun applyBind(): Boolean {
        return try {
            watchWifi()
            val c = cm()
            if (!wantWifi) {
                c.bindProcessToNetwork(null); bound = null; true
            } else {
                val w = wifiNow()
                if (w == null) { c.bindProcessToNetwork(null); bound = null; false }
                else { val ok = c.bindProcessToNetwork(w); bound = if (ok) w else null; ok }
            }
        } catch (e: Exception) {
            false
        }
    }

    private fun watchWifi() {
        if (wifiCb != null) return
        val cb = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) { runOnUiThread { if (wantWifi) applyBind() } }
            override fun onLost(network: Network) {
                runOnUiThread {
                    if (network == bound) { try { cm().bindProcessToNetwork(null) } catch (e: Exception) {}; bound = null }
                    if (wantWifi) applyBind()
                }
            }
        }
        try {
            val req = android.net.NetworkRequest.Builder().addTransportType(NetworkCapabilities.TRANSPORT_WIFI)
                .removeCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET).build()
            cm().registerNetworkCallback(req, cb)
            wifiCb = cb
        } catch (e: Exception) {
        }
    }

    private fun startReceiver() {
        if (receiver != null) return
        receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent == null) return
                try {
                    val msgs = Telephony.Sms.Intents.getMessagesFromIntent(intent) ?: return
                    if (msgs.isEmpty()) return
                    val from = msgs[0].originatingAddress ?: ""
                    val body = msgs.joinToString("") { it.messageBody ?: "" }
                    sink?.success(mapOf("from" to from, "body" to body))
                } catch (e: Exception) {
                }
            }
        }
        val f = IntentFilter(Telephony.Sms.Intents.SMS_RECEIVED_ACTION)
        f.priority = 999
        try {
            if (Build.VERSION.SDK_INT >= 33) {
                registerReceiver(receiver, f, Context.RECEIVER_EXPORTED)
            } else {
                registerReceiver(receiver, f)
            }
        } catch (e: Exception) {
            receiver = null
        }
    }

    private fun stopReceiver() {
        try {
            receiver?.let { unregisterReceiver(it) }
        } catch (e: Exception) {
        }
        receiver = null
    }

    override fun onDestroy() {
        stopReceiver()
        super.onDestroy()
    }
}
