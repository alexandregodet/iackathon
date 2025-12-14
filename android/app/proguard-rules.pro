# Flutter specific
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# PDFBox / read_pdf_text - Missing classes workaround
-dontwarn com.gemalto.jp2.**
-dontwarn org.bouncycastle.**
-dontwarn com.tom_roush.pdfbox.**
-dontwarn javax.xml.**

# Keep PDFBox classes
-keep class com.tom_roush.** { *; }
-keep class org.bouncycastle.** { *; }

# Flutter Gemma
-keep class com.google.mediapipe.** { *; }
-dontwarn com.google.mediapipe.**

# TTS
-keep class com.google.android.tts.** { *; }

# Play Core (deferred components)
-dontwarn com.google.android.play.core.**

# Missing classes from R8
-dontwarn org.slf4j.**
-dontwarn java.awt.**
-dontwarn javax.swing.**
