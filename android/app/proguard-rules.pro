# Flutter wrapper
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Google Sign-In
-keep class com.google.android.gms.** { *; }
-keep class com.google.api.client.** { *; }

# Keep flutter_local_notifications
-keep class com.dexterous.** { *; }

# Keep flutter_secure_storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Keep sqflite
-keep class com.tekartik.sqflite.** { *; }

# Keep Dio / OkHttp
-keep class okhttp3.** { *; }
-dontwarn okhttp3.**
-keep class okio.** { *; }
-dontwarn okio.**

# Keep model classes (prevent Gson/JSON serialization from being stripped)
-keep class com.specz.app.specz_co.** { *; }

# General rules
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-dontwarn java.lang.invoke.**
