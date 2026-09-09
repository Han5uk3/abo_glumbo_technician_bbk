# ---------------------------------------------------------------------------
# R8 rules for the technician app.
#
# R8 only ever sees the Java/Kotlin bytecode. The Dart code lives in libapp.so
# and is obfuscated separately, via `flutter build --obfuscate`.
#
# Nearly every plugin here ships its own consumer rules inside its AAR, so this
# file deliberately stays small: it covers only the libraries that reach for
# their own classes reflectively and therefore cannot be renamed safely.
# ---------------------------------------------------------------------------

# Keep line numbers so Play Console can still symbolicate release crashes,
# while letting R8 rename the source file itself.
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Generic signatures and annotations must survive for reflective
# (de)serialisation to resolve types at runtime.
-keepattributes Signature,InnerClasses,EnclosingMethod
-keepattributes RuntimeVisibleAnnotations,RuntimeVisibleParameterAnnotations

# flutter_local_notifications rehydrates its own model classes through Gson
# when rescheduling notifications after a reboot. Renaming them breaks reboot
# rescheduling silently, at runtime, only on release builds.
-keep class com.dexterous.** { *; }

# Gson resolves generic types through TypeToken subclasses.
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# Firestore/RTDB map custom objects by reflecting over annotated members.
-keepclassmembers class * {
  @com.google.firebase.firestore.PropertyName <methods>;
  @com.google.firebase.database.PropertyName <methods>;
}

# Flutter references Play Core for deferred components, which this app does not
# use; without this R8 fails the build on the missing classes.
-dontwarn com.google.android.play.core.**
