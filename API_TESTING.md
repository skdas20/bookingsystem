# API Testing Examples

This file contains sample requests for testing the Appointment Booking System API.

## Prerequisites

1. Make sure the server is running:
   ```bash
   npm run dev
   # or
   docker-compose up
   ```

2. Set your base URL:
   ```bash
   export BASE_URL="http://localhost:3000"
   ```

## Authentication

### Register a new user
```bash
curl -X POST ${BASE_URL}/api/signup \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "password": "password123"
  }'
```

### Login
```bash
curl -X POST ${BASE_URL}/api/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "password123"
  }'
```

**Save the token from login response for use in subsequent requests.**

### Set TOKEN variable
```bash
export TOKEN="your-jwt-token-here"
```

## Availability Management

### Set availability for Monday (9 AM - 5 PM, 30-minute slots)
```bash
curl -X POST ${BASE_URL}/api/availability \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "dayOfWeek": 1,
    "startTime": "09:00",
    "endTime": "17:00",
    "intervalMin": 30,
    "timeZone": "America/New_York"
  }'
```

### Set availability for Tuesday (10 AM - 6 PM, 60-minute slots)
```bash
curl -X POST ${BASE_URL}/api/availability \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "dayOfWeek": 2,
    "startTime": "10:00",
    "endTime": "18:00",
    "intervalMin": 60,
    "timeZone": "America/New_York"
  }'
```

### Set availability for Friday (9 AM - 12 PM, 45-minute slots)
```bash
curl -X POST ${BASE_URL}/api/availability \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "dayOfWeek": 5,
    "startTime": "09:00",
    "endTime": "12:00",
    "intervalMin": 45,
    "timeZone": "America/New_York"
  }'
```

### Get all availability rules
```bash
curl -X GET ${BASE_URL}/api/availability \
  -H "Authorization: Bearer ${TOKEN}"
```

## Available Slots

### Get available slots for next week
```bash
# Adjust dates to future dates (must be within 14 days and at least 2 hours ahead)
curl -X GET "${BASE_URL}/api/slots?from=2024-07-08&to=2024-07-14" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Get available slots for a specific date range
```bash
curl -X GET "${BASE_URL}/api/slots?from=2024-07-10&to=2024-07-12" \
  -H "Authorization: Bearer ${TOKEN}"
```

## Booking Management

### Create a booking
```bash
# Use a slot time from the available slots response (must be future time)
curl -X POST ${BASE_URL}/api/book \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Jane Smith",
    "email": "jane@example.com",
    "slotStart": "2024-07-08T14:00:00.000Z",
    "slotEnd": "2024-07-08T14:30:00.000Z"
  }'
```

**Save the bookingId and cancelCode from the response.**

### Cancel a booking
```bash
curl -X POST ${BASE_URL}/api/cancel \
  -H "Content-Type: application/json" \
  -d '{
    "bookingId": "your-booking-id-here",
    "cancelCode": "ABC123"
  }'
```

### Get all bookings for a user
```bash
curl -X GET ${BASE_URL}/api/bookings \
  -H "Authorization: Bearer ${TOKEN}"
```

## Health Check

### Check server status
```bash
curl -X GET ${BASE_URL}/health
```

## Error Testing

### Test validation errors
```bash
# Invalid email format
curl -X POST ${BASE_URL}/api/signup \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "invalid-email",
    "password": "password123"
  }'

# Missing required fields
curl -X POST ${BASE_URL}/api/availability \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "dayOfWeek": 1,
    "startTime": "09:00"
  }'

# Invalid time range
curl -X POST ${BASE_URL}/api/availability \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "dayOfWeek": 1,
    "startTime": "17:00",
    "endTime": "09:00",
    "intervalMin": 30,
    "timeZone": "America/New_York"
  }'
```

### Test authentication errors
```bash
# Request without token
curl -X GET ${BASE_URL}/api/availability

# Request with invalid token
curl -X GET ${BASE_URL}/api/availability \
  -H "Authorization: Bearer invalid-token"
```

## Database Commands (for development)

### Run migrations
```bash
npm run migrate
```

### Connect to PostgreSQL (if running locally)
```bash
psql -h localhost -p 5432 -U postgres -d appointment_booking
```

### View database tables
```sql
\dt
```

### Check users
```sql
SELECT id, name, email, created_at FROM users;
```

### Check availability rules
```sql
SELECT * FROM availability_rules;
```

### Check bookings
```sql
SELECT * FROM bookings;
```
