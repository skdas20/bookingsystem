import { 
  format, 
  parseISO, 
  addDays, 
  addHours, 
  isBefore, 
  isAfter,
  startOfDay,
  endOfDay,
  getDay,
  addMinutes,
  isWithinInterval
} from 'date-fns';
import { 
  zonedTimeToUtc, 
  utcToZonedTime, 
  formatInTimeZone
} from 'date-fns-tz';
import { v4 as uuidv4 } from 'uuid';
import { AvailabilityRule, TimeSlot } from '../models/schemas';

export class TimeUtils {
  /**
   * Convert a time string (HH:MM or HH:MM:SS) and date to UTC considering timezone
   */
  static timeStringToUTC(timeString: string, date: Date, timezone: string): Date {
    const timeParts = timeString.split(':');
    if (timeParts.length < 2 || timeParts.length > 3) {
      throw new Error(`Invalid time format: ${timeString}. Expected HH:MM or HH:MM:SS`);
    }
    const hours = parseInt(timeParts[0]!, 10);
    const minutes = parseInt(timeParts[1]!, 10);
    const localDate = new Date(date);
    localDate.setHours(hours, minutes, 0, 0);
    
    return zonedTimeToUtc(localDate, timezone);
  }

  /**
   * Convert UTC date to timezone-aware date
   */
  static utcToTimezone(utcDate: Date, timezone: string): Date {
    return utcToZonedTime(utcDate, timezone);
  }

  /**
   * Check if current time meets lead time requirement (≥ 2 hours)
   */
  static meetsLeadTime(slotStart: Date): boolean {
    const now = new Date();
    const leadTimeHours = 2;
    const minimumTime = addHours(now, leadTimeHours);
    
    return isAfter(slotStart, minimumTime);
  }

  /**
   * Check if date is within booking horizon (≤ 14 days)
   */
  static withinBookingHorizon(slotStart: Date): boolean {
    const now = new Date();
    const horizonDays = 14;
    const maxDate = addDays(now, horizonDays);
    
    return isBefore(slotStart, maxDate);
  }

  /**
   * Check if cancellation meets minimum notice (≥ 12 hours)
   */
  static meetsCancellationNotice(slotStart: Date): boolean {
    const now = new Date();
    const noticeHours = 12;
    const minimumTime = addHours(now, noticeHours);
    
    return isAfter(slotStart, minimumTime);
  }

  /**
   * Generate available time slots for a given date based on availability rules
   */
  static generateSlotsForDate(
    date: Date,
    availabilityRules: AvailabilityRule[],
    bookedSlots: { slot_start: Date; slot_end: Date }[],
    hostTimezone: string
  ): TimeSlot[] {
    const slots: TimeSlot[] = [];
    const dayOfWeek = getDay(date);

    // Find availability rules for this day of week
    const rulesForDay = availabilityRules.filter(rule => rule.day_of_week === dayOfWeek);

    for (const rule of rulesForDay) {
      // Convert rule times to UTC for the specific date
      const slotStart = this.timeStringToUTC(rule.start_time, date, rule.timezone);
      const slotEnd = this.timeStringToUTC(rule.end_time, date, rule.timezone);

      // Generate slots within this time range
      let currentSlot = slotStart;
      
      while (isBefore(currentSlot, slotEnd)) {
        const slotEndTime = addMinutes(currentSlot, rule.interval_minutes);
        
        // Don't create slot if it would exceed the rule's end time
        if (isAfter(slotEndTime, slotEnd)) {
          break;
        }

        // Check if slot meets lead time and horizon requirements
        const meetsLeadTime = this.meetsLeadTime(currentSlot);
        const withinHorizon = this.withinBookingHorizon(currentSlot);

        // Check if slot conflicts with existing bookings
        const isBooked = bookedSlots.some(booking => 
          this.slotsOverlap(
            { start: currentSlot, end: slotEndTime },
            { start: booking.slot_start, end: booking.slot_end }
          )
        );

        const isAvailable = meetsLeadTime && withinHorizon && !isBooked;

        slots.push({
          start: currentSlot,
          end: slotEndTime,
          available: isAvailable
        });

        currentSlot = slotEndTime;
      }
    }

    return slots.sort((a, b) => a.start.getTime() - b.start.getTime());
  }

  /**
   * Check if two time slots overlap
   */
  static slotsOverlap(
    slot1: { start: Date; end: Date },
    slot2: { start: Date; end: Date }
  ): boolean {
    return (
      isBefore(slot1.start, slot2.end) && 
      isAfter(slot1.end, slot2.start)
    );
  }

  /**
   * Validate date range for slot queries
   */
  static validateDateRange(fromDate: string, toDate: string): { from: Date; to: Date } {
    const from = parseISO(fromDate);
    const to = parseISO(toDate);

    if (isAfter(from, to)) {
      throw new Error('From date must be before to date');
    }

    const daysDiff = Math.ceil((to.getTime() - from.getTime()) / (1000 * 60 * 60 * 24));
    if (daysDiff > 14) {
      throw new Error('Date range cannot exceed 14 days');
    }

    return { from: startOfDay(from), to: endOfDay(to) };
  }

  /**
   * Format date for display in specific timezone
   */
  static formatInTimezone(date: Date, timezone: string, formatString: string = 'yyyy-MM-dd HH:mm:ss zzz'): string {
    return formatInTimeZone(date, timezone, formatString);
  }

  /**
   * Generate date range array
   */
  static generateDateRange(from: Date, to: Date): Date[] {
    const dates: Date[] = [];
    let currentDate = startOfDay(from);
    const endDate = startOfDay(to);

    while (!isAfter(currentDate, endDate)) {
      dates.push(new Date(currentDate));
      currentDate = addDays(currentDate, 1);
    }

    return dates;
  }
}

export class BookingUtils {
  /**
   * Generate unique booking ID
   */
  static generateBookingId(): string {
    return uuidv4();
  }

  /**
   * Generate cancel code (6-digit alphanumeric)
   */
  static generateCancelCode(): string {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let result = '';
    for (let i = 0; i < 6; i++) {
      result += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return result;
  }

  /**
   * Validate slot booking constraints
   */
  static validateBookingSlot(slotStart: Date, slotEnd: Date): void {
    // Check lead time
    if (!TimeUtils.meetsLeadTime(slotStart)) {
      throw new Error('Booking must be at least 2 hours in advance');
    }

    // Check horizon
    if (!TimeUtils.withinBookingHorizon(slotStart)) {
      throw new Error('Booking cannot be more than 14 days in advance');
    }

    // Check slot duration is reasonable (between 15 minutes and 8 hours)
    const durationMs = slotEnd.getTime() - slotStart.getTime();
    const durationMinutes = durationMs / (1000 * 60);
    
    if (durationMinutes < 15) {
      throw new Error('Slot duration must be at least 15 minutes');
    }
    
    if (durationMinutes > 480) {
      throw new Error('Slot duration cannot exceed 8 hours');
    }

    // Check that end is after start
    if (!isAfter(slotEnd, slotStart)) {
      throw new Error('Slot end time must be after start time');
    }
  }
}
