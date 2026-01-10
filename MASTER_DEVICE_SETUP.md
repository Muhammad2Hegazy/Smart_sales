# Master-Device System Setup Guide

This document explains how to set up and use the Master-Device synchronization system in Smart Sales.

## Overview

The Master-Device system enables:
- **Offline-first architecture**: All data is stored locally first
- **Automatic synchronization**: Data syncs to Cloud Firestore when internet is available
- **Multi-device support**: Multiple devices can be linked to a master device
- **Conflict resolution**: Last write wins based on `updatedAt` timestamp

## Architecture

### Firestore Structure

```
masters/
  {masterDeviceId}/
    name: string
    createdAt: timestamp
    devices/
      {deviceId}/
        deviceName: string
        masterDeviceId: string
        isMaster: boolean
        lastSeenAt: timestamp
    data/
      {dataType}/
        records/
          {recordId}/
            ... (all app data)
```

### Database Schema

All local database tables now include:
- `master_device_id`: Links data to master device
- `sync_status`: 'pending', 'synced', or 'failed'
- `updated_at`: Timestamp for conflict resolution

## Setup Instructions

### 1. Firebase Setup

1. Create a Firebase project at https://console.firebase.google.com
2. Enable Cloud Firestore
3. Copy your Firebase configuration
4. Add `firebase_options.dart` to your project (or configure manually)

#### Option A: Using FlutterFire CLI (Recommended)

```bash
flutter pub global activate flutterfire_cli
flutterfire configure
```

#### Option B: Manual Configuration

Create `lib/firebase_options.dart` or configure in `main.dart`:

```dart
await Firebase.initializeApp(
  options: const FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    // ... other options
  ),
);
```

### 2. Deploy Firestore Rules

Deploy the security rules from `firestore.rules`:

```bash
firebase deploy --only firestore:rules
```

Or manually copy the rules from `firestore.rules` to Firebase Console > Firestore > Rules.

### 3. App Initialization

The app automatically:
1. Initializes master device on first launch
2. Registers current device
3. Starts sync listener
4. Syncs data when internet is available

No manual intervention required!

## Usage

### Settings Page

The Settings page now includes:

1. **Device Management Section**:
   - Master device name (editable)
   - List of all linked devices
   - Current device indicator

2. **Sync Status Section**:
   - Online/Offline status
   - Pending records count
   - Manual sync button
   - Last sync time

### How It Works

1. **First Launch**:
   - App creates a master device automatically
   - Current device is registered as master
   - All data is linked to this master

2. **Data Operations**:
   - All writes go to local database first
   - Records are marked as 'pending' for sync
   - When online, pending records sync to Firestore

3. **Multi-Device**:
   - Other devices can be added manually or automatically
   - All devices share the same masterDeviceId
   - Data syncs across all devices

4. **Conflict Resolution**:
   - When syncing, records with newer `updatedAt` win
   - Local database is always the source of truth
   - Firestore is used for backup and multi-device sync

## Important Notes

### Master Device ID

- Every piece of data MUST have a `masterDeviceId`
- This links all data to the master device
- The master device ID is generated on first launch
- It's stored locally and synced to Firestore

### Sync Status

- `pending`: Record needs to be synced
- `synced`: Record is synced to Firestore
- `failed`: Sync failed (will retry on next sync)

### Offline Mode

- App works completely offline
- All operations work on local database
- Sync happens automatically when online
- No user intervention required

## Troubleshooting

### Sync Not Working

1. Check internet connection
2. Verify Firebase configuration
3. Check Firestore rules
4. Review sync status in Settings

### Data Not Syncing

1. Check `sync_status` in database
2. Verify `master_device_id` is set
3. Check Firestore console for errors
4. Review app logs

### Multiple Masters

- Only one master should exist per installation
- If multiple masters exist, the first one is used
- To reset, clear app data and reinstall

## Security

**Important**: The current Firestore rules allow all reads/writes. For production:

1. Add Firebase Authentication
2. Update rules to require authentication
3. Add user-based access control
4. Implement proper security measures

Example secure rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /masters/{masterId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == resource.data.ownerId;
      // ... more rules
    }
  }
}
```

## API Reference

### DeviceBloc

- `InitializeMaster`: Initialize or get master device
- `LoadDevices`: Load all devices
- `UpdateMasterName`: Update master device name
- `RegisterCurrentDevice`: Register current device
- `DeleteDevice`: Delete a device

### SyncBloc

- `StartSyncListener`: Start listening to connectivity changes
- `StopSyncListener`: Stop sync listener
- `TriggerSync`: Manually trigger sync

### SyncService

- `syncAllPendingRecords()`: Sync all pending records
- `getPendingRecordsCount()`: Get count of pending records
- `markForSync(tableName, id)`: Mark record for sync

## Support

For issues or questions, check:
1. App logs for error messages
2. Firestore console for sync status
3. Database for sync_status values
4. Settings page for sync information

