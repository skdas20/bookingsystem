-- Initial database setup for Appointment Booking System
-- Run this file to create all necessary tables

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create availability_rules table
CREATE TABLE IF NOT EXISTS availability_rules (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    day_of_week INTEGER NOT NULL CHECK (day_of_week >= 0 AND day_of_week <= 6),
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    interval_minutes INTEGER NOT NULL CHECK (interval_minutes >= 15 AND interval_minutes <= 480),
    timezone VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, day_of_week),
    CHECK (end_time > start_time)
);

-- Create bookings table
CREATE TABLE IF NOT EXISTS bookings (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    booking_id UUID NOT NULL UNIQUE,
    cancel_code VARCHAR(6) NOT NULL,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    slot_start TIMESTAMP WITH TIME ZONE NOT NULL,
    slot_end TIMESTAMP WITH TIME ZONE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'confirmed' CHECK (status IN ('confirmed', 'cancelled')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CHECK (slot_end > slot_start)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_availability_rules_user_id ON availability_rules(user_id);
CREATE INDEX IF NOT EXISTS idx_availability_rules_day_of_week ON availability_rules(day_of_week);
CREATE INDEX IF NOT EXISTS idx_bookings_user_id ON bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_bookings_booking_id ON bookings(booking_id);
CREATE INDEX IF NOT EXISTS idx_bookings_slot_times ON bookings(slot_start, slot_end);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON bookings(status);

-- Create constraint to prevent overlapping bookings for the same user
CREATE UNIQUE INDEX IF NOT EXISTS idx_bookings_no_overlap 
ON bookings (user_id, slot_start, slot_end) 
WHERE status = 'confirmed';

-- Add comment for documentation
COMMENT ON TABLE users IS 'Stores user account information';
COMMENT ON TABLE availability_rules IS 'Stores weekly availability patterns for each user';
COMMENT ON TABLE bookings IS 'Stores all appointment bookings';

COMMENT ON COLUMN availability_rules.day_of_week IS '0=Sunday, 1=Monday, 2=Tuesday, 3=Wednesday, 4=Thursday, 5=Friday, 6=Saturday';
COMMENT ON COLUMN availability_rules.interval_minutes IS 'Duration of each appointment slot in minutes (15-480)';
COMMENT ON COLUMN bookings.booking_id IS 'Public UUID for booking identification';
COMMENT ON COLUMN bookings.cancel_code IS '6-character code required for booking cancellation';
