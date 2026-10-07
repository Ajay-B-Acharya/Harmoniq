package com.example.rachan

import android.content.Context
import com.chaquo.python.Python
import dev.ffmpegkit_maintained.ytdlp.YtDlp
import org.json.JSONObject
import java.io.File
import java.util.concurrent.TimeUnit

internal class YtDlpAdapter(private val context: Context) {
    companion object {
        private val videoIdPattern = Regex("^[A-Za-z0-9_-]{11}$")
        private val safeAudioExtensions = setOf("m4a", "mp4", "webm", "mp3", "opus")
        private val safeHeaders = setOf("User-Agent", "Referer")
        private const val runtimeVersion = "2026.08.19"
        private val runtimeLock = Any()
        private var runtimeReady = false
    }

    private val quickJs: File
        get() = File(context.applicationInfo.nativeLibraryDir, "libharmoniq_quickjs.so")

    fun isAvailable(): Boolean = quickJs.canExecute()

    fun initialize(): String = synchronized(runtimeLock) {
        check(isAvailable()) { "No supported JavaScript runtime for this ABI" }
        if (!runtimeReady) {
            val directory = File(context.noBackupFilesDir, "youtube-runtime")
            check(directory.isDirectory || directory.mkdirs()) { "Runtime directory unavailable" }
            val bundle = File(directory, "yt-dlp-$runtimeVersion.zip")
            val temporary = File(directory, "yt-dlp.tmp")
            context.assets.open("yt-dlp/yt-dlp.zip").use { input ->
                temporary.outputStream().use { output -> input.copyTo(output) }
            }
            check(temporary.renameTo(bundle)) { "Runtime installation failed" }
            YtDlp.init(context.applicationContext)
            val python = Python.getInstance()
            python.getModule("sys").get("path")!!.callAttr("insert", 0, bundle.absolutePath)
            check(python.getModule("yt_dlp.version").get("__version__").toString() == runtimeVersion) {
                "Unexpected yt-dlp runtime"
            }
            check(python.getModule("yt_dlp_ejs.version").get("__version__").toString() == "0.8.0") {
                "Unexpected EJS runtime"
            }
            val probe = ProcessBuilder(quickJs.absolutePath, "-e", "console.log(1 + 1)")
                .redirectErrorStream(true).start()
            try {
                check(probe.waitFor(5, TimeUnit.SECONDS) && probe.exitValue() == 0) {
                    "JavaScript runtime unavailable"
                }
                check(probe.inputStream.bufferedReader().use { it.readText().trim() } == "2") {
                    "JavaScript runtime self-test failed"
                }
            } finally {
                probe.destroy()
            }
            runtimeReady = true
        }
        runtimeVersion
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
                    "thumbnail" to thumbnail(video),
                    "duration" to video.optDouble("duration", 0.0).takeIf { it.isFinite() && it > 0 },
                    "sourceUrl" to "https://www.youtube.com/watch?v=$id",
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
        val format = info
        check(format.optString("vcodec") == "none" &&
            format.optString("acodec").let { it.isNotBlank() && it != "none" } &&
            format.optString("ext") in safeAudioExtensions &&
            safeHttps(format.optString("url")) != null &&
            !format.optBoolean("has_drm") &&
            format.optString("protocol") == "https") {
            "No directly playable audio-only stream"
        }
        val headers = format.optJSONObject("http_headers")
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
            "duration" to info.optDouble("duration", 0.0).takeIf { it.isFinite() && it > 0 },
            "sourceUrl" to "https://www.youtube.com/watch?v=$videoId",
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
        .put("simulate", true)
        .put("skip_download", true)
        .put("check_formats", false)
        .put("format", "bestaudio[ext=m4a][protocol=https]/bestaudio[protocol=https]")
        .put("js_runtimes", JSONObject().put("quickjs", JSONObject().put("path", quickJs.absolutePath)))
        .put("remote_components", org.json.JSONArray())
        .put("cachedir", false)
        .put("socket_timeout", 12)
        .put("retries", 0)
        .put("extractor_retries", 0)
        .put("fragment_retries", 0)
        .put("noplaylist", !flat)
        .put("extract_flat", flat)

    private fun thumbnail(video: JSONObject): String? {
        safeHttps(video.optString("thumbnail"))?.let { return it }
        val thumbnails = video.optJSONArray("thumbnails") ?: return null
        for (index in thumbnails.length() - 1 downTo 0) {
            safeHttps(thumbnails.optJSONObject(index)?.optString("url") ?: "")?.let { return it }
        }
        return null
    }

    private fun safeHttps(raw: String): String? {
        val uri = android.net.Uri.parse(raw)
        return raw.takeIf { uri.scheme == "https" && !uri.host.isNullOrBlank() && uri.userInfo.isNullOrEmpty() }
    }
}
