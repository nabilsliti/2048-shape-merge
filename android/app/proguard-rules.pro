# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google Play Billing (in_app_purchase)
-keep class com.android.vending.billing.** { *; }
-keep class com.google.android.gms.** { *; }

# Google Play Core (deferred components / split install)
-dontwarn com.google.android.play.core.**

# Gson (used by flutter_local_notifications)
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# Firebase
-keep class com.google.firebase.** { *; }
-keepattributes *Annotation*
-keepattributes Signature

# Credential Manager (google_sign_in 6.x)
-keep class androidx.credentials.** { *; }
-keep class androidx.credentials.playservices.** { *; }
-keep class com.google.android.libraries.identity.googleid.** { *; }

# Google Sign-In plugin
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.signin.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.tasks.** { *; }

# Keep all Google Identity Services
-keep class com.google.android.gms.auth.api.identity.** { *; }
-keep class com.google.android.gms.auth.api.signin.** { *; }
-keep class com.google.android.gms.auth.api.credentials.** { *; }

# Keep R8 from stripping metadata needed for Sign-In
-keepattributes InnerClasses
-keepattributes EnclosingMethod
