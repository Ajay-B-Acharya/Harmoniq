package com.example.rachan

import android.Manifest
import android.content.ContentResolver
import android.content.ContentUris
import android.content.ContentValues
import android.content.pm.PackageManager
import android.database.Cursor
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import android.content.Intent
import android.net.Uri
import android.net.wifi.WifiManager
import android.os.PowerManager
import android.provider.Settings
import androidx.core.content.ContextCompat
import com.arthenica.ffmpegkit.FFmpegKit
import com.arthenica.ffmpegkit.ReturnCode
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException
import java.util.concurrent.Executors

// audio_service (used by just_audio_background) requires the Activity to
// extend AudioServiceActivity instead of FlutterActivity so it can bind to
// the background audio service correctly.
class MainActivity : AudioServiceActivity() {
    private val CHANNEL = "com.example.harmoniq/local_music"
    private val NOTIFICATION_CHANNEL_ID = "harmoniq_downloads"
    private val PERMISSION_REQUEST_CODE = 1001
    private val pendingPermissionResults = mutableListOf<MethodChannel.Result>()
    private val pendingScanResults = mutableSetOf<MethodChannel.Result>()
    private val scanExecutor = Executors.newSingleThreadExecutor()
    private val ytDlpExecutor = java.util.concurrent.ThreadPoolExecutor(
        1, 1, 0L, java.util.concurrent.TimeUnit.MILLISECONDS,
        java.util.concurrent.ArrayBlockingQueue(4)
    )
    private val ytDlpAdapter by lazy { YtDlpAdapter(applicationContext) }
    private val mainHandler = Handler(Looper.getMainLooper())
    private var musicChannel: MethodChannel? = null
    private var ytDlpChannel: MethodChannel? = null
    private var ytDlpActive = true
    private var wakeLock: PowerManager.WakeLock? = null
    private var wifiLock: WifiManager.WifiLock? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        createNotificationChannel()
        musicChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        musicChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPermission" -> {
                    result.success(checkMusicPermission())
                }
                "checkAllPermissions" -> {
                    result.success(checkAllPermissions())
                }
                "isIgnoringBatteryOptimizations" -> {
                    result.success(isIgnoringBatteryOptimizations())
                }
                "requestIgnoreBatteryOptimizations" -> {
                    requestIgnoreBatteryOptimizations(result)
                }
                "openBatteryOptimizationSettings" -> {
                    openBatteryOptimizationSettings(result)
                }
                "acquirePlaybackWakeLock" -> {
                    acquirePlaybackWakeLock()
                    result.success(true)
                }
                "releasePlaybackWakeLock" -> {
                    releasePlaybackWakeLock()
                    result.success(true)
                }
                "requestPermission", "requestAllPermissions" -> {
                    pendingPermissionResults.add(result)
                    if (pendingPermissionResults.size == 1) requestRequiredPermissions()
                }
                "fetchLocalSongs" -> {
                    if (checkMusicPermission()) {
                        fetchLocalSongsAsync(result)
                    } else {
                        result.error("PERMISSION_DENIED", "Storage/Media permission is not granted", null)
                    }
                }
                "saveDownloadedAudio" -> {
                    val title = call.argument<String>("title") ?: "Unknown Title"
                    val artist = call.argument<String>("artist") ?: "Unknown Artist"
                    val album = call.argument<String>("album") ?: "Harmoniq"
                    val durationMs = (call.argument<Number>("durationMs"))?.toLong() ?: 0L
                    val mimeType = call.argument<String>("mimeType") ?: "audio/mpeg"
                    val displayName = call.argument<String>("displayName") ?: "$title.mp3"
                    val tempFilePath = call.argument<String>("tempFilePath")
                    val bitrateKbps = (call.argument<Number>("bitrateKbps"))?.toInt() ?: 192
                    if (tempFilePath == null) {
                        result.error("INVALID_ARGS", "tempFilePath is required", null)
                    } else {
                        saveDownloadedAudioAsync(
                            title, artist, album, durationMs, mimeType, displayName, tempFilePath, bitrateKbps, result
                        )
                    }
                }
                "showDownloadNotification" -> {
                    val id = call.argument<Number>("id")?.toInt() ?: 101
                    val title = call.argument<String>("title") ?: "Music"
                    val artist = call.argument<String>("artist") ?: ""
                    val progress = call.argument<Number>("progress")?.toInt() ?: -1
                    val isCompleted = call.argument<Boolean>("isCompleted") ?: false
                    val isFailed = call.argument<Boolean>("isFailed") ?: false
                    val isCancelled = call.argument<Boolean>("isCancelled") ?: false
                    showDownloadNotification(id, title, artist, progress, isCompleted, isFailed, isCancelled)
                    result.success(true)
                }
                "cancelDownloadNotification" -> {
                    val id = call.argument<Number>("id")?.toInt() ?: 101
                    cancelDownloadNotification(id)
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        ytDlpChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.harmoniq/yt_dlp")
        ytDlpChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "isAvailable" -> result.success(ytDlpAdapter.isAvailable())
                "getVersion", "initialize", "smoke", "search", "resolve" -> try {
                    ytDlpExecutor.execute {
                    try {
                        val response: Any = when (call.method) {
                            "smoke" -> ytDlpAdapter.smoke()
                            "search" -> ytDlpAdapter.search(
                                call.argument<String>("query") ?: "",
                                call.argument<Int>("limit") ?: 25,
                                call.argument<Int>("page") ?: 1
                            )
                            "resolve" -> ytDlpAdapter.resolve(
                                call.argument<String>("id") ?: "",
                                call.argument<String>("quality")
                            )
                            else -> ytDlpAdapter.initialize()
                        }
                        mainHandler.post { if (ytDlpActive) result.success(response) }
                    } catch (error: Exception) {
                        android.util.Log.e("YtDlpAdapter", "Extraction failed: ${error.javaClass.simpleName}")
                        val code = if (error is IllegalArgumentException) "INVALID_INPUT" else "EXTRACTION_FAILED"
                        mainHandler.post {
                            if (ytDlpActive) result.error(code, "Online music is unavailable right now.", null)
                        }
                    }
                    }
                } catch (_: java.util.concurrent.RejectedExecutionException) {
                    result.error("BUSY", "Online extraction is busy. Please try again.", null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getStoragePermission(): String {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            Manifest.permission.READ_MEDIA_AUDIO
        } else {
            Manifest.permission.READ_EXTERNAL_STORAGE
        }
    }

    private fun checkMusicPermission(): Boolean {
        val permission = getStoragePermission()
        return ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED
    }

    private fun checkNotificationPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(
                this, Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }

    private fun checkAllPermissions(): Map<String, Boolean> {
        val storage = checkMusicPermission()
        val notification = checkNotificationPermission()
        return mapOf(
            "storage" to storage,
            "notification" to notification,
            "batteryOptimizationsIgnored" to isIgnoringBatteryOptimizations(),
            "allGranted" to (storage && notification)
        )
    }

    private fun requestRequiredPermissions() {
        val permissionsToRequest = mutableListOf<String>()
        if (!checkMusicPermission()) {
            permissionsToRequest.add(getStoragePermission())
        }
        if (!checkNotificationPermission() && Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            permissionsToRequest.add(Manifest.permission.POST_NOTIFICATIONS)
        }

        if (permissionsToRequest.isEmpty()) {
            completePermissionRequests(true)
        } else {
            ActivityCompat.requestPermissions(
                this, permissionsToRequest.toTypedArray(), PERMISSION_REQUEST_CODE
            )
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_CODE) {
            val storageGranted = checkMusicPermission()
            completePermissionRequests(storageGranted)
        }
    }

    private fun completePermissionRequests(granted: Boolean) {
        val results = pendingPermissionResults.toList()
        pendingPermissionResults.clear()
        results.forEach { it.success(granted) }
    }

    private fun fetchLocalSongsAsync(result: MethodChannel.Result) {
        // Query and cursor traversal can be slow for large libraries. Use the
        // application resolver so the worker does not need a live Activity.
        val resolver = applicationContext.contentResolver
        pendingScanResults.add(result)
        scanExecutor.execute {
            try {
                val songs = fetchLocalSongs(resolver)
                mainHandler.post {
                    if (pendingScanResults.remove(result)) result.success(songs)
                }
            } catch (error: Exception) {
                mainHandler.post {
                    if (pendingScanResults.remove(result)) {
                        val code = if (error is SecurityException) "PERMISSION_DENIED" else "SCAN_FAILED"
                        result.error(code, error.message ?: "Unable to scan local music", null)
                    }
                }
            }
        }
    }

    override fun onDestroy() {
        releasePlaybackWakeLock()
        ytDlpActive = false
        ytDlpChannel?.setMethodCallHandler(null)
        ytDlpChannel = null
        ytDlpExecutor.shutdownNow()
        musicChannel?.setMethodCallHandler(null)
        musicChannel = null
        pendingScanResults.forEach {
            it.error("ACTIVITY_DESTROYED", "Local music scan interrupted", null)
        }
        pendingScanResults.clear()
        completePermissionRequests(false)
        scanExecutor.shutdownNow()
        super.onDestroy()
    }

    private fun fetchLocalSongs(resolver: ContentResolver): List<Map<String, Any>> {
        val songsList = mutableListOf<Map<String, Any>>()

        val uri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.DURATION
        )
        val selection = "${MediaStore.Audio.Media.IS_MUSIC} != 0"
        val sortOrder = "${MediaStore.Audio.Media.TITLE} ASC"

        val cursor: Cursor? = resolver.query(uri, projection, selection, null, sortOrder)
        cursor?.use {
            val idCol       = it.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
            val titleCol    = it.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
            val artistCol   = it.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
            val albumCol    = it.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM)
            val durationCol = it.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)

            while (!Thread.currentThread().isInterrupted && it.moveToNext()) {
                val id       = it.getLong(idCol)
                val title    = it.getString(titleCol)    ?: "Unknown Title"
                val artist   = it.getString(artistCol)   ?: "Unknown Artist"
                val album    = it.getString(albumCol)    ?: "Unknown Album"
                val duration = it.getLong(durationCol)

                val contentUri = ContentUris.withAppendedId(
                    MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, id
                ).toString()

                songsList.add(
                    mapOf(
                        "id"       to id.toInt(),
                        "title"    to title,
                        "artist"   to artist,
                        "album"    to album,
                        "duration" to duration,
                        "path"     to contentUri
                    )
                )
            }
        }
        return songsList
    }

    private fun saveDownloadedAudioAsync(
        title: String,
        artist: String,
        album: String,
        durationMs: Long,
        mimeType: String,
        displayName: String,
        tempFilePath: String,
        bitrateKbps: Int = 192,
        result: MethodChannel.Result
    ) {
        val resolver = applicationContext.contentResolver
        scanExecutor.execute {
            var insertedUri: android.net.Uri? = null
            val originalTempFile = File(tempFilePath)
            var fileToSave = originalTempFile
            var convertedMp3File: File? = null
            val sanitizedDisplayName = sanitizeFileName(displayName)
            var effectiveMimeType = mimeType
            var effectiveDisplayName = sanitizedDisplayName

            try {
                if (!originalTempFile.exists()) {
                    mainHandler.post {
                        result.error("FILE_NOT_FOUND", "Temporary download file does not exist", null)
                    }
                    return@execute
                }

                val isMp3Target = mimeType == "audio/mpeg" || sanitizedDisplayName.endsWith(".mp3", ignoreCase = true)

                if (isMp3Target) {
                    val baseName = if (sanitizedDisplayName.endsWith(".mp3", ignoreCase = true)) {
                        sanitizedDisplayName.substringBeforeLast(".mp3")
                    } else {
                        sanitizedDisplayName.substringBeforeLast(".")
                    }
                    val candidateDisplayName = "$baseName.mp3"
                    val candidateMimeType = "audio/mpeg"

                    val safeBitrate = bitrateKbps.coerceIn(64, 320)
                    val mp3Out = File(originalTempFile.parentFile, "harmoniq_conv_${System.currentTimeMillis()}.mp3")

                    try {
                        val cmd = "-y -i \"" + originalTempFile.absolutePath + "\" -vn -c:a libmp3lame -b:a " + safeBitrate + "k -ac 2 -ar 44100 -f mp3 \"" + mp3Out.absolutePath + "\""
                        val session = FFmpegKit.execute(cmd)
                        if (ReturnCode.isSuccess(session.returnCode) && mp3Out.exists() && mp3Out.length() > 0) {
                            convertedMp3File = mp3Out
                            fileToSave = mp3Out
                            effectiveDisplayName = candidateDisplayName
                            effectiveMimeType = candidateMimeType
                        } else {
                            android.util.Log.w("MainActivity", "FFmpeg MP3 conversion returned code: " + session.returnCode + ", logs: " + session.allLogsAsString)
                        }
                    } catch (t: Throwable) {
                        android.util.Log.w("MainActivity", "FFmpeg conversion execution notice: " + t.message)
                    }
                }

                val contentValues = ContentValues().apply {
                    put(MediaStore.Audio.Media.TITLE, title)
                    put(MediaStore.Audio.Media.ARTIST, artist)
                    put(MediaStore.Audio.Media.ALBUM, album)
                    put(MediaStore.Audio.Media.DISPLAY_NAME, effectiveDisplayName)
                    put(MediaStore.Audio.Media.MIME_TYPE, effectiveMimeType)
                    if (durationMs > 0) {
                        put(MediaStore.Audio.Media.DURATION, durationMs)
                    }
                    put(MediaStore.Audio.Media.IS_MUSIC, 1)

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        put(MediaStore.Audio.Media.RELATIVE_PATH, "Music/Harmoniq")
                        put(MediaStore.Audio.Media.IS_PENDING, 1)
                    } else {
                        val musicDir = android.os.Environment.getExternalStoragePublicDirectory(android.os.Environment.DIRECTORY_MUSIC)
                        val harmoniqDir = File(musicDir, "Harmoniq").apply { if (!exists()) mkdirs() }
                        val destFile = File(harmoniqDir, effectiveDisplayName)
                        put(MediaStore.Audio.Media.DATA, destFile.absolutePath)
                    }
                }

                val collection = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
                insertedUri = resolver.insert(collection, contentValues)

                if (insertedUri != null) {
                    resolver.openOutputStream(insertedUri)?.use { output ->
                        fileToSave.inputStream().use { input ->
                            input.copyTo(output)
                        }
                        output.flush()
                    } ?: throw IOException("Unable to open output stream for MediaStore URI")

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        val completedValues = ContentValues().apply {
                            put(MediaStore.Audio.Media.IS_PENDING, 0)
                        }
                        resolver.update(insertedUri, completedValues, null, null)
                    }

                    originalTempFile.delete()
                    convertedMp3File?.delete()
                    val uriString = insertedUri.toString()
                    mainHandler.post {
                        result.success(uriString)
                    }
                    return@execute
                }

                // If MediaStore returned null, fallback directly to app-specific external files
                val fallbackDir = applicationContext.getExternalFilesDir(android.os.Environment.DIRECTORY_MUSIC)
                    ?: applicationContext.filesDir
                val harmoniqDir = File(fallbackDir, "Harmoniq").apply { if (!exists()) mkdirs() }
                val destFile = File(harmoniqDir, effectiveDisplayName)
                fileToSave.copyTo(destFile, overwrite = true)
                originalTempFile.delete()
                convertedMp3File?.delete()
                mainHandler.post {
                    result.success(destFile.absolutePath)
                }
            } catch (t: Throwable) {
                val e = if (t is Exception) t else Exception(t.message, t)
                insertedUri?.let { uri ->
                    try {
                        resolver.delete(uri, null, null)
                    } catch (_: Exception) {}
                }
                // Try fallback to app storage before returning error
                try {
                    if (fileToSave.exists()) {
                        val fallbackDir = applicationContext.getExternalFilesDir(android.os.Environment.DIRECTORY_MUSIC)
                            ?: applicationContext.filesDir
                        val harmoniqDir = File(fallbackDir, "Harmoniq").apply { if (!exists()) mkdirs() }
                        val destFile = File(harmoniqDir, effectiveDisplayName)
                        fileToSave.copyTo(destFile, overwrite = true)
                        originalTempFile.delete()
                        convertedMp3File?.delete()
                        mainHandler.post {
                            result.success(destFile.absolutePath)
                        }
                        return@execute
                    }
                } catch (_: Exception) {}

                originalTempFile.delete()
                convertedMp3File?.delete()
                mainHandler.post {
                    result.error("SAVE_FAILED", e.message ?: "Failed to save audio file", null)
                }
            }
        }
    }

    private fun sanitizeFileName(name: String): String {
        val clean = name.replace(Regex("[\\\\/:*?\"<>|]"), "_").trim()
        return if (clean.isEmpty()) "download.mp3" else clean
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Downloads"
            val descriptionText = "Music download progress notifications"
            val importance = NotificationManager.IMPORTANCE_LOW
            val channel = NotificationChannel(NOTIFICATION_CHANNEL_ID, name, importance).apply {
                description = descriptionText
                setShowBadge(false)
            }
            val notificationManager: NotificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun showDownloadNotification(
        id: Int,
        title: String,
        artist: String,
        progress: Int,
        isCompleted: Boolean,
        isFailed: Boolean,
        isCancelled: Boolean
    ) {
        if (!checkNotificationPermission()) return
        val notificationManager = NotificationManagerCompat.from(this)
        if (isCancelled) {
            notificationManager.cancel(id)
            return
        }

        val appIcon = applicationInfo.icon.takeIf { it != 0 } ?: android.R.drawable.stat_sys_download

        val builder = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(appIcon)
            .setContentTitle(title)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_PROGRESS)
            .setOnlyAlertOnce(true)

        when {
            isCompleted -> {
                builder.setContentText(if (artist.isNotEmpty()) "Downloaded • $artist" else "Download complete")
                    .setProgress(0, 0, false)
                    .setOngoing(false)
                    .setAutoCancel(true)
            }
            isFailed -> {
                builder.setContentText("Download failed")
                    .setProgress(0, 0, false)
                    .setOngoing(false)
                    .setAutoCancel(true)
            }
            else -> {
                val subText = if (progress in 0..100) "$progress%" else "Downloading..."
                val content = if (artist.isNotEmpty()) "$artist • $subText" else subText
                builder.setContentText(content)
                    .setOngoing(true)
                    .setAutoCancel(false)
                if (progress in 0..100) {
                    builder.setProgress(100, progress, false)
                } else {
                    builder.setProgress(0, 0, true)
                }
            }
        }

        try {
            notificationManager.notify(id, builder.build())
        } catch (e: SecurityException) {
            android.util.Log.w("MainActivity", "Notification permission not granted: ${e.message}")
        } catch (e: Exception) {
            android.util.Log.w("MainActivity", "Error showing download notification: ${e.message}")
        }
    }

    private fun cancelDownloadNotification(id: Int) {
        try {
            NotificationManagerCompat.from(this).cancel(id)
        } catch (_: Exception) {}
    }



    private fun isIgnoringBatteryOptimizations(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager
            powerManager?.isIgnoringBatteryOptimizations(packageName) ?: true
        } else {
            true
        }
    }

    private fun requestIgnoreBatteryOptimizations(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            result.success(true)
            return
        }
        try {
            if (isIgnoringBatteryOptimizations()) {
                result.success(true)
                return
            }
            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                data = Uri.parse("package:$packageName")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            result.success(true)
        } catch (_: Exception) {
            openBatteryOptimizationSettings(result)
        }
    }

    private fun openBatteryOptimizationSettings(result: MethodChannel.Result) {
        try {
            val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
            } else {
                Intent(Settings.ACTION_SETTINGS).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
            }
            startActivity(intent)
            result.success(true)
        } catch (_: Exception) {
            try {
                val appDetailsIntent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.parse("package:$packageName")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                startActivity(appDetailsIntent)
                result.success(true)
            } catch (e2: Exception) {
                result.error("SETTINGS_ERROR", "Could not open settings: ${e2.message}", null)
            }
        }
    }

    @Synchronized
    private fun acquirePlaybackWakeLock() {
        try {
            if (wakeLock == null) {
                val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager
                wakeLock = powerManager?.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "Harmoniq:PlaybackWakeLock")
                wakeLock?.setReferenceCounted(false)
            }
            if (wakeLock?.isHeld == false) {
                wakeLock?.acquire(4 * 60 * 60 * 1000L)
            }

            if (wifiLock == null) {
                val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
                @Suppress("DEPRECATION")
                wifiLock = wifiManager?.createWifiLock(WifiManager.WIFI_MODE_FULL_HIGH_PERF, "Harmoniq:PlaybackWifiLock")
                wifiLock?.setReferenceCounted(false)
            }
            if (wifiLock?.isHeld == false) {
                wifiLock?.acquire()
            }
        } catch (e: Exception) {
            android.util.Log.w("MainActivity", "Failed to acquire wake/wifi lock: ${e.message}")
        }
    }

    @Synchronized
    private fun releasePlaybackWakeLock() {
        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
            }
            if (wifiLock?.isHeld == true) {
                wifiLock?.release()
            }
        } catch (e: Exception) {
            android.util.Log.w("MainActivity", "Failed to release wake/wifi lock: ${e.message}")
        }
    }

}
