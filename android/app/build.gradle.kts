import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Chave de assinatura da Play Store: lida de android/key.properties, que NUNCA
// vai para o GitHub (ver android/key.properties.exemplo e PUBLICAR_NA_PLAY_STORE.md).
val propriedadesDaChave = Properties()
val arquivoDaChave = rootProject.file("key.properties")
if (arquivoDaChave.exists()) {
    propriedadesDaChave.load(FileInputStream(arquivoDaChave))
}

android {
    namespace = "br.edu.ifsp.conectavida"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Identificador único na Play Store (não pode mudar depois de publicado).
        applicationId = "br.edu.ifsp.conectavida"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (arquivoDaChave.exists()) {
                keyAlias = propriedadesDaChave["keyAlias"] as String
                keyPassword = propriedadesDaChave["keyPassword"] as String
                storeFile = file(propriedadesDaChave["storeFile"] as String)
                storePassword = propriedadesDaChave["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Com android/key.properties: assinatura oficial (Play Store).
            // Sem ele: chave de teste, só para instalar direto no celular.
            signingConfig = if (arquivoDaChave.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
