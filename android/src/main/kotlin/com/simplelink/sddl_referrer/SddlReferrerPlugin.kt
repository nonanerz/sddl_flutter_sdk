package com.simplelink.sddl_referrer

import android.content.Context
import android.net.Uri
import android.util.Log
import androidx.annotation.NonNull
import com.android.installreferrer.api.InstallReferrerClient
import com.android.installreferrer.api.InstallReferrerStateListener
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

class SddlReferrerPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var channel: MethodChannel
    private lateinit var appContext: Context

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "sddl_referrer")
        channel.setMethodCallHandler(this)
        appContext = binding.applicationContext
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        when (call.method) {
            "getInstallReferrer" -> {
                val waitMs = (call.argument<Int>("waitMs") ?: 0).coerceAtLeast(0)
                result.success(getInstallReferrer(waitMs))
            }
            else -> result.notImplemented()
        }
    }

    private fun prefs() =
        appContext.getSharedPreferences("sddl_sdk_prefs", Context.MODE_PRIVATE)

    private fun parseQuery(raw: String?): Map<String, String> {
        if (raw.isNullOrBlank()) return emptyMap()
        val out = LinkedHashMap<String, String>()
        var start = 0
        val s = raw
        while (start <= s.length) {
            val amp = s.indexOf('&', start).let { if (it == -1) s.length else it }
            val pair = s.substring(start, amp)
            if (pair.isNotEmpty()) {
                val eq = pair.indexOf('=')
                val name: String
                val value: String
                if (eq >= 0) {
                    name = Uri.decode(pair.substring(0, eq))
                    value = Uri.decode(pair.substring(eq + 1))
                } else {
                    name = Uri.decode(pair)
                    value = ""
                }
                if (name.isNotEmpty() && !out.containsKey(name)) out[name] = value
            }
            if (amp == s.length) break
            start = amp + 1
        }
        return out
    }

    private fun readCached(): Map<String, Any> {
        val p = prefs()
        val raw = p.getString("sddl.referrer.raw", null)
        val click = p.getLong("sddl.referrer.click", 0L)
        val install = p.getLong("sddl.referrer.install", 0L)
        return if (raw != null) {
            mapOf(
                "raw" to raw,
                "clickTsSec" to click.toInt(),
                "installBeginTsSec" to install.toInt(),
                "params" to parseQuery(raw)
            )
        } else emptyMap()
    }

    private fun cache(raw: String, click: Long, install: Long) {
        prefs().edit()
            .putString("sddl.referrer.raw", raw)
            .putLong("sddl.referrer.click", click)
            .putLong("sddl.referrer.install", install)
            .apply()
    }

    private fun getInstallReferrer(waitMs: Int): Map<String, Any> {
        val cached = readCached()
        if (cached.isNotEmpty()) return cached

        if (waitMs <= 0) {
            try { startFetchAsync() } catch (_: Throwable) {}
            return emptyMap()
        }

        val latch = CountDownLatch(1)
        try {
            startFetchAsync { latch.countDown() }
            latch.await(waitMs.toLong(), TimeUnit.MILLISECONDS)
        } catch (_: Throwable) {
        }
        return readCached()
    }

    private fun startFetchAsync(onDone: (() -> Unit)? = null) {
        val client = InstallReferrerClient.newBuilder(appContext).build()
        client.startConnection(object : InstallReferrerStateListener {
            override fun onInstallReferrerSetupFinished(responseCode: Int) {
                try {
                    if (responseCode == InstallReferrerClient.InstallReferrerResponse.OK) {
                        val info = client.installReferrer
                        val raw = info.installReferrer.orEmpty()
                        val click = info.referrerClickTimestampSeconds
                        val install = info.installBeginTimestampSeconds
                        if (raw.isNotBlank()) cache(raw, click, install)
                    }
                } catch (t: Throwable) {
                    Log.w("SDDL", "InstallReferrer error: ${t.message}")
                } finally {
                    try { client.endConnection() } catch (_: Throwable) {}
                    onDone?.let { it() }
                }
            }
            override fun onInstallReferrerServiceDisconnected() {
                onDone?.let { it() }
            }
        })
    }
}