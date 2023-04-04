// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../bloc/home_bloc.dart';

const colors = <String, Color>{
  'BTC': Colors.orange,
  'ETH': Colors.deepPurple,
  'USDT': Colors.green,
  'BNB': Colors.yellow,
  'USDC': Colors.blue,
  'DOGE': Colors.orange,
  'LTC': Colors.grey,
  'XMR': Colors.deepOrangeAccent,
};

class HomeLoaded extends StatelessWidget {
  const HomeLoaded({
    Key? key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final HomeBloc bloc = context.watch();
    final state = bloc.state;
    return state.maybeMap(
      orElse: () => const SizedBox(),
      loaded: (state) {
        final cryptos = state.cryptos;
        return ListView.builder(
          padding: const EdgeInsets.all(6),
          itemBuilder: (_, index) {
            final crypto = cryptos[index];
            return Padding(
              padding: const EdgeInsets.all(4.0),
              child: ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                leading: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/${crypto.symbol}.svg',
                      width: 30,
                      height: 30,
                      color: colors[crypto.symbol],
                    ),
                  ],
                ),
                title: Text(
                  crypto.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(crypto.symbol),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(NumberFormat.currency(name: r'$').format(crypto.price),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      '${crypto.changePercent24Hr.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: crypto.changePercent24Hr.isNegative
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          itemCount: cryptos.length,
        );
      },
    );
  }
}
