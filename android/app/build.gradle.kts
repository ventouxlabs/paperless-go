import com.android.build.gradle.internal.api.ApkVariantOutputImpl
import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.ventoux.paperlessgo"

    dependenciesInfo {
        includeInApk = false
        includeInBundle = false
    }
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Play Store identity (the original com.ventoux.paperlessgo was burned on
        // Play and can never be reused). namespace stays com.ventoux.paperlessgo —
        // it is internal-only and decoupled from applicationId.
        applicationId = "com.ventouxlabs.paperlessgo"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Default for every build type. The Flutter Gradle plugin also creates a
        // `profile` variant, which is not enumerated in buildTypes below — setting
        // the placeholder only on debug/release left profile with an unresolved
        // ${appLabel} and hard-failed manifest merging on `flutter build --profile`.
        manifestPlaceholders["appLabel"] = "Paperless Go"
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        debug {
            // A debug build installs alongside the signed release build so
            // on-device investigation does not cost a reinstall (and a
            // re-login) of the real app. The distinct label matters as much as
            // the distinct id: both appear in the system share sheet, and two
            // identical "Paperless Go" entries make it impossible to tell
            // which build a share test actually went to.
            applicationIdSuffix = ".debug"
            manifestPlaceholders["appLabel"] = "Paperless Go (debug)"
        }
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            // No keystore -> UNSIGNED. Never the debug key.
            //
            // The debug fallback that used to live here produced an APK that
            // looked entirely legitimate — right applicationId, right version,
            // minified and shrunk — but carried the universal Android debug
            // key. One of those was sideloaded onto a real phone as "v1.1.7"
            // and could only be replaced by wiping the app: a correctly signed
            // release cannot upgrade it, in either direction.
            //
            // The upgrade breakage is the smaller half. The debug key is
            // public, so ANY apk anyone signs with it and this applicationId
            // can upgrade such an install in place and inherit its data
            // directory — which holds the Paperless server URL and API token.
            // A debug-signed release does not just inconvenience the user, it
            // removes the signature as a trust boundary.
            //
            // Unsigned is the honest outcome for a source build: whoever
            // builds signs it themselves, which is what F-Droid and
            // distro packagers do anyway.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                null
            }
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

}

val abiCodes = mapOf("armeabi-v7a" to 1, "arm64-v8a" to 2, "x86_64" to 3)
android.applicationVariants.configureEach {
    val variant = this
    variant.outputs.forEach { output ->
        val abiVersionCode = abiCodes[output.filters.find { it.filterType == "ABI" }?.identifier]
        if (abiVersionCode != null) {
            (output as ApkVariantOutputImpl).versionCodeOverride = variant.versionCode * 10 + abiVersionCode
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    testImplementation("junit:junit:4.13.2")
    // Real org.json for local unit tests; the android.jar stubs throw "not mocked".
    testImplementation("org.json:json:20240303")
}

flutter {
    source = "../.."
}
