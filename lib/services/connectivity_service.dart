import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

enum NetworkStatus {
  online,
  offline,
  unknown,
}

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<NetworkStatus> _statusController =
      StreamController<NetworkStatus>.broadcast();

  StreamSubscription<ConnectivityResult>? _subscription;
  NetworkStatus _currentStatus = NetworkStatus.unknown;

  // Public API
  Stream<NetworkStatus> get statusStream => _statusController.stream;

  NetworkStatus get currentStatus => _currentStatus;

  bool get isOnlineSync => _currentStatus == NetworkStatus.online;

  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return _resultHasConnection(result);
  }

  // Lifecycle
  Future<void> initialize() async {
    // Kiểm tra trạng thái ban đầu
    final initial = await _connectivity.checkConnectivity();
    _updateStatusSingle(initial);

    // Lắng nghe thay đổi mạng
    _subscription = _connectivity.onConnectivityChanged.listen(
      _updateStatusSingle,
      onError: (_) => _setStatus(NetworkStatus.offline),
    );
  }

  void dispose() {
    _subscription?.cancel();
    _statusController.close();
  }

  // Private Helpers
  bool _resultHasConnection(ConnectivityResult result) {
    return result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet;
  }

  void _updateStatusSingle(ConnectivityResult result) {
    _setStatus(
      _resultHasConnection(result)
          ? NetworkStatus.online
          : NetworkStatus.offline,
    );
  }

  void _setStatus(NetworkStatus status) {
    if (_currentStatus == status) return; // Không phát nếu không đổi
    _currentStatus = status;
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }
}
