import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../domain/models/ws_status/ws_status.dart';
import '../../../../domain/repositories/exchange_repository.dart';
import '../../../../domain/repositories/ws_repository.dart';
import 'home_state.dart';

class HomeBloc extends ChangeNotifier {
  HomeBloc({
    required this.exchangeRepository,
    required this.wsRepository,
  });

  final ExchangeRepository exchangeRepository;
  final WsRepository wsRepository;
  StreamSubscription? _pricesSubscription, _wsSubscription;

  HomeState _state = const HomeState.loading();
  HomeState get state => _state;
  final _ids = [
    'bitcoin',
    'ethereum',
    'tether',
    'binance-coin',
    'monero',
    'litecoin',
    'usd-coin',
    'dogecoin',
  ];
  Future<void> init() async {
    state.maybeWhen(
      loading: () {},
      orElse: () {
        _state = const HomeState.loading();
        notifyListeners();
      },
    );
    final res = await exchangeRepository.getPrices(_ids);
    _state = res.when(
        left: (failure) => HomeState.failed(failure),
        right: (cryptos) {
          startPricesListening();
          return HomeState.loaded(cryptos: cryptos);
        });
    notifyListeners();
  }

  Future<bool> startPricesListening() async {
    final connected = await wsRepository.connect(_ids);
    state.mapOrNull(
      loaded: (state) {
        if (connected) {
          _onPriceChanged();
        }
        _state = state.copyWith(
            wsStatus: connected
                ? const WsStatus.connected()
                : const WsStatus.failed());
        notifyListeners();
      },
    );
    return connected;
  }

  void _onPriceChanged() async {
    _pricesSubscription?.cancel();
    _wsSubscription?.cancel();
    _pricesSubscription = wsRepository.onPricesChanged.listen((changes) {
      state.mapOrNull(
        loaded: (state) {
          final keys = changes.keys;
          final cryptos = [
            ...state.cryptos.map((crypto) {
              if (keys.contains(crypto.id)) {
                return crypto.copyWith(price: changes[crypto.id]!);
              }
              return crypto;
            })
          ];
          _state = state.copyWith(cryptos: cryptos);
          notifyListeners();
        },
      );
    });
    _wsSubscription = wsRepository.onStatusChanged.listen((status) {
      state.mapOrNull(loaded: (state) {
        _state = state.copyWith(wsStatus: status);
        notifyListeners();
      });
    });
  }

  @override
  void dispose() {
    _pricesSubscription?.cancel();
    _wsSubscription?.cancel();
    super.dispose();
  }
}
