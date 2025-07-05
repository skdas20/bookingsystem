import { Router, Response } from 'express';
import { db } from '../utils/database';
import { authenticateToken, AuthenticatedRequest } from '../middleware/auth';
import { availabilitySchema, AvailabilityData } from '../models/schemas';

const router = Router();

// POST /availability - Add availability rules (Protected route)
router.post('/availability', authenticateToken, async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    // Validate request body
    const validatedData: AvailabilityData = availabilitySchema.parse(req.body);
    const { dayOfWeek, startTime, endTime, intervalMin, timeZone } = validatedData;

    // Validate that end time is after start time
    const start = new Date(`2000-01-01T${startTime}:00`);
    const end = new Date(`2000-01-01T${endTime}:00`);
    
    if (end <= start) {
      res.status(400).json({ error: 'End time must be after start time' });
      return;
    }

    // Check if user already has availability for this day
    const existingRule = await db.query(
      'SELECT id FROM availability_rules WHERE user_id = $1 AND day_of_week = $2',
      [req.user!.id, dayOfWeek]
    );

    if (existingRule.rows.length > 0) {
      res.status(409).json({ 
        error: 'Availability rule already exists for this day. Delete the existing rule first.' 
      });
      return;
    }

    // Create availability rule
    const result = await db.query(
      `INSERT INTO availability_rules 
       (user_id, day_of_week, start_time, end_time, interval_minutes, timezone) 
       VALUES ($1, $2, $3, $4, $5, $6) 
       RETURNING id, day_of_week, start_time, end_time, interval_minutes, timezone, created_at`,
      [req.user!.id, dayOfWeek, startTime, endTime, intervalMin, timeZone]
    );

    const rule = result.rows[0];

    res.status(201).json({
      message: 'Availability rule created successfully',
      availability: {
        id: rule.id,
        dayOfWeek: rule.day_of_week,
        startTime: rule.start_time,
        endTime: rule.end_time,
        intervalMinutes: rule.interval_minutes,
        timeZone: rule.timezone,
        createdAt: rule.created_at
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

    console.error('Create availability error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// GET /availability - List saved availability rules (Protected route)
router.get('/availability', authenticateToken, async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const result = await db.query(
      `SELECT id, day_of_week, start_time, end_time, interval_minutes, timezone, created_at 
       FROM availability_rules 
       WHERE user_id = $1 
       ORDER BY day_of_week, start_time`,
      [req.user!.id]
    );

    const availability = result.rows.map((row: any) => ({
      id: row.id,
      dayOfWeek: row.day_of_week,
      startTime: row.start_time,
      endTime: row.end_time,
      intervalMinutes: row.interval_minutes,
      timeZone: row.timezone,
      createdAt: row.created_at
    }));

    res.status(200).json({
      availability,
      count: availability.length
    });
  } catch (error) {
    console.error('Get availability error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// DELETE /availability/:id - Delete availability rule (Protected route)
router.delete('/availability/:id', authenticateToken, async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const ruleId = parseInt(req.params?.id || '0');
    
    if (isNaN(ruleId)) {
      res.status(400).json({ error: 'Invalid availability rule ID' });
      return;
    }

    // Check if rule exists and belongs to user
    const existingRule = await db.query(
      'SELECT id FROM availability_rules WHERE id = $1 AND user_id = $2',
      [ruleId, req.user!.id]
    );

    if (existingRule.rows.length === 0) {
      res.status(404).json({ error: 'Availability rule not found' });
      return;
    }

    // Delete the rule
    await db.query(
      'DELETE FROM availability_rules WHERE id = $1 AND user_id = $2',
      [ruleId, req.user!.id]
    );

    res.status(200).json({
      message: 'Availability rule deleted successfully'
    });
  } catch (error) {
    console.error('Delete availability error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
