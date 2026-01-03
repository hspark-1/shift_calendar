import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// secrets.properties 파일에서 환경변수 로드
val secretsFile = rootProject.file("secrets.properties")
val secretsProperties = Properties()
if (secretsFile.exists()) {
    secretsProperties.load(secretsFile.inputStream())
}

android {
    namespace = "com.shiftcalendar.shift_calendar"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.shiftcalendar.shift_calendar"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // 카카오 로그인 설정 (secrets.properties 또는 --dart-define에서 읽어옴)
        val kakaoNativeAppKey = secretsProperties.getProperty("KAKAO_NATIVE_APP_KEY")
            ?: project.findProperty("KAKAO_NATIVE_APP_KEY")?.toString()
            ?: ""
        manifestPlaceholders["KAKAO_NATIVE_APP_KEY"] = kakaoNativeAppKey
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
