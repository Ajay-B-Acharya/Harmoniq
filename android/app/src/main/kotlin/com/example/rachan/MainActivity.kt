package com.example.rachan

import android.Manifest
import android.content.ContentResolver
import android.content.ContentUris
import android.content.ContentValues
import android.content.pm.PackageManager
import android.database.Cursor
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
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

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        musicChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        musicChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPermission" -> {
                    result.success(checkMusicPermission())
                }
                "checkAllPermissions" -> {
                    result.success(checkAllPermissions())
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
                    val mimeType = call.argument<String>("mimeType") ?: "audio/mp4"
                    val displayName = call.argument<String>("displayName") ?: "$title.m4a"
                    val tempFilePath = call.argument<String>("tempFilePath")
                    if (tempFilePath == null) {
                        result.error("INVALID_ARGS", "tempFilePath is required", null)
                    } else {
                        saveDownloadedAudioAsync(
                            title, artist, album, durationMs, mimeType, displayName, tempFilePath, result
                        )
                    }
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
                            "resolve" -> ytDlpAdapter.resolve(call.argument<String>("id") ?: "")
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
        result: MethodChannel.Result
    ) {
        val resolver = applicationContext.contentResolver
        scanExecutor.execute {
            var insertedUri: android.net.Uri? = null
            val tempFile = File(tempFilePath)
            try {
                if (!tempFile.exists()) {
                    mainHandler.post {
                        result.error("FILE_NOT_FOUND", "Temporary download file does not exist", null)
                    }
                    return@execute
                }

                val sanitizedDisplayName = sanitizeFileName(displayName)
                val contentValues = ContentValues().apply {
                    put(MediaStore.Audio.Media.TITLE, title)
                    put(MediaStore.Audio.Media.ARTIST, artist)
                    put(MediaStore.Audio.Media.ALBUM, album)
                    put(MediaStore.Audio.Media.DISPLAY_NAME, sanitizedDisplayName)
                    put(MediaStore.Audio.Media.MIME_TYPE, mimeType)
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
                        val destFile = File(harmoniqDir, sanitizedDisplayName)
                        put(MediaStore.Audio.Media.DATA, destFile.absolutePath)
                    }
                }

                val collection = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
                insertedUri = resolver.insert(collection, contentValues)

                if (insertedUri != null) {
                    resolver.openOutputStream(insertedUri)?.use { output ->
                        tempFile.inputStream().use { input ->
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

                    tempFile.delete()
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
                val destFile = File(harmoniqDir, sanitizedDisplayName)
                tempFile.copyTo(destFile, overwrite = true)
                tempFile.delete()
                mainHandler.post {
                    result.success(destFile.absolutePath)
                }
            } catch (e: Exception) {
                // If anything failed, clean up the pending entry if created
                insertedUri?.let { uri ->
                    try {
                        resolver.delete(uri, null, null)
                    } catch (_: Exception) {}
                }
                // Try fallback to app storage before returning error
                try {
                    if (tempFile.exists()) {
                        val fallbackDir = applicationContext.getExternalFilesDir(android.os.Environment.DIRECTORY_MUSIC)
                            ?: applicationContext.filesDir
                        val harmoniqDir = File(fallbackDir, "Harmoniq").apply { if (!exists()) mkdirs() }
                        val destFile = File(harmoniqDir, sanitizeFileName(displayName))
                        tempFile.copyTo(destFile, overwrite = true)
                        tempFile.delete()
                        mainHandler.post {
                            result.success(destFile.absolutePath)
                        }
                        return@execute
                    }
                } catch (_: Exception) {}

                mainHandler.post {
                    result.error("SAVE_FAILED", e.message ?: "Failed to save audio file", null)
                }
            }
        }
    }

    private fun sanitizeFileName(name: String): String {
        val clean = name.replace(Regex("[\\\\/:*?\"<>|]"), "_").trim()
        return if (clean.isEmpty()) "download.m4a" else clean
    }
}
