package ir.sooden.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Telephony
import android.telephony.SmsManager

/**
 * پنل سیمکارتی بعد از قطع برق، اگر ساعت نداشت، یک بار «برق پنل وصل شد» می‌فرستد. اگر کاربر اجازه داده باشد،
 * گوشی (حتی وقتی اپ بسته است) یک پیامک «#TIME» جواب می‌دهد؛ پنل ساعت را از مُهر زمان همان پیامک برمی‌دارد و جوابی نمی‌دهد.
 * شماره‌های پنل‌هایی که اجازه دارند در SharedPreferences (از اپ: MethodChannel «autoTime»).
 */
class PowerSmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent == null || intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return
        try {
            val nums = prefs(context).getStringSet(KEY, emptySet()) ?: return
            if (nums.isEmpty()) return
            val msgs = Telephony.Sms.Intents.getMessagesFromIntent(intent) ?: return
            if (msgs.isEmpty()) return
            val from = msgs[0].originatingAddress ?: return
            if (!nums.contains(tail(from))) return
            val body = msgs.joinToString("") { it.messageBody ?: "" }
            if (!body.contains("برق پنل وصل شد") && !body.contains("Panel power is back")) return
            val sm: SmsManager = if (Build.VERSION.SDK_INT >= 31) {
                context.getSystemService(SmsManager::class.java)
            } else {
                @Suppress("DEPRECATION")
                SmsManager.getDefault()
            }
            sm.sendTextMessage(from, null, "#TIME", null, null)
        } catch (e: Exception) {
        }
    }

    companion object {
        private const val KEY = "numbers"
        private fun prefs(c: Context) = c.getSharedPreferences("sooden_auto_time", Context.MODE_PRIVATE)

        /** آخرین ۱۰ رقم (۰۹۱۲... و +۹۸۹۱۲... یکی‌اند) */
        fun tail(n: String): String {
            val d = n.filter { it.isDigit() }
            return if (d.length > 10) d.substring(d.length - 10) else d
        }

        /** اجازه‌ی جواب خودکار برای یک شماره‌ی پنل */
        fun set(c: Context, number: String, on: Boolean) {
            val t = tail(number)
            if (t.length < 10) return
            val s = HashSet(prefs(c).getStringSet(KEY, emptySet()) ?: emptySet())
            if (on) s.add(t) else s.remove(t)
            prefs(c).edit().putStringSet(KEY, s).apply()
        }
    }
}
