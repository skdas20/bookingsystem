import { z } from 'zod';

// User schemas
export const signupSchema = z.object({
  name: z.string().min(2).max(100),
  email: z.string().email(),
  password: z.string().min(8).max(100)
});

export const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1)
});

// Availability schemas
export const availabilitySchema = z.object({
  dayOfWeek: z.number().int().min(0).max(6), // 0 = Sunday, 6 = Saturday
  startTime: z.string().regex(/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/, 'Invalid time format (HH:MM)'),
  endTime: z.string().regex(/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/, 'Invalid time format (HH:MM)'),
  intervalMin: z.number().int().min(15).max(480), // 15 minutes to 8 hours
  timeZone: z.string().min(1) // e.g., 'America/New_York'
});

// Slots query schema
export const slotsQuerySchema = z.object({
  from: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Invalid date format (YYYY-MM-DD)'),
  to: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Invalid date format (YYYY-MM-DD)')
});

// Booking schemas
export const bookingSchema = z.object({
  name: z.string().min(2).max(100),
  email: z.string().email(),
  slotStart: z.string().datetime(), // ISO 8601 format
  slotEnd: z.string().datetime()   // ISO 8601 format
});

export const cancelBookingSchema = z.object({
  bookingId: z.string().uuid(),
  cancelCode: z.string().min(6)
});

// Type exports
export type SignupData = z.infer<typeof signupSchema>;
export type LoginData = z.infer<typeof loginSchema>;
export type AvailabilityData = z.infer<typeof availabilitySchema>;
export type SlotsQuery = z.infer<typeof slotsQuerySchema>;
export type BookingData = z.infer<typeof bookingSchema>;
export type CancelBookingData = z.infer<typeof cancelBookingSchema>;

// Database model interfaces
export interface User {
  id: number;
  name: string;
  email: string;
  password_hash: string;
  created_at: Date;
}

export interface AvailabilityRule {
  id: number;
  user_id: number;
  day_of_week: number;
  start_time: string;
  end_time: string;
  interval_minutes: number;
  timezone: string;
  created_at: Date;
}

export interface Booking {
  id: number;
  user_id: number;
  booking_id: string;
  cancel_code: string;
  name: string;
  email: string;
  slot_start: Date;
  slot_end: Date;
  status: 'confirmed' | 'cancelled';
  created_at: Date;
}

export interface TimeSlot {
  start: Date;
  end: Date;
  available: boolean;
}
