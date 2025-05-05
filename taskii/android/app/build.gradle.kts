plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}
val flutter by extensions.getByName("flutter")
ndkVersion = project.extra["flutter.ndkVersion"] as String
android {
    namespace = "io.teamh.taskii"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = project.extra["flutter.ndkVersion"] as String
    buildToolsVersion = flutter.buildToolsVersion ?: "33.0.0"
    defaultConfig {
        ndk {
            checkNotNull(flutter) { "Flutter plugin extension is not configured properly." }
            abiFilters.addAll(flutter.defaultNdkAbiFilters)
        }
    }

        sourceCompatibility = JavaVersion.VERSION_24
        sourceCompatibility = JavaVersion.VERSION_24
        targetCompatibility = JavaVersion.VERSION_24

    kotlinOptions {
        // Optionally, you can add:
        // apiVersion = "2.1"
        // languageVersion = "2.1"
        jvmTarget = JavaVersion.VERSION_24.toString()
        jvmTarget = "24"

    java {
        toolchain {
            languageVersion.set(JavaLanguageVersion.of(24))
        }
    }

    defaultConfig {
        applicationId = "io.teamh.taskii"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Replace this with your own signing config for the release build.
            // Example:
            // signingConfig = signingConfigs.create("release") {
            //     keyAlias = "your-key-alias"
            //     keyPassword = "your-key-password"
            //     storeFile = file("path/to/your/keystore.jks")
flutter {
    // Update the source path to point to the correct Flutter project directory
    source = "../../.."
}
    }
    sourceSets["main"].java.srcDirs("src/main/kotlin")
}

compileOptions {
    sourceCompatibility = JavaVersion.VERSION_1_8
    targetCompatibility = JavaVersion.VERSION_1_8
}

flutter {
    source = "../.."
}
