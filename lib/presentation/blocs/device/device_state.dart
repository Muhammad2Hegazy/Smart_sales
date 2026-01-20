import 'package:equatable/equatable.dart';
import '../../../core/models/master.dart';
import '../../../core/models/device.dart';

/// Device States
abstract class DeviceState extends Equatable {
  const DeviceState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class DeviceInitial extends DeviceState {
  const DeviceInitial();
}

/// Loading state
class DeviceLoading extends DeviceState {
  const DeviceLoading();
}

/// Ready state - devices loaded successfully
class DeviceReady extends DeviceState {
  final Master? master;
  final List<Device> devices;
  final Device? currentDevice;

  const DeviceReady({
    this.master,
    this.devices = const [],
    this.currentDevice,
  });

  DeviceReady copyWith({
    Master? master,
    List<Device>? devices,
    Device? currentDevice,
  }) {
    return DeviceReady(
      master: master ?? this.master,
      devices: devices ?? this.devices,
      currentDevice: currentDevice ?? this.currentDevice,
    );
  }

  @override
  List<Object?> get props => [master, devices, currentDevice];
}

/// Error state
class DeviceError extends DeviceState {
  final String message;
  const DeviceError(this.message);

  @override
  List<Object?> get props => [message];
}

