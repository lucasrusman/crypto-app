import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../domain/models/ws_status/ws_status.dart';
import '../../domain/repositories/ws_repository.dart';

class WsRepositoryImpl implements WsRepository {
  WsRepositoryImpl(
    this.builder, [
    this._reconnectDuration = const Duration(seconds: 5),
  ]);
  final WebSocketChannel Function(List<String> ids) builder;
  final Duration _reconnectDuration;
  WebSocketChannel? _channel;
  StreamController<Map<String, double>>? _pricescontroller;
  StreamController<WsStatus>? _wsController;
  StreamSubscription? _subscription;
  Timer? _timer;
  @override
  Future<bool> connect(List<String> ids) async {
    try {
      _notifyStatus(const WsStatus.connecting());
      _channel = builder(ids);
      await _channel!.ready;
      _subscription = _channel!.stream.listen(
        (event) {
          final map = Map<String, String>.from(jsonDecode(event));
          //aqui lo que hacemos es convertir de Map<String, String> a Map<String, double>
          final data = <String, double>{}..addEntries(
              map.entries.map(
                (e) => MapEntry(
                  e.key,
                  double.parse(e.value),
                ),
              ),
            );
          if (_pricescontroller?.hasListener ?? false) {
            _pricescontroller!.add(data);
          }
        },
        //utilizamos recursividad para reconectarnos al socket
        onDone: () => _reconnect(ids),
      );
      _notifyStatus(const WsStatus.connected());
      return true;
    } catch (e) {
      if (kDebugMode) print(e);
      _reconnect(ids);
      return false;
    }
  }

  void _reconnect(List<String> ids) {
    if (_subscription != null) {
      _timer?.cancel();
      _timer = Timer(_reconnectDuration, () => connect(ids));
    }
  }

  void _notifyStatus(WsStatus status) {
    if (_subscription == null) {
      return;
    }
    if (_wsController?.hasListener ?? false) {
      _wsController!.add(status);
    }
  }

  @override
  Future<void> disconnect() async {
    _subscription?.cancel();
    _timer?.cancel();
    _subscription = null;
    _timer = null;
    await _pricescontroller?.close();
    await _wsController?.close();
    await _channel?.sink.close();
    _channel = null;
  }

  @override
  Stream<Map<String, double>> get onPricesChanged {
    _pricescontroller ??= StreamController.broadcast();
    return _pricescontroller!.stream;
  }

  @override
  Stream<WsStatus> get onStatusChanged {
    _wsController ??= StreamController.broadcast();
    return _wsController!.stream;
  }
}
