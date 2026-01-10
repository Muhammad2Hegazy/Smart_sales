import 'package:equatable/equatable.dart';

/// Sync States
abstract class SyncState extends Equatable {
  const SyncState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class SyncInitial extends SyncState {
  const SyncInitial();
}

/// Ready state - sync is ready
class SyncReady extends SyncState {
  final bool isOnline;
  final bool isSyncing;
  final int pendingRecords;
  final String? lastSyncTime;
  final String? error;

  const SyncReady({
    this.isOnline = false,
    this.isSyncing = false,
    this.pendingRecords = 0,
    this.lastSyncTime,
    this.error,
  });

  SyncReady copyWith({
    bool? isOnline,
    bool? isSyncing,
    int? pendingRecords,
    String? lastSyncTime,
    String? error,
  }) {
    return SyncReady(
      isOnline: isOnline ?? this.isOnline,
      isSyncing: isSyncing ?? this.isSyncing,
      pendingRecords: pendingRecords ?? this.pendingRecords,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        isOnline,
        isSyncing,
        pendingRecords,
        lastSyncTime,
        error,
      ];
}

/// Syncing state
class SyncSyncing extends SyncState {
  final int totalRecords;
  final int syncedRecords;
  const SyncSyncing({
    required this.totalRecords,
    required this.syncedRecords,
  });

  @override
  List<Object?> get props => [totalRecords, syncedRecords];
}

/// Error state
class SyncError extends SyncState {
  final String message;
  const SyncError(this.message);

  @override
  List<Object?> get props => [message];
}

