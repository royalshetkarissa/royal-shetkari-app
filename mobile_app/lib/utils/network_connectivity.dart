import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/offline_queue.dart';

class NetworkConnectivity {
  static final NetworkConnectivity _instance = NetworkConnectivity._internal();
  factory NetworkConnectivity() => _instance;
  NetworkConnectivity._internal();

  final Connectivity _connectivity = Connectivity();
  final OfflineQueueService _queue = OfflineQueueService();

  /**
   * Start monitoring connectivity changes.
   */
  void initialize() {
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.isNotEmpty && results.first != ConnectivityResult.none) {
        print('🌐 Internet is back! Starting sync...');
        _queue.syncQueue();
      } else {
        print('🚫 Internet is disconnected.');
      }
    });
  }

  /**
   * Check if currently online.
   */
  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return results.isNotEmpty && results.first != ConnectivityResult.none;
  }
}
