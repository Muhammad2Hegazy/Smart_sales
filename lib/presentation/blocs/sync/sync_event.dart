import 'package:equatable/equatable.dart';

/// Sync Events
abstract class SyncEvent extends Equatable {
  const SyncEvent();

  @override
  List<Object?> get props => [];
}

/// Start sync listener
class StartSyncListener extends SyncEvent {
  const StartSyncListener();
}

/// Stop sync listener
class StopSyncListener extends SyncEvent {
  const StopSyncListener();
}

/// Trigger manual sync
class TriggerSync extends SyncEvent {
  const TriggerSync();
}

/// Sync status changed
class SyncStatusChanged extends SyncEvent {
  final bool isOnline;
  const SyncStatusChanged(this.isOnline);

  @override
  List<Object?> get props => [isOnline];
}

