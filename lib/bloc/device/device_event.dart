import 'package:equatable/equatable.dart';

/// Device Events
abstract class DeviceEvent extends Equatable {
  const DeviceEvent();

  @override
  List<Object?> get props => [];
}

/// Initialize master device
class InitializeMaster extends DeviceEvent {
  final String userId; // Required: userId from authenticated user
  final String? deviceName;
  const InitializeMaster({
    required this.userId,
    this.deviceName,
  });

  @override
  List<Object?> get props => [userId, deviceName];
}

/// Load devices
class LoadDevices extends DeviceEvent {
  const LoadDevices();
}

/// Update master name
class UpdateMasterName extends DeviceEvent {
  final String masterDeviceId;
  final String newName;
  const UpdateMasterName({
    required this.masterDeviceId,
    required this.newName,
  });

  @override
  List<Object?> get props => [masterDeviceId, newName];
}

/// Register current device
class RegisterCurrentDevice extends DeviceEvent {
  final String masterDeviceId;
  final String? deviceName;
  final bool isMaster;
  final String? macAddress;
  const RegisterCurrentDevice({
    required this.masterDeviceId,
    this.deviceName,
    this.isMaster = false,
    this.macAddress,
  });

  @override
  List<Object?> get props => [masterDeviceId, deviceName, isMaster, macAddress];
}

/// Update device last seen
class UpdateDeviceLastSeen extends DeviceEvent {
  final String masterDeviceId;
  final String deviceId;
  const UpdateDeviceLastSeen({
    required this.masterDeviceId,
    required this.deviceId,
  });

  @override
  List<Object?> get props => [masterDeviceId, deviceId];
}

/// Delete device
class DeleteDevice extends DeviceEvent {
  final String masterDeviceId;
  final String deviceId;
  const DeleteDevice({
    required this.masterDeviceId,
    required this.deviceId,
  });

  @override
  List<Object?> get props => [masterDeviceId, deviceId];
}

/// Set device as master
class SetDeviceAsMaster extends DeviceEvent {
  final String masterDeviceId;
  final String deviceId;
  const SetDeviceAsMaster({
    required this.masterDeviceId,
    required this.deviceId,
  });

  @override
  List<Object?> get props => [masterDeviceId, deviceId];
}

/// Delete all devices except current device
class DeleteAllDevices extends DeviceEvent {
  final String masterDeviceId;
  final String currentDeviceId;
  const DeleteAllDevices({
    required this.masterDeviceId,
    required this.currentDeviceId,
  });

  @override
  List<Object?> get props => [masterDeviceId, currentDeviceId];
}

/// Update device floor
class UpdateDeviceFloor extends DeviceEvent {
  final String deviceId;
  final int? floor;
  const UpdateDeviceFloor({
    required this.deviceId,
    this.floor,
  });

  @override
  List<Object?> get props => [deviceId, floor];
}

