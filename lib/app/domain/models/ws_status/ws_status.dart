import 'package:freezed_annotation/freezed_annotation.dart';
part 'ws_status.freezed.dart';

@freezed
class WsStatus with _$WsStatus {
  const factory WsStatus.connecting() = _WstatusConnecting;
  const factory WsStatus.connected() = _WstatusConnected;
  const factory WsStatus.failed() = _WsStatusFailed;
}
