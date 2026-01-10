import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/repositories/device_repository.dart';
import '../../core/models/device.dart';
import '../../core/utils/mac_address_helper.dart';
import 'device_event.dart';
import 'device_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device BLoC
/// Manages master device and linked devices state
class DeviceBloc extends Bloc<DeviceEvent, DeviceState> {
  final DeviceRepository _deviceRepository;
  String? _currentDeviceId;

  DeviceBloc(this._deviceRepository) : super(const DeviceInitial()) {
    on<InitializeMaster>(_onInitializeMaster);
    on<LoadDevices>(_onLoadDevices);
    on<UpdateMasterName>(_onUpdateMasterName);
    on<RegisterCurrentDevice>(_onRegisterCurrentDevice);
    on<UpdateDeviceLastSeen>(_onUpdateDeviceLastSeen);
    on<DeleteDevice>(_onDeleteDevice);
    on<SetDeviceAsMaster>(_onSetDeviceAsMaster);
    on<DeleteAllDevices>(_onDeleteAllDevices);
    on<UpdateDeviceFloor>(_onUpdateDeviceFloor);
  }

  Future<void> _onInitializeMaster(
    InitializeMaster event,
    Emitter<DeviceState> emit,
  ) async {
    emit(const DeviceLoading());
    try {
      final master = await _deviceRepository.initializeMaster(
        userId: event.userId,
        deviceName: event.deviceName,
      );

      // Register current device as master if it's the first device
      final devices = await _deviceRepository.getDevicesByMasterId(master.masterDeviceId);
      if (devices.isEmpty) {
        await _getCurrentDeviceId(); // Initialize device ID
        // Get physical MAC address
        final macAddress = await MacAddressHelper.getMacAddress();
        // Check if this is developer MAC - use "DEV" instead of "Master Device"
        const developerMacAddress = 'E0:0A:F6:C3:BA:FF';
        final deviceName = (macAddress != null && macAddress.toUpperCase() == developerMacAddress.toUpperCase())
            ? 'DEV'
            : 'Master Device';
        final currentDevice = await _deviceRepository.registerCurrentDevice(
          masterDeviceId: master.masterDeviceId,
          deviceName: deviceName,
          isMaster: true,
          macAddress: macAddress,
        );
        _currentDeviceId = currentDevice.deviceId;

        final updatedDevices = await _deviceRepository.getDevicesByMasterId(master.masterDeviceId);
        emit(DeviceReady(
          master: master,
          devices: updatedDevices,
          currentDevice: currentDevice,
        ));
      } else {
        // Get current device or register it
        final currentDeviceId = await _getCurrentDeviceId();
        Device? currentDevice;
        for (final device in devices) {
          if (device.deviceId == currentDeviceId) {
            currentDevice = device;
            break;
          }
        }

        if (currentDevice == null) {
          // Check by MAC address first
          final macAddress = await MacAddressHelper.getMacAddress();
          Device? deviceByMac;
          if (macAddress != null && macAddress.isNotEmpty) {
            deviceByMac = await _deviceRepository.getDeviceByMacAddress(macAddress);
          }
          
          if (deviceByMac != null) {
            // Device with this MAC already exists - use it
            currentDevice = deviceByMac;
            // Update last seen
            await _deviceRepository.updateDeviceLastSeen(master.masterDeviceId, deviceByMac.deviceId);
          } else {
            // Register as new device with MAC address
            currentDevice = await _deviceRepository.registerCurrentDevice(
              masterDeviceId: master.masterDeviceId,
              deviceName: 'Device ${currentDeviceId.substring(0, 8)}',
              isMaster: false,
              macAddress: macAddress,
            );
          }
          _currentDeviceId = currentDevice.deviceId;
          final updatedDevices = await _deviceRepository.getDevicesByMasterId(master.masterDeviceId);
          emit(DeviceReady(
            master: master,
            devices: updatedDevices,
            currentDevice: currentDevice,
          ));
        } else {
          _currentDeviceId = currentDevice.deviceId;
          emit(DeviceReady(
            master: master,
            devices: devices,
            currentDevice: currentDevice,
          ));
        }
      }
    } catch (e) {
      emit(DeviceError('Failed to initialize master: $e'));
    }
  }

  Future<void> _onLoadDevices(
    LoadDevices event,
    Emitter<DeviceState> emit,
  ) async {
    emit(const DeviceLoading());
    try {
      final master = await _deviceRepository.getMaster();
      if (master == null) {
        emit(const DeviceError('No master device found. Please initialize master first.'));
        return;
      }

      final devices = await _deviceRepository.getDevicesByMasterId(master.masterDeviceId);
      
      // Try to find current device by MAC address first
      Device? currentDevice;
      final macAddress = await MacAddressHelper.getMacAddress();
      if (macAddress != null && macAddress.isNotEmpty) {
        currentDevice = await _deviceRepository.getDeviceByMacAddress(macAddress);
        if (currentDevice != null) {
          // Update last seen
          await _deviceRepository.updateDeviceLastSeen(master.masterDeviceId, currentDevice.deviceId);
          _currentDeviceId = currentDevice.deviceId;
        }
      }
      
      // Fallback to deviceId if MAC address lookup failed
      if (currentDevice == null) {
        final currentDeviceId = await _getCurrentDeviceId();
        currentDevice = devices.firstWhere(
          (d) => d.deviceId == currentDeviceId,
          orElse: () => devices.isNotEmpty ? devices.first : throw StateError('No devices found'),
        );
        _currentDeviceId = currentDevice.deviceId;
      }

      emit(DeviceReady(
        master: master,
        devices: devices,
        currentDevice: currentDevice,
      ));
    } catch (e) {
      emit(DeviceError('Failed to load devices: $e'));
    }
  }

  Future<void> _onUpdateMasterName(
    UpdateMasterName event,
    Emitter<DeviceState> emit,
  ) async {
    try {
      await _deviceRepository.updateMasterName(event.masterDeviceId, event.newName);
      final master = await _deviceRepository.getMaster();
      final devices = await _deviceRepository.getDevicesByMasterId(event.masterDeviceId);
      final currentDeviceId = await _getCurrentDeviceId();
      final currentDevice = devices.firstWhere(
        (d) => d.deviceId == currentDeviceId,
        orElse: () => devices.first,
      );

      emit(DeviceReady(
        master: master,
        devices: devices,
        currentDevice: currentDevice,
      ));
    } catch (e) {
      emit(DeviceError('Failed to update master name: $e'));
    }
  }

  Future<void> _onRegisterCurrentDevice(
    RegisterCurrentDevice event,
    Emitter<DeviceState> emit,
  ) async {
    try {
      // If MAC address not provided, get physical MAC address
      String? macAddress = event.macAddress;
      if (macAddress == null || macAddress.isEmpty) {
        macAddress = await MacAddressHelper.getMacAddress();
      }
      
      final device = await _deviceRepository.registerCurrentDevice(
        masterDeviceId: event.masterDeviceId,
        deviceName: event.deviceName,
        isMaster: event.isMaster,
        macAddress: macAddress,
      );
      _currentDeviceId = device.deviceId;

      final master = await _deviceRepository.getMaster();
      final devices = await _deviceRepository.getDevicesByMasterId(event.masterDeviceId);
      emit(DeviceReady(
        master: master,
        devices: devices,
        currentDevice: device,
      ));
    } catch (e) {
      emit(DeviceError('Failed to register device: $e'));
    }
  }

  Future<void> _onUpdateDeviceLastSeen(
    UpdateDeviceLastSeen event,
    Emitter<DeviceState> emit,
  ) async {
    try {
      await _deviceRepository.updateDeviceLastSeen(event.masterDeviceId, event.deviceId);
      final master = await _deviceRepository.getMaster();
      final devices = await _deviceRepository.getDevicesByMasterId(event.masterDeviceId);
      final currentDeviceId = await _getCurrentDeviceId();
      final currentDevice = devices.firstWhere(
        (d) => d.deviceId == currentDeviceId,
        orElse: () => devices.first,
      );

      emit(DeviceReady(
        master: master,
        devices: devices,
        currentDevice: currentDevice,
      ));
    } catch (e) {
      // Silently fail for last seen updates
    }
  }

  Future<void> _onDeleteDevice(
    DeleteDevice event,
    Emitter<DeviceState> emit,
  ) async {
    try {
      // Check if the device being deleted is the current device
      final currentDeviceId = await _getCurrentDeviceId();
      final isCurrentDeviceDeleted = event.deviceId == currentDeviceId;
      
      await _deviceRepository.deleteDevice(event.masterDeviceId, event.deviceId);
      final master = await _deviceRepository.getMaster();
      final devices = await _deviceRepository.getDevicesByMasterId(event.masterDeviceId);
      
      // If current device was deleted, emit state with null currentDevice to indicate logout needed
      if (isCurrentDeviceDeleted) {
        emit(DeviceReady(
          master: master,
          devices: devices,
          currentDevice: null, // null indicates current device was deleted
        ));
      } else {
        final currentDevice = devices.firstWhere(
          (d) => d.deviceId == currentDeviceId,
          orElse: () => devices.isNotEmpty ? devices.first : throw StateError('No devices found'),
        );

        emit(DeviceReady(
          master: master,
          devices: devices,
          currentDevice: currentDevice,
        ));
      }
    } catch (e) {
      emit(DeviceError('Failed to delete device: $e'));
    }
  }

  Future<void> _onSetDeviceAsMaster(
    SetDeviceAsMaster event,
    Emitter<DeviceState> emit,
  ) async {
    try {
      await _deviceRepository.setDeviceAsMaster(event.masterDeviceId, event.deviceId);
      final master = await _deviceRepository.getMaster();
      final devices = await _deviceRepository.getDevicesByMasterId(event.masterDeviceId);
      final currentDeviceId = await _getCurrentDeviceId();
      final currentDevice = devices.firstWhere(
        (d) => d.deviceId == currentDeviceId,
        orElse: () => devices.first,
      );

      emit(DeviceReady(
        master: master,
        devices: devices,
        currentDevice: currentDevice,
      ));
    } catch (e) {
      emit(DeviceError('Failed to set device as master: $e'));
    }
  }

  Future<void> _onDeleteAllDevices(
    DeleteAllDevices event,
    Emitter<DeviceState> emit,
  ) async {
    try {
      final devices = await _deviceRepository.getDevicesByMasterId(event.masterDeviceId);
      for (final device in devices) {
        if (device.deviceId != event.currentDeviceId) {
          await _deviceRepository.deleteDevice(event.masterDeviceId, device.deviceId);
        }
      }
      final master = await _deviceRepository.getMaster();
      final updatedDevices = await _deviceRepository.getDevicesByMasterId(event.masterDeviceId);
      final currentDevice = updatedDevices.firstWhere(
        (d) => d.deviceId == event.currentDeviceId,
        orElse: () => updatedDevices.first,
      );

      emit(DeviceReady(
        master: master,
        devices: updatedDevices,
        currentDevice: currentDevice,
      ));
    } catch (e) {
      emit(DeviceError('Failed to delete all devices: $e'));
    }
  }

  Future<void> _onUpdateDeviceFloor(
    UpdateDeviceFloor event,
    Emitter<DeviceState> emit,
  ) async {
    try {
      await _deviceRepository.updateDeviceFloor(event.deviceId, event.floor);
      final master = await _deviceRepository.getMaster();
      if (master != null) {
        final devices = await _deviceRepository.getDevicesByMasterId(master.masterDeviceId);
        final currentDeviceId = await _getCurrentDeviceId();
        final currentDevice = devices.firstWhere(
          (d) => d.deviceId == currentDeviceId,
          orElse: () => devices.isNotEmpty ? devices.first : throw StateError('No devices found'),
        );

        emit(DeviceReady(
          master: master,
          devices: devices,
          currentDevice: currentDevice,
        ));
      }
    } catch (e) {
      emit(DeviceError('Failed to update device floor: $e'));
    }
  }

  /// Get current device ID from SharedPreferences or generate new one
  Future<String> _getCurrentDeviceId() async {
    if (_currentDeviceId != null) return _currentDeviceId!;

    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('current_device_id');

    if (deviceId == null) {
      deviceId = await _deviceRepository.getCurrentDeviceId();
      await prefs.setString('current_device_id', deviceId);
    }

    _currentDeviceId = deviceId;
    return deviceId;
  }
}

