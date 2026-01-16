import 'dart:async';
import 'package:flutter/foundation.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscriptions.add(
      stream.asBroadcastStream().listen((_) => notifyListeners()),
    );
  }

  /// Constructor que acepta múltiples streams
  GoRouterRefreshStream.multi(List<Stream<dynamic>> streams) {
    for (final stream in streams) {
      _subscriptions.add(
        stream.asBroadcastStream().listen((_) => notifyListeners()),
      );
    }
  }

  final List<StreamSubscription<dynamic>> _subscriptions = [];

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}
