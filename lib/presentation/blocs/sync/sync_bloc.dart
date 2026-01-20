import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/sync_service.dart';
import 'sync_event.dart';
import 'sync_state.dart';

/// Sync BLoC
/// Manages synchronization state and automatic syncing
class SyncBloc extends Bloc<SyncEvent, SyncState> {
  final SyncService _syncService;
  StreamSubscription<void>? _syncSubscription;

  SyncBloc(this._syncService) : super(const SyncInitial()) {
    on<StartSyncListener>(_onStartSyncListener);
    on<StopSyncListener>(_onStopSyncListener);
    on<TriggerSync>(_onTriggerSync);
    on<SyncStatusChanged>(_onSyncStatusChanged);
  }

  Future<void> _onStartSyncListener(
    StartSyncListener event,
    Emitter<SyncState> emit,
  ) async {
    // Check initial connectivity
    final pendingRecords = await _syncService.getPendingRecordsCount();
    final isOnline = await _checkConnectivity();

    emit(SyncReady(
      isOnline: isOnline,
      isSyncing: false,
      pendingRecords: pendingRecords,
    ));

    // Start listening to connectivity changes
    _syncService.startSyncListener((isOnline, pendingRecords) {
      add(SyncStatusChanged(isOnline));
    });

    // Trigger initial sync if online
    if (isOnline) {
      add(const TriggerSync());
    }
  }

  Future<void> _onStopSyncListener(
    StopSyncListener event,
    Emitter<SyncState> emit,
  ) async {
    _syncService.stopSyncListener();
    _syncSubscription?.cancel();
    emit(const SyncInitial());
  }

  Future<void> _onTriggerSync(
    TriggerSync event,
    Emitter<SyncState> emit,
  ) async {
    final currentState = state;
    if (currentState is SyncReady && currentState.isSyncing) {
      return; // Already syncing
    }

    final isOnline = await _checkConnectivity();
    if (!isOnline) {
      emit(SyncReady(
        isOnline: false,
        isSyncing: false,
        pendingRecords: currentState is SyncReady ? currentState.pendingRecords : 0,
        error: 'No internet connection',
      ));
      return;
    }

    // Update state to syncing
    final pendingRecords = await _syncService.getPendingRecordsCount();
    emit(SyncReady(
      isOnline: true,
      isSyncing: true,
      pendingRecords: pendingRecords,
    ));

    try {
      await _syncService.syncAllPendingRecords();
      final newPendingRecords = await _syncService.getPendingRecordsCount();
      emit(SyncReady(
        isOnline: true,
        isSyncing: false,
        pendingRecords: newPendingRecords,
        lastSyncTime: DateTime.now().toIso8601String(),
      ));
    } catch (e) {
      emit(SyncReady(
        isOnline: true,
        isSyncing: false,
        pendingRecords: pendingRecords,
        error: 'Sync failed: $e',
      ));
    }
  }

  Future<void> _onSyncStatusChanged(
    SyncStatusChanged event,
    Emitter<SyncState> emit,
  ) async {
    final pendingRecords = await _syncService.getPendingRecordsCount();
    final currentState = state;

    if (currentState is SyncReady) {
      emit(currentState.copyWith(
        isOnline: event.isOnline,
        pendingRecords: pendingRecords,
      ));

      // Auto-sync when connection is restored
      if (event.isOnline && !currentState.isSyncing) {
        add(const TriggerSync());
      }
    } else {
      emit(SyncReady(
        isOnline: event.isOnline,
        isSyncing: false,
        pendingRecords: pendingRecords,
      ));
    }
  }

  Future<bool> _checkConnectivity() async {
    try {
      return await _syncService.hasInternetConnection();
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> close() {
    _syncSubscription?.cancel();
    _syncService.stopSyncListener();
    return super.close();
  }
}

