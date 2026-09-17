# ============================================================
#  Proguard rules — Loob
# ============================================================
#
# غير مُفعّلة حالياً (minifyEnabled = false افتراضياً في release buildType)،
# لكن جاهزة لحظة تفعيل التصغير (minification) مستقبلاً لتفادي كسر flutter_stripe.
# للتفعيل: أضف في android/app/build.gradle.kts داخل buildTypes.release:
#   isMinifyEnabled = true
#   proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")

# Stripe SDK
-keep class com.stripe.android.** { *; }
-keep class com.stripe.android.pushProvisioning.** { *; }
-dontwarn com.stripe.android.**

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Kotlin metadata (يمنع تحذيرات إضافية مع Kotlin الحديث)
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable
