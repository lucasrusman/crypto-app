import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../bloc/home_bloc.dart';

class HomeError extends StatelessWidget {
  const HomeError({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final HomeBloc bloc = context.watch();
    final state = bloc.state;
    return state.maybeWhen(
      orElse: () => const SizedBox(),
      failed: (failure) {
        final message = failure.whenOrNull(
          network: () => 'Revisa tu conexion a internet',
          server: () => 'Error en el servidor',
        );
        if (message == null) return const SizedBox();
        return Center(child: Text(message));
      },
    );
  }
}
