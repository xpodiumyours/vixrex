import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
val hasReleaseKeystore = keyPropertiesFile.exists()
if (hasReleaseKeystore) {
    keyProperties.load(keyPropertiesFile.inputStream())
}

android {
    namespace = "com.xpodiumyours.vixrex"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "29.0.14206865"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                val storePath = keyProperties["storeFile"] as String?
                val storePasswordValue = keyProperties["storePassword"] as String?
                val keyAliasValue = keyProperties["keyAlias"] as String?
                val keyPasswordValue = keyProperties["keyPassword"] as String?
                check(!storePath.isNullOrBlank()) { "android/key.properties missing storeFile" }
                check(!storePasswordValue.isNullOrBlank()) { "android/key.properties missing storePassword" }
                check(!keyAliasValue.isNullOrBlank()) { "android/key.properties missing keyAlias" }
                check(!keyPasswordValue.isNullOrBlank()) { "android/key.properties missing keyPassword" }
                storeFile = file(storePath)
                storePassword = storePasswordValue
                keyAlias = keyAliasValue
                keyPassword = keyPasswordValue
            }
        }
    }

    defaultConfig {
        applicationId = "com.xpodiumyours.vixrex"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Never fall back to the debug key. Release requires key.properties.
            if (hasReleaseKeystore) {
                signingConfig = signingConfigs.getByName("release")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

// Fail release/package tasks when no upload keystore is configured.
// Debug / flutter run stay usable without android/key.properties.
gradle.taskGraph.whenReady {
    val needsReleaseKey = allTasks.any { task ->
        val n = task.name
        n.contains("Release", ignoreCase = true) &&
            (n.startsWith("assemble") ||
                n.startsWith("bundle") ||
                n.startsWith("package") ||
                n.contains("bundleRelease") ||
                n == "assembleRelease")
    }
    if (needsReleaseKey && !hasReleaseKeystore) {
        throw GradleException(
            "Missing android/key.properties. Release builds require a real upload keystore " +
                "(see MOBIL_APK_GUNCELLEME.md and android/key.properties.template). " +
                "Debug builds are unchanged."
        )
    }
}
