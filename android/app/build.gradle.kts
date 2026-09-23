import java.io.FileInputStream
import java.util.Properties

val signingPropertiesFile = rootProject.file("key.properties")
val signingProperties = Properties()
if (signingPropertiesFile.exists()) {
    signingProperties.load(FileInputStream(signingPropertiesFile))
}

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.yerlestir.game.yerlestir"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.yerlestir.game.yerlestir"
        manifestPlaceholders["admobAppId"] = providers.gradleProperty("ADMOB_APP_ID")
            .getOrElse("ca-app-pub-4879558726064660~2177724664")
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (signingPropertiesFile.exists()) {
                storeFile = rootProject.file(
                    signingProperties.getProperty("storeFile")
                        ?: error("android/key.properties içinde storeFile eksik")
                )
                storePassword = signingProperties.getProperty("storePassword")
                    ?: error("android/key.properties içinde storePassword eksik")
                keyAlias = signingProperties.getProperty("keyAlias")
                    ?: error("android/key.properties içinde keyAlias eksik")
                keyPassword = signingProperties.getProperty("keyPassword")
                    ?: error("android/key.properties içinde keyPassword eksik")
            }
        }
    }

    buildTypes {
        release {
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            check(signingPropertiesFile.exists()) {
                "Production release için android/key.properties ve gerçek release keystore gerekli. Debug signing kabul edilmez."
            }
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
