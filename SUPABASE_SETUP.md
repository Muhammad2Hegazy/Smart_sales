# Supabase Setup Guide

This document explains how to set up Supabase for the Master-Device synchronization system.

## Overview

The app uses Supabase (PostgreSQL) as the online database backend. All data is stored locally first (offline-first), then synced to Supabase when internet is available.

## Setup Instructions

### 1. Create Supabase Project

1. Go to https://supabase.com and sign up/login
2. Create a new project
3. Note your project URL and anon key from Settings > API

### 2. Run SQL Schema

1. Open Supabase Dashboard > SQL Editor
2. Copy and paste the contents of `supabase_schema.sql`
3. Run the SQL to create all required tables and indexes

### 3. Configure App

#### Option A: Environment Variables (Recommended)

Set environment variables before running:

```bash
# Windows (PowerShell)
$env:SUPABASE_URL="https://your-project.supabase.co"
$env:SUPABASE_ANON_KEY="your-anon-key"

# Linux/Mac
export SUPABASE_URL="https://your-project.supabase.co"
export SUPABASE_ANON_KEY="your-anon-key"
```

#### Option B: Update main.dart Directly

Edit `lib/main.dart` and replace the placeholder values:

```dart
const supabaseUrl = 'https://your-project.supabase.co';
const supabaseAnonKey = 'your-anon-key';
```

**Note**: For production, use environment variables or a secure config file. Never commit API keys to version control.

### 4. Test Connection

1. Run the app
2. Check Settings page for sync status
3. Verify data appears in Supabase Dashboard > Table Editor

## Database Structure

### Tables

1. **masters**: Master device information
   - `master_device_id` (UUID, Primary Key)
   - `master_name` (TEXT)
   - `created_at` (TIMESTAMPTZ)
   - `updated_at` (TIMESTAMPTZ)

2. **devices**: All devices (master and slaves)
   - `device_id` (UUID, Primary Key)
   - `device_name` (TEXT)
   - `master_device_id` (UUID, Foreign Key)
   - `is_master` (BOOLEAN)
   - `last_seen_at` (TIMESTAMPTZ)
   - `created_at` (TIMESTAMPTZ)
   - `updated_at` (TIMESTAMPTZ)

3. **app_data**: Generic table for all app data
   - `id` (UUID, Primary Key)
   - `master_device_id` (UUID, Foreign Key)
   - `table_name` (TEXT) - e.g., 'categories', 'items', 'sales'
   - `record_id` (TEXT) - The ID from local database
   - `payload` (JSONB) - The actual data
   - `sync_status` (TEXT) - 'pending', 'synced', or 'failed'
   - `updated_at` (TIMESTAMPTZ)
   - `created_at` (TIMESTAMPTZ)
   - Unique constraint on (master_device_id, table_name, record_id)

## How It Works

1. **Offline-First**: All writes go to local SQLite database first
2. **Sync Status**: Each record has `sync_status` field
3. **Automatic Sync**: When online, pending records sync to Supabase
4. **Conflict Resolution**: Last write wins (based on `updated_at`)

## Security

### Row Level Security (RLS)

The schema includes RLS policies that allow all operations for development. **For production**, you should:

1. Enable authentication in Supabase
2. Update RLS policies to require authentication
3. Add user-based access control

Example secure policy:

```sql
-- Replace the existing policy
DROP POLICY "Allow all operations on app_data" ON app_data;

CREATE POLICY "Users can only access their own data" ON app_data
    FOR ALL USING (
        auth.uid()::text = (payload->>'userId')::text
    );
```

## Troubleshooting

### Sync Not Working

1. Check internet connection
2. Verify Supabase credentials in main.dart
3. Check Supabase Dashboard > Logs for errors
4. Verify tables exist (run `supabase_schema.sql`)

### Data Not Appearing in Supabase

1. Check `sync_status` in local database
2. Verify `master_device_id` is set on records
3. Check Supabase Dashboard > Table Editor > app_data
4. Review app logs for sync errors

### Connection Errors

1. Verify Supabase URL and anon key
2. Check network connectivity
3. Verify Supabase project is active
4. Check Supabase Dashboard > Settings > API for correct URLs

## Monitoring

### View Sync Status

- Settings page shows sync status
- Check `app_data` table in Supabase Dashboard
- Filter by `sync_status` to see pending records

### View Devices

- Settings page shows all devices
- Check `devices` table in Supabase Dashboard
- Filter by `master_device_id` to see devices for a master

## Production Checklist

- [ ] Update RLS policies for security
- [ ] Use environment variables for credentials
- [ ] Enable Supabase authentication
- [ ] Set up monitoring and alerts
- [ ] Test offline/online scenarios
- [ ] Verify conflict resolution works
- [ ] Test multi-device sync

## Support

For issues:
1. Check app logs
2. Check Supabase Dashboard > Logs
3. Verify database schema matches `supabase_schema.sql`
4. Check Settings page for sync status

