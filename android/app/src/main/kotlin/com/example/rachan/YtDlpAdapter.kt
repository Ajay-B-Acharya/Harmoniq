package com.example.rachan

import android.content.Context
import com.chaquo.python.Python
import dev.ffmpegkit_maintained.ytdlp.YtDlp
import org.json.JSONObject

internal class YtDlpAdapter(private val context: Context) {
    companion object {
        private val videoIdPattern = Regex("^[A-Za-z0-9_-]{11}$")
        private val safeAudioExtensions = setOf("m4a", "mp4", "webm", "mp3", "opus")
        private val safeHeaders = setOf("User-Agent", "Referer")
    }

    fun isAvailable(): Boolean = true

    fun initialize(): String {
        YtDlp.init(context.applicationContext)
        return Python.getInstance().getModule("yt_dlp.version").get("__version__").toString()
    }

    fun smoke(): Map<String, Any?> {
        val version = initialize()
        val python = Python.getInstance()
        val json = python.getModule("json")
        val options = pythonOptions(flat = true)
        val downloader = python.getModule("yt_dlp").callAttr("YoutubeDL", options)
        try {
            val info = json.callAttr("loads", "{\"id\":\"offline-smoke\",\"title\":\"No network\"}")
            val safe = downloader.callAttr("sanitize_info", info)
            return mapOf(
                "version" to version,
                "metadata" to json.callAttr("dumps", safe).toJava(String::class.java),
                "download" to false
            )
        } finally {
            downloader.callAttr("close")
        }
    }

    fun search(query: String, limit: Int): List<Map<String, Any?>> {
        require(query.isNotBlank() && query.length <= 200) { "Invalid search query" }
        require(limit in 1..10) { "Invalid result limit" }
        val result = extract("ytsearch$limit:${query.trim()}", flat = true)
        val entries = result.optJSONArray("entries") ?: return emptyList()
        val videos = ArrayList<Map<String, Any?>>(limit)
        for (index in 0 until minOf(entries.length(), limit)) {
            val video = entries.optJSONObject(index) ?: continue
            val id = video.optString("id")
            if (!videoIdPattern.matches(id)) continue
            videos.add(
                mapOf(
                    "id" to id,
                    "title" to video.optString("title", "Untitled video"),
                    "artist" to video.optString("channel", video.optString("uploader", "Unknown channel")),
                    "thumbnail" to safeHttps(video.optString("thumbnail")),
                    "duration" to video.optDouble("duration", 0.0).takeIf { it.isFinite() && it > 0 },
                    "source" to "youtube"
                )
            )
        }
        return videos
    }

    fun resolve(videoId: String): Map<String, Any?> {
        require(videoIdPattern.matches(videoId)) { "Invalid YouTube video ID" }
        val info = extract("https://www.youtube.com/watch?v=$videoId", flat = false)
        require(info.optString("id") == videoId) { "Unexpected video identity" }
        val formats = info.optJSONArray("formats") ?: throw IllegalStateException("No audio formats")
        val candidates = ArrayList<JSONObject>()
        for (index in 0 until formats.length()) {
            val format = formats.optJSONObject(index) ?: continue
            if (format.optString("vcodec") != "none" || format.optString("acodec") == "none") continue
            if (format.optString("ext") !in safeAudioExtensions) continue
            val url = format.optString("url")
            if (safeHttps(url) == null || format.optBoolean("has_drm")) continue
            if (format.optString("protocol") !in setOf("https", "http")) continue
            candidates.add(format)
        }
        if (candidates.isEmpty()) throw IllegalStateException("No directly playable audio-only stream")
        candidates.sortWith(compareBy<JSONObject> {
            if (it.optString("ext") == "m4a") 0 else 1
        }.thenBy {
            val bitrate = it.optDouble("abr", it.optDouble("tbr", 0.0))
            if (bitrate.isFinite() && bitrate > 0) kotlin.math.abs(bitrate - 144.0) else 1000.0
        })
        val format = candidates.first()
        val headers = format.optJSONObject("http_headers") ?: info.optJSONObject("http_headers")
        val playbackHeaders = mutableMapOf<String, String>()
        if (headers != null) {
            for (name in safeHeaders) {
                val value = headers.optString(name)
                if (value.isNotBlank() && !value.contains('\n') && !value.contains('\r')) playbackHeaders[name] = value
            }
        }
        return mapOf(
            "id" to videoId,
            "streamUrl" to format.getString("url"),
            "headers" to playbackHeaders,
            "format" to format.optString("format_id"),
            "source" to "youtube"
        )
    }

    private fun extract(url: String, flat: Boolean): JSONObject {
        initialize()
        val python = Python.getInstance()
        val json = python.getModule("json")
        val options = pythonOptions(flat)
        val downloader = python.getModule("yt_dlp").callAttr("YoutubeDL", options)
        try {
            val info = downloader.callAttr("extract_info", url, false)
            if (info.toString() == "None") throw IllegalStateException("No metadata returned")
            val sanitized = downloader.callAttr("sanitize_info", info)
            return JSONObject(json.callAttr("dumps", sanitized).toJava(String::class.java))
        } finally {
            downloader.callAttr("close")
        }
    }

    private fun pythonOptions(flat: Boolean): com.chaquo.python.PyObject {
        val python = Python.getInstance()
        val options = python.getModule("json").callAttr("loads", baseOptions(flat).toString())
        val logger = python.getModule("logging").callAttr("getLogger", "harmoniq.ytdlp")
        logger.callAttr("setLevel", 100)
        options.callAttr("__setitem__", "logger", logger)
        return options
    }

    private fun baseOptions(flat: Boolean): JSONObject = JSONObject()
        .put("quiet", true)
        .put("no_warnings", true)
        .put("ignoreerrors", false)
        .put("skip_download", true)
        .put("cachedir", false)
        .put("socket_timeout", 12)
        .put("retries", 0)
        .put("extractor_retries", 0)
        .put("fragment_retries", 0)
        .put("noplaylist", !flat)
        .put("extract_flat", flat)

    private fun safeHttps(raw: String): String? {
        val uri = android.net.Uri.parse(raw)
        return raw.takeIf { uri.scheme == "https" && !uri.host.isNullOrBlank() && uri.userInfo.isNullOrEmpty() }
    }
}
