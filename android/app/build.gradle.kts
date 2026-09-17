import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.wolf.loob"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.wolf.loob"
        minSdk = 21
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // BUG FIX: the release build type used to sign with signingConfigs
    // "debug" left at its Android-Gradle-Plugin default, which resolves to
    // ~/.android/debug.keystore - a file the SDK auto-generates *with a
    // random key* the first time it's needed on any machine that doesn't
    // already have one. Every GitHub Actions run starts from a clean
    // runner with no such file, so every CI build produced a brand-new
    // SHA-1 signing fingerprint. That's exactly why Google Sign-In failed
    // with ApiException 10 (DEVELOPER_ERROR): Firebase checks the APK's
    // signing fingerprint against whatever SHA-1 is registered in the
    // console, and a fingerprint that changes on every build can never
    // stay registered. Pointing explicitly at a fixed, checked-in
    // debug.keystore makes every build - local or CI - share the exact
    // same fingerprint, so registering it once in Firebase is permanent.
    signingConfigs {
        getByName("debug") {
            storeFile = file("debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    implementation("org.jetbrains.kotlin:kotlin-stdlib:2.2.0")
}
