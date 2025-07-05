import { Router, Response } from 'express';
import { db } from '../utils/database';
import { authenticateToken, AuthenticatedRequest } from '../middleware/auth';
import { slotsQuerySchema, SlotsQuery } from '../models/schemas';
import { TimeUtils } from '../utils/timeUtils';
import { parseISO } from 'date-fns';

const router = Router();

// GET /slots?from=YYYY-MM-DD&to=YYYY-MM-DD - Get available slots (Protected route)
router.get('/slots', authenticateToken, async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const query = req.query as any;
    
    // Validate query parameters
    const validatedQuery: SlotsQuery = slotsQuerySchema.parse({
      from: query.from,
      to: query.to
    });

    const { from, to } = validatedQuery;

    // Validate and parse date range
    const dateRange = TimeUtils.validateDateRange(from, to);

    // Get user's availability rules
    const availabilityResult = await db.query(
      `SELECT id, day_of_week, start_time, end_time, interval_minutes, timezone 
       FROM availability_rules 
       WHERE user_id = $1 
       ORDER BY day_of_week, start_time`,
      [req.user!.id]
    );

    if (availabilityResult.rows.length === 0) {
      res.status(200).json({
        message: 'No availability rules found',
        slots: [],
        dateRange: {
          from: dateRange.from,
          to: dateRange.to
        }
      });
      return;
    }

    // Get existing bookings in the date range
    const bookingsResult = await db.query(
      `SELECT slot_start, slot_end 
       FROM bookings 
       WHERE user_id = $1 
         AND status = 'confirmed'
         AND slot_start >= $2 
         AND slot_end <= $3`,
      [req.user!.id, dateRange.from, dateRange.to]
    );

    const bookedSlots = bookingsResult.rows.map((row: any) => ({
      slot_start: row.slot_start,
      slot_end: row.slot_end
    }));

    // Get the user's primary timezone from their first availability rule
    const hostTimezone = availabilityResult.rows[0].timezone;

    // Generate all dates in the range
    const dates = TimeUtils.generateDateRange(dateRange.from, dateRange.to);
    
    let allSlots: any[] = [];

    // Generate slots for each date
    for (const date of dates) {
      const slotsForDate = TimeUtils.generateSlotsForDate(
        date,
        availabilityResult.rows,
        bookedSlots,
        hostTimezone
      );

      // Filter to only available slots
      const availableSlots = slotsForDate.filter(slot => slot.available);
      
      allSlots = allSlots.concat(
        availableSlots.map(slot => ({
          start: slot.start.toISOString(),
          end: slot.end.toISOString(),
          startLocal: TimeUtils.formatInTimezone(slot.start, hostTimezone, 'yyyy-MM-dd HH:mm:ss'),
          endLocal: TimeUtils.formatInTimezone(slot.end, hostTimezone, 'yyyy-MM-dd HH:mm:ss'),
          timezone: hostTimezone,
          duration: Math.round((slot.end.getTime() - slot.start.getTime()) / (1000 * 60)) // duration in minutes
        }))
      );
    }

    // Sort slots by start time
    allSlots.sort((a, b) => new Date(a.start).getTime() - new Date(b.start).getTime());

    res.status(200).json({
      slots: allSlots,
      count: allSlots.length,
      dateRange: {
        from: dateRange.from.toISOString(),
        to: dateRange.to.toISOString()
      },
      hostTimezone
    });

  } catch (error: any) {
    if (error.name === 'ZodError') {
      res.status(400).json({
        error: 'Validation error',
        details: error.errors
      });
      return;
    }

    if (error.message.includes('Date range') || error.message.includes('date')) {
      res.status(400).json({ error: error.message });
      return;
    }

    console.error('Get slots error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
