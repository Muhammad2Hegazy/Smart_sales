-- Supabase SQL Schema for User Management and Permissions
-- Run this SQL in your Supabase SQL Editor to add user management features

-- Enable UUID extension (if not already enabled)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- User Profiles table: Stores user profile information including role
CREATE TABLE IF NOT EXISTS user_profiles (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('admin', 'user')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id),
    UNIQUE(email)
);

-- User Permissions table: Stores granular permissions for each user
CREATE TABLE IF NOT EXISTS user_permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    permission_key TEXT NOT NULL,
    allowed BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, permission_key)
);

-- Indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_user_profiles_role ON user_profiles(role);
CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON user_profiles(email);
CREATE INDEX IF NOT EXISTS idx_user_permissions_user_id ON user_permissions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_permissions_permission_key ON user_permissions(permission_key);

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_user_profiles_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE OR REPLACE FUNCTION update_user_permissions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers to auto-update updated_at
CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON user_profiles
    FOR EACH ROW EXECUTE FUNCTION update_user_profiles_updated_at();

CREATE TRIGGER update_user_permissions_updated_at BEFORE UPDATE ON user_permissions
    FOR EACH ROW EXECUTE FUNCTION update_user_permissions_updated_at();

-- Enable Row Level Security (RLS)
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_permissions ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own profile" ON user_profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON user_profiles;
DROP POLICY IF EXISTS "Admins can insert profiles" ON user_profiles;
DROP POLICY IF EXISTS "Admins can update profiles" ON user_profiles;
DROP POLICY IF EXISTS "Users can view their own permissions" ON user_permissions;
DROP POLICY IF EXISTS "Admins can view all permissions" ON user_permissions;
DROP POLICY IF EXISTS "Admins can insert permissions" ON user_permissions;
DROP POLICY IF EXISTS "Admins can update permissions" ON user_permissions;

-- Helper function to check if user is admin
CREATE OR REPLACE FUNCTION is_admin(user_id_param UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM user_profiles
        WHERE user_profiles.user_id = user_id_param
        AND user_profiles.role = 'admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RLS Policies for user_profiles

-- Policy: Users can view their own profile
CREATE POLICY "Users can view their own profile" ON user_profiles
    FOR SELECT USING (auth.uid() = user_id);

-- Policy: Admins can view all profiles
CREATE POLICY "Admins can view all profiles" ON user_profiles
    FOR SELECT USING (is_admin(auth.uid()));

-- Policy: Admins can insert profiles
CREATE POLICY "Admins can insert profiles" ON user_profiles
    FOR INSERT WITH CHECK (is_admin(auth.uid()));

-- Policy: Admins can update profiles (including roles)
CREATE POLICY "Admins can update profiles" ON user_profiles
    FOR UPDATE USING (is_admin(auth.uid()))
    WITH CHECK (is_admin(auth.uid()));

-- RLS Policies for user_permissions

-- Policy: Users can view their own permissions
CREATE POLICY "Users can view their own permissions" ON user_permissions
    FOR SELECT USING (auth.uid() = user_id);

-- Policy: Admins can view all permissions
CREATE POLICY "Admins can view all permissions" ON user_permissions
    FOR SELECT USING (is_admin(auth.uid()));

-- Policy: Admins can insert permissions
CREATE POLICY "Admins can insert permissions" ON user_permissions
    FOR INSERT WITH CHECK (is_admin(auth.uid()));

-- Policy: Admins can update permissions
CREATE POLICY "Admins can update permissions" ON user_permissions
    FOR UPDATE USING (is_admin(auth.uid()))
    WITH CHECK (is_admin(auth.uid()));

-- Policy: Admins can delete permissions
CREATE POLICY "Admins can delete permissions" ON user_permissions
    FOR DELETE USING (is_admin(auth.uid()));

-- Comments for documentation
COMMENT ON TABLE user_profiles IS 'Stores user profile information including role (admin/user)';
COMMENT ON TABLE user_permissions IS 'Stores granular permissions for each user';
COMMENT ON COLUMN user_profiles.role IS 'User role: admin or user';
COMMENT ON COLUMN user_permissions.permission_key IS 'Permission identifier (e.g., manage_users, view_reports, edit_data, delete_data)';
COMMENT ON COLUMN user_permissions.allowed IS 'Whether the permission is allowed for this user';

-- Function to create a new user (to be called via RPC or Edge Function)
-- Note: This is a placeholder. In production, use Supabase Admin API or Edge Function
CREATE OR REPLACE FUNCTION create_user_with_profile(
    p_email TEXT,
    p_password TEXT,
    p_role TEXT DEFAULT 'user',
    p_name TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- This function should be called via Supabase Admin API or Edge Function
    -- For security, password hashing and user creation should happen server-side
    -- This is a placeholder that shows the expected structure
    
    -- In production, use Supabase Admin API:
    -- 1. Create user in auth.users via Admin API
    -- 2. Insert profile in user_profiles
    -- 3. Set default permissions
    
    -- For now, return a placeholder UUID
    -- The actual implementation should use Supabase Admin API client-side
    -- or an Edge Function that uses service_role key
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

