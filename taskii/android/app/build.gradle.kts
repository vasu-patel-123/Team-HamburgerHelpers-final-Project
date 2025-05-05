plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "io.teamh.taskii"
    compileSdk = 35 // Or use flutter.compileSdkVersion if available
    ndkVersion = "28.1.13356709"
    buildToolsVersion = "33.0.0"

    defaultConfig {
        applicationId = "io.teamh.taskii"
        minSdk = 23
        targetSdk = 35 // Or use flutter.targetSdkVersion if available
        versionCode = 1 // Or use flutter.versionCode if available
        versionName = "1.0" // Or use flutter.versionName if available
        ndk {
            abiFilters.addAll(listOf("armeabi-v7a", "arm64-v8a", "x86_64"))
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
        }
    }

    sourceSets["main"].java.srcDirs("src/main/kotlin")

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    kotlinOptions {
        jvmTarget = "21"
    }
}

// Remove invalid flutter { source = ... } blocks

// If you need to configure the Flutter extension, do it like this:
flutter {
    // No 'source' property needed here
}
