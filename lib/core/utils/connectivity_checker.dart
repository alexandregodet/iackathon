import 'dart:async';
import 'dart:io';

/// Utilitaire pour verifier la connectivite reseau
class ConnectivityChecker {
  /// Verifie si l'appareil a une connexion internet
  /// Utilise un DNS lookup comme test leger de connectivite
  static Future<bool> hasConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Verifie la connectivite vers un hote specifique
  static Future<bool> canReachHost(String host) async {
    try {
      final result = await InternetAddress.lookup(host)
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
