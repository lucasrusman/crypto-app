import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';

import '../../../domain/either/either.dart';
import '../../../domain/failures/http_request_failure.dart';
import '../../../domain/models/crypto/crypto.dart';
import '../../../domain/repositories/exchange_repository.dart';

class ExchangeAPI {
  final Client _client;

  ExchangeAPI(this._client);

  GetPricesFuture getPrices(List<String> ids) async {
    try {
      final url = Uri.parse(
        'https://api.coincap.io/v2/assets?ids=${ids.join(',')}',
      );
      final res = await _client.get(url);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final cryptos = (json['data'] as List).map(
          (e) => Crypto(
            id: e['id'],
            symbol: e['symbol'],
            price: double.parse(e['priceUsd']),
            changePercent24Hr: double.parse(e['changePercent24Hr']),
            name: e['name'],
          ),
        );
        return Either.right(cryptos.toList());
      }
      if (res.statusCode == 404) throw HttpRequestFailure.notFound();
      if (res.statusCode >= 500) throw HttpRequestFailure.server();
      throw HttpRequestFailure.local();
    } catch (e) {
      late HttpRequestFailure failure;
      if (e is HttpRequestFailure) {
        failure = e;
      } else if (e is SocketException || e is ClientException) {
        failure = HttpRequestFailure.network();
      } else {
        failure = HttpRequestFailure.local();
      }
      return Either.left(failure);
    }
  }
}
