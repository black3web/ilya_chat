// File: lib/services/connectivity_service.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityProvider = StreamProvider<bool>((ref) {
  return Connectivity()
      .onConnectivityChanged
      .map((results) => !results.contains(ConnectivityResult.none));
});

final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).maybeWhen(
        data: (online) => online,
        orElse: () => true,
      );
});

class ConnectivityService {
  final _conn = Connectivity();

  Future<bool> isConnected() async {
    final results = await _conn.checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }

  Stream<bool> get onConnectivityChanged =>
      _conn.onConnectivityChanged
          .map((r) => !r.contains(ConnectivityResult.none));
}
