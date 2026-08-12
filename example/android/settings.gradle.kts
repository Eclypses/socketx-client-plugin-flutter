pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.13.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")

// Dev-only composite: build against the checked-out sibling lib when present;
// otherwise the declared com.eclypses:* artifact resolves from Maven Central.
if (file("../../../../Packages/socketx-client-android").exists()) {
    includeBuild("../../../../Packages/socketx-client-android") {
        dependencySubstitution {
            substitute(module("com.eclypses:mte-socketx-client-android")).using(project(":socketx-client-android"))
        }
    }
}
