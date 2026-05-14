plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.shubra.hr" // ✅ Required for AGP 8+
    compileSdk = 36

    defaultConfig {
        applicationId = "com.shubra.hr"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 102
        versionName = "2.0.2"
    }

    compileOptions {
        // Java 17 — Java 8 is deprecated in modern JDKs and produces "source/target
        // value 8 is obsolete" warnings. AGP 8.9 fully supports Java 17, and core
        // library desugaring (below) keeps backward compat for `java.time` etc. on
        // older Android runtimes (min SDK 21).
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    signingConfigs {
        create("release") {
            storeFile = file("C:/Users/smaji/Desktop/moh.jks") // Prefer relative path if possible
            storePassword = "moha990"
            keyAlias = "my-key-alias"
            keyPassword = "moha990"
        }
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.0.0"))
    implementation("com.google.firebase:firebase-analytics")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}

flutter {
    source = "../.."
}
