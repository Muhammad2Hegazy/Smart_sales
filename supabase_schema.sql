-- Supabase SQL Schema for Master-Device System with Authentication
-- Run this SQL in your Supabase SQL Editor to create the required tables

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Masters table: Stores master device information
-- Linked to Supabase Auth users via userId
CREATE TABLE IF NOT EXISTS masters (
    master_device_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    master_name TEXT NOT NULL DEFAULT 'Master Device',
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- Ensure one master per user
    UNIQUE(user_id)
);

-- Devices table: Stores all devices (master and slaves)
CREATE TABLE IF NOT EXISTS devices (
    device_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_name TEXT NOT NULL,
    master_device_id UUID NOT NULL REFERENCES masters(master_device_id) ON DELETE CASCADE,
    is_master BOOLEAN NOT NULL DEFAULT FALSE,
    last_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- App data table: Generic table for all app data
-- Uses JSONB for flexible schema, linked via masterDeviceId
CREATE TABLE IF NOT EXISTS app_data (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    master_device_id UUID NOT NULL REFERENCES masters(master_device_id) ON DELETE CASCADE,
    table_name TEXT NOT NULL, -- e.g., 'categories', 'items', 'sales', etc.
    record_id TEXT NOT NULL, -- The ID of the record in the local database
    payload JSONB NOT NULL, -- The actual data as JSON
    sync_status TEXT NOT NULL DEFAULT 'pending' CHECK (sync_status IN ('pending', 'synced', 'failed')),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- Ensure unique records per master device and table
    UNIQUE(master_device_id, table_name, record_id)
);

-- Indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_masters_user_id ON masters(user_id);
CREATE INDEX IF NOT EXISTS idx_devices_master_device_id ON devices(master_device_id);
CREATE INDEX IF NOT EXISTS idx_devices_last_seen_at ON devices(last_seen_at);
CREATE INDEX IF NOT EXISTS idx_app_data_master_device_id ON app_data(master_device_id);
CREATE INDEX IF NOT EXISTS idx_app_data_table_name ON app_data(table_name);
CREATE INDEX IF NOT EXISTS idx_app_data_sync_status ON app_data(sync_status);
CREATE INDEX IF NOT EXISTS idx_app_data_updated_at ON app_data(updated_at);
CREATE INDEX IF NOT EXISTS idx_app_data_master_table_record ON app_data(master_device_id, table_name, record_id);

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers to auto-update updated_at
CREATE TRIGGER update_masters_updated_at BEFORE UPDATE ON masters
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_devices_updated_at BEFORE UPDATE ON devices
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_app_data_updated_at BEFORE UPDATE ON app_data
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security (RLS)
ALTER TABLE masters ENABLE ROW LEVEL SECURITY;
ALTER TABLE devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_data ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Allow all operations on masters" ON masters;
DROP POLICY IF EXISTS "Allow all operations on devices" ON devices;
DROP POLICY IF EXISTS "Allow all operations on app_data" ON app_data;

-- RLS Policies: Users can only access their own data
-- Masters: Users can only access masters where userId = auth.uid()
CREATE POLICY "Users can manage their own masters" ON masters
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Devices: Users can only access devices linked to their master
CREATE POLICY "Users can manage devices for their masters" ON devices
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM masters 
            WHERE masters.master_device_id = devices.master_device_id 
            AND masters.user_id = auth.uid()
        )
    ) WITH CHECK (
        EXISTS (
            SELECT 1 FROM masters 
            WHERE masters.master_device_id = devices.master_device_id 
            AND masters.user_id = auth.uid()
        )
    );

-- App data: Users can only access app_data linked to their master
CREATE POLICY "Users can manage app_data for their masters" ON app_data
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM masters 
            WHERE masters.master_device_id = app_data.master_device_id 
            AND masters.user_id = auth.uid()
        )
    ) WITH CHECK (
        EXISTS (
            SELECT 1 FROM masters 
            WHERE masters.master_device_id = app_data.master_device_id 
            AND masters.user_id = auth.uid()
        )
    );

-- Comments for documentation
COMMENT ON TABLE masters IS 'Stores master device information. Each user has one master device.';
COMMENT ON TABLE devices IS 'Stores all devices linked to a master device.';
COMMENT ON TABLE app_data IS 'Generic table for all app data. Each record is linked to a master device via master_device_id.';
COMMENT ON COLUMN masters.user_id IS 'Links master device to Supabase Auth user';
COMMENT ON COLUMN app_data.table_name IS 'The name of the table in the local database (e.g., categories, items, sales)';
COMMENT ON COLUMN app_data.record_id IS 'The ID of the record in the local database';
COMMENT ON COLUMN app_data.payload IS 'The actual data stored as JSONB for flexibility';
COMMENT ON COLUMN app_data.sync_status IS 'Status: pending (needs sync), synced (synced to Supabase), failed (sync failed)';
