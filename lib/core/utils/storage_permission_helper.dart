import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

import 'app_logger.dart';

/// Helper pour gerer les permissions de stockage et les chemins des modeles locaux
class StoragePermissionHelper {
  /// Chemin de base pour les modeles locaux sur le stockage externe
  static const String localModelBasePath = '/storage/emulated/0/Download/data';

  /// Verifie et demande la permission de stockage externe
  /// Retourne true si la permission est accordee
  static Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) {
      AppLogger.info(
        'Permissions de stockage non requises sur cette plateforme',
        'StoragePermissionHelper',
      );
      return false;
    }

    // Android 11+ (API 30+) necessite MANAGE_EXTERNAL_STORAGE
    final manageStatus = await Permission.manageExternalStorage.status;
    if (manageStatus.isGranted) {
      AppLogger.info(
        'Permission MANAGE_EXTERNAL_STORAGE deja accordee',
        'StoragePermissionHelper',
      );
      return true;
    }

    // Demander la permission MANAGE_EXTERNAL_STORAGE
    final result = await Permission.manageExternalStorage.request();
    if (result.isGranted) {
      AppLogger.info(
        'Permission MANAGE_EXTERNAL_STORAGE accordee',
        'StoragePermissionHelper',
      );
      return true;
    }

    // Fallback sur READ_EXTERNAL_STORAGE pour Android < 11
    final storageStatus = await Permission.storage.status;
    if (storageStatus.isGranted) {
      AppLogger.info(
        'Permission storage deja accordee',
        'StoragePermissionHelper',
      );
      return true;
    }

    final storageResult = await Permission.storage.request();
    if (storageResult.isGranted) {
      AppLogger.info(
        'Permission storage accordee',
        'StoragePermissionHelper',
      );
      return true;
    }

    AppLogger.warning(
      'Permission de stockage refusee',
      'StoragePermissionHelper',
    );
    return false;
  }

  /// Verifie si un fichier de modele existe localement
  static Future<bool> localModelExists(String filename) async {
    final filePath = getLocalModelPath(filename);
    final exists = await File(filePath).exists();
    AppLogger.debug(
      'Verification fichier local $filePath: ${exists ? "existe" : "absent"}',
      'StoragePermissionHelper',
    );
    return exists;
  }

  /// Retourne le chemin complet du modele local
  static String getLocalModelPath(String filename) {
    return '$localModelBasePath/$filename';
  }
}
