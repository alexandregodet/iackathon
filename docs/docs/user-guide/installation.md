---
sidebar_position: 2
title: Installation
description: Comment installer IAckathon sur votre appareil Android
---

# Installation

Ce guide vous accompagne dans l'installation de IAckathon sur votre appareil Android.

## Configuration requise

Avant d'installer IAckathon, assurez-vous que votre appareil repond aux exigences suivantes :

### Minimum requis

| Composant | Requirement |
|-----------|-------------|
| **Systeme** | Android 8.0 (API 26) ou superieur |
| **RAM** | 4 Go minimum |
| **Stockage** | 2 Go d'espace libre (+ espace pour les modeles) |
| **Processeur** | ARM64 (aarch64) |

### Recommande

| Composant | Recommandation |
|-----------|----------------|
| **Systeme** | Android 12 ou superieur |
| **RAM** | 8 Go ou plus |
| **Stockage** | 10 Go d'espace libre |
| **Processeur** | Snapdragon 8xx ou equivalent |

:::tip Conseil
Les modeles d'IA peuvent etre volumineux (jusqu'a 4 Go). Assurez-vous d'avoir suffisamment d'espace de stockage.
:::

## Methode 1 : Installation depuis le fichier APK

### Etape 1 : Telecharger l'APK

Telechargez la derniere version de l'APK depuis la page des releases :

```
https://github.com/iackathon/iackathon/releases/latest
```

### Etape 2 : Autoriser les sources inconnues

1. Allez dans **Parametres** > **Securite**
2. Activez **Sources inconnues** ou **Installer des applications inconnues**
3. Selectionnez votre navigateur ou gestionnaire de fichiers

### Etape 3 : Installer l'application

1. Ouvrez le fichier APK telecharge
2. Appuyez sur **Installer**
3. Attendez la fin de l'installation
4. Appuyez sur **Ouvrir**

## Methode 2 : Compilation depuis les sources

Pour les utilisateurs avances qui souhaitent compiler l'application :

### Prerequis

- Flutter SDK 3.10 ou superieur
- Android SDK
- Git

### Etapes

```bash
# Cloner le depot
git clone https://github.com/iackathon/iackathon.git
cd iackathon

# Installer les dependances
flutter pub get

# Compiler en mode release
flutter build apk --release

# L'APK se trouve dans build/app/outputs/flutter-apk/
```

## Apres l'installation

Une fois l'application installee, vous devrez :

1. **Choisir un modele** - Selectionnez le modele d'IA adapte a votre appareil
2. **Telecharger le modele** - Le telechargement peut prendre plusieurs minutes
3. **Charger le modele** - L'initialisation prend quelques secondes

Consultez le guide [Premiers pas](/user-guide/first-steps) pour commencer a utiliser l'application.

## Depannage

### L'installation echoue

**Probleme** : Message "Installation bloquee" ou "App non verifiee"

**Solution** :
1. Desactivez Google Play Protect temporairement
2. Allez dans Play Store > Menu > Play Protect > Parametres
3. Desactivez "Analyser les applications"
4. Reinstallez l'APK
5. Reactivez Play Protect

### L'application ne demarre pas

**Probleme** : L'application se ferme immediatement

**Solutions possibles** :
- Verifiez que vous avez Android 8.0 ou superieur
- Liberez de la RAM en fermant d'autres applications
- Redemarrez votre appareil

### Espace de stockage insuffisant

**Probleme** : Impossible de telecharger le modele

**Solution** :
- Liberez de l'espace en supprimant des fichiers ou applications
- Choisissez un modele plus leger (Gemma 3 1B = 900 Mo)
