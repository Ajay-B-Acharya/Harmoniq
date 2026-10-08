# ProGuard / R8 Rules for Harmoniq Flutter Application

# Flutter Engine
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Suppress Play Store deferred component warnings (standard Flutter R8 requirement)
-dontwarn com.google.android.play.core.**

# Harmoniq Native Kotlin / Activity
-keep class com.example.rachan.** { *; }

# Just Audio Background & Audio Service
-keep class com.ryanheise.audioservice.** { *; }
-keep class com.ryanheise.just_audio.** { *; }

# dev.ffmpegkit_maintained yt-dlp & Chaquopy
-keep class dev.ffmpegkit_maintained.** { *; }
-keep class com.chaquo.python.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}
