import { Router, Response } from 'express';
import { db } from '../utils/database';
import { authenticateToken, AuthenticatedRequest } from '../middleware/auth';
import { bookingSchema, cancelBookingSchema, BookingData, CancelBookingData } from '../models/schemas';
import { TimeUtils, BookingUtils } from '../utils/timeUtils';
import { parseISO } from 'date-fns';

const router = Router();

// POST /book - Create a new booking (Protected route)
router.post('/book', authenticateToken, async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    // Validate request body
    const validatedData: BookingData = bookingSchema.parse((req as any).body);
    const { name, email, slotStart, slotEnd } = validatedData;

    // Parse slot times
    const slotStartDate = parseISO(slotStart);
    const slotEndDate = parseISO(slotEnd);

    // Validate booking constraints
    BookingUtils.validateBookingSlot(slotStartDate, slotEndDate);

    // Check if slot is already booked
    const existingBooking = await db.query(
      `SELECT id FROM bookings 
       WHERE user_id = $1 
         AND status = 'confirmed'
         AND (
           (slot_start <= $2 AND slot_end > $2) OR
           (slot_start < $3 AND slot_end >= $3) OR
           (slot_start >= $2 AND slot_end <= $3)
         )`,
      [req.user!.id, slotStartDate, slotEndDate]
    );

    if (existingBooking.rows.length > 0) {
      res.status(409).json({ 
        error: 'This time slot is already booked' 
      });
      return;
    }

    // Generate booking ID and cancel code
    const bookingId = BookingUtils.generateBookingId();
    const cancelCode = BookingUtils.generateCancelCode();

    // Create booking
    const result = await db.query(
      `INSERT INTO bookings 
       (user_id, booking_id, cancel_code, name, email, slot_start, slot_end, status) 
       VALUES ($1, $2, $3, $4, $5, $6, $7, 'confirmed') 
       RETURNING id, booking_id, cancel_code, name, email, slot_start, slot_end, status, created_at`,
      [req.user!.id, bookingId, cancelCode, name, email, slotStartDate, slotEndDate]
    );

    const booking = result.rows[0];

    res.status(201).json({
      message: 'Booking created successfully',
      booking: {
        id: booking.id,
        bookingId: booking.booking_id,
        cancelCode: booking.cancel_code,
        name: booking.name,
        email: booking.email,
        slotStart: booking.slot_start,
        slotEnd: booking.slot_end,
        status: booking.status,
        createdAt: booking.created_at
      }
    });

  } catch (error: any) {
    if (error.name === 'ZodError') {
      res.status(400).json({
        error: 'Validation error',
        details: error.errors
      });
      return;
    }

    if (error.message.includes('Booking must be') || 
        error.message.includes('Slot duration') || 
        error.message.includes('time must be')) {
      res.status(400).json({ error: error.message });
      return;
    }

    console.error('Create booking error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// POST /cancel - Cancel a booking
router.post('/cancel', async (req: any, res: Response): Promise<void> => {
  try {
    // Validate request body
    const validatedData: CancelBookingData = cancelBookingSchema.parse(req.body);
    const { bookingId, cancelCode } = validatedData;

    // Find booking
    const bookingResult = await db.query(
      `SELECT id, booking_id, cancel_code, slot_start, slot_end, status 
       FROM bookings 
       WHERE booking_id = $1`,
      [bookingId]
    );

    if (bookingResult.rows.length === 0) {
      res.status(404).json({ error: 'Booking not found' });
      return;
    }

    const booking = bookingResult.rows[0];

    // Check if booking is already cancelled
    if (booking.status === 'cancelled') {
      res.status(400).json({ error: 'Booking is already cancelled' });
      return;
    }

    // Verify cancel code
    if (booking.cancel_code !== cancelCode) {
      res.status(401).json({ error: 'Invalid cancel code' });
      return;
    }

    // Check cancellation notice requirement (≥ 12 hours before slot)
    if (!TimeUtils.meetsCancellationNotice(booking.slot_start)) {
      res.status(400).json({ 
        error: 'Cancellation must be at least 12 hours before the appointment time' 
      });
      return;
    }

    // Cancel the booking
    await db.query(
      `UPDATE bookings 
       SET status = 'cancelled' 
       WHERE id = $1`,
      [booking.id]
    );

    res.status(200).json({
      message: 'Booking cancelled successfully',
      bookingId: booking.booking_id,
      cancelledAt: new Date().toISOString()
    });

  } catch (error: any) {
    if (error.name === 'ZodError') {
      res.status(400).json({
        error: 'Validation error',
        details: error.errors
      });
      return;
    }

    console.error('Cancel booking error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// GET /bookings - List user's bookings (Protected route)
router.get('/bookings', authenticateToken, async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const result = await db.query(
      `SELECT id, booking_id, name, email, slot_start, slot_end, status, created_at 
       FROM bookings 
       WHERE user_id = $1 
       ORDER BY slot_start DESC`,
      [req.user!.id]
    );

    const bookings = result.rows.map((row: any) => ({
      id: row.id,
      bookingId: row.booking_id,
      name: row.name,
      email: row.email,
      slotStart: row.slot_start,
      slotEnd: row.slot_end,
      status: row.status,
      createdAt: row.created_at
    }));

    res.status(200).json({
      bookings,
      count: bookings.length
    });

  } catch (error) {
    console.error('Get bookings error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
