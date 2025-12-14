---
sidebar_position: 10
title: Build et deploiement
description: Compiler et deployer l'application
---

# Build et deploiement

Ce guide couvre la compilation et le deploiement de IAckathon.

## Build Android

### APK de debug

Pour le developpement et les tests :

```bash
flutter build apk --debug
```

Sortie : `build/app/outputs/flutter-apk/app-debug.apk`

### APK de release

Pour la distribution :

```bash
flutter build apk --release
```

Sortie : `build/app/outputs/flutter-apk/app-release.apk`

### APK split par ABI

Pour reduire la taille en ciblant des architectures specifiques :

```bash
flutter build apk --split-per-abi --release
```

Sorties :
- `app-armeabi-v7a-release.apk` (~30 Mo)
- `app-arm64-v8a-release.apk` (~35 Mo)
- `app-x86_64-release.apk` (~40 Mo)

### App Bundle (AAB)

Pour le Play Store :

```bash
flutter build appbundle --release
```

Sortie : `build/app/outputs/bundle/release/app-release.aab`

## Signature de l'APK

### 1. Generer une cle

```bash
keytool -genkey -v -keystore ~/iackathon-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias iackathon
```

### 2. Configurer la signature

Creer `android/key.properties` :

```properties
storePassword=<mot_de_passe>
keyPassword=<mot_de_passe>
keyAlias=iackathon
storeFile=/chemin/vers/iackathon-key.jks
```

### 3. Configurer Gradle

Dans `android/app/build.gradle` :

```groovy
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

### 4. Builder l'APK signe

```bash
flutter build apk --release
```

## Optimisations

### Reduire la taille

```bash
# Activer la minification
flutter build apk --release --shrink

# Supprimer les ressources inutilisees
flutter build apk --release --tree-shake-icons
```

### Obfuscation du code

```bash
flutter build apk --release --obfuscate --split-debug-info=./debug-info/
```

:::warning Important
Conservez le dossier `debug-info/` pour pouvoir desymboliser les stack traces en cas de crash.
:::

## Configuration AndroidManifest

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- Permissions -->
    <uses-permission android:name="android.permission.INTERNET" />

    <application
        android:label="IAckathon"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:enableOnBackInvokedCallback="true">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">

            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>

        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
```

## Personnalisation

### Icone de l'application

1. Generez les icones avec [App Icon Generator](https://appicon.co/)
2. Placez-les dans `android/app/src/main/res/mipmap-*/`

Ou utilisez le package `flutter_launcher_icons` :

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_icons:
  android: true
  ios: false
  image_path: "assets/icon/app_icon.png"
```

```bash
flutter pub run flutter_launcher_icons
```

### Splash screen

Utilisez `flutter_native_splash` :

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_native_splash: ^2.3.0

flutter_native_splash:
  color: "#0A0A0F"
  image: assets/splash.png
  android: true
  ios: false
```

```bash
flutter pub run flutter_native_splash:create
```

## CI/CD

### GitHub Actions

```yaml
# .github/workflows/build.yml
name: Build APK

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v4

    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.22.0'
        channel: 'stable'

    - name: Install dependencies
      run: flutter pub get

    - name: Generate code
      run: flutter pub run build_runner build --delete-conflicting-outputs

    - name: Analyze
      run: flutter analyze

    - name: Test
      run: flutter test

    - name: Build APK
      run: flutter build apk --release

    - name: Upload APK
      uses: actions/upload-artifact@v3
      with:
        name: release-apk
        path: build/app/outputs/flutter-apk/app-release.apk
```

### Tests d'integration en CI

```yaml
# Ajouter apres le build
- name: Integration tests
  uses: reactivecircus/android-emulator-runner@v2
  with:
    api-level: 29
    script: flutter test integration_test/app_test.dart
```

## Distribution

### GitHub Releases

1. Taguez une version :
```bash
git tag -a v1.0.0 -m "Release 1.0.0"
git push origin v1.0.0
```

2. Creez une release sur GitHub avec l'APK attache

### Play Store

1. Creez un compte developpeur Google Play
2. Creez une fiche d'application
3. Uploadez l'AAB
4. Remplissez les informations requises
5. Soumettez pour revue

## Versioning

Dans `pubspec.yaml` :

```yaml
version: 1.0.0+1
#        ^^^^^  ^
#        |      |
#        |      +-- build number (versionCode Android)
#        +--------- version name (versionName Android)
```

Incrementer avant chaque release :
- **Patch** (1.0.X) : Corrections de bugs
- **Minor** (1.X.0) : Nouvelles fonctionnalites
- **Major** (X.0.0) : Changements majeurs
