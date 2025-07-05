# Appointment Booking System Backend

A complete, production-ready appointment booking system backend built with Express.js, TypeScript, PostgreSQL, and Docker.

## 🚀 Features

- **JWT Authentication** - Secure user registration and login
- **Time-Zone Aware Scheduling** - Full timezone support with date-fns-tz
- **Availability Management** - Set weekly availability patterns
- **Smart Slot Generation** - Automatic available slot calculation
- **Booking Management** - Create and cancel appointments with proper validation
- **Business Logic Enforcement** - Lead time, booking horizon, and cancellation policies
- **Docker Containerization** - Complete Docker setup with PostgreSQL
- **TypeScript** - Type-safe development with comprehensive validation
- **Professional Error Handling** - Proper HTTP status codes and error messages

## 🛠 Tech Stack

- **Backend**: Express.js with TypeScript
- **Database**: PostgreSQL with migrations
- **Authentication**: JWT with bcrypt password hashing
- **Validation**: Zod schemas for request validation
- **Time Management**: date-fns with timezone support
- **Containerization**: Docker & docker-compose
- **Security**: Helmet, CORS, input sanitization

## 📋 Requirements

- Node.js 18+
- PostgreSQL 15+
- Docker & Docker Compose (for containerized setup)

## 🔧 Installation & Setup

### Option 1: Docker Setup (Recommended)

1. **Clone and setup**:
   ```bash
   git clone <repository-url>
   cd appointment-booking-backend
   cp .env.example .env
   ```

2. **Configure environment** (edit `.env`):
   ```env
   NODE_ENV=production
   JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
   POSTGRES_DB=appointment_booking
   POSTGRES_USER=postgres
   POSTGRES_PASSWORD=postgres
   ```

3. **Start with Docker**:
   ```bash
   docker-compose up -d
   ```

4. **Check status**:
   ```bash
   docker-compose logs -f
   curl http://localhost:3000/health
   ```

### Option 2: Local Development Setup

1. **Install dependencies**:
   ```bash
   npm install
   ```

2. **Setup PostgreSQL database**:
   ```bash
   # Create database
   createdb appointment_booking
   
   # Run migrations
   npm run migrate
   ```

3. **Start development server**:
   ```bash
   npm run dev
   ```

## 📊 Database Schema

### Users Table
```sql
users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
)
```

### Availability Rules Table
```sql
availability_rules (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    day_of_week INTEGER CHECK (day_of_week >= 0 AND day_of_week <= 6),
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    interval_minutes INTEGER CHECK (interval_minutes >= 15 AND interval_minutes <= 480),
    timezone VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
)
```

### Bookings Table
```sql
bookings (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    booking_id UUID NOT NULL UNIQUE,
    cancel_code VARCHAR(6) NOT NULL,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    slot_start TIMESTAMP WITH TIME ZONE NOT NULL,
    slot_end TIMESTAMP WITH TIME ZONE NOT NULL,
    status VARCHAR(20) DEFAULT 'confirmed',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
)
```

## 🔗 API Endpoints

### Authentication

#### Register User
```http
POST /api/signup
Content-Type: application/json

{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "securepassword123"
}
```

**Response:**
```json
{
  "message": "User created successfully",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "createdAt": "2024-01-01T10:00:00.000Z"
  }
}
```

#### Login User
```http
POST /api/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "securepassword123"
}
```

**Response:**
```json
{
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com"
  }
}
```

### Availability Management

#### Set Availability
```http
POST /api/availability
Authorization: Bearer <jwt-token>
Content-Type: application/json

{
  "dayOfWeek": 1,
  "startTime": "09:00",
  "endTime": "17:00",
  "intervalMin": 30,
  "timeZone": "America/New_York"
}
```

**Response:**
```json
{
  "message": "Availability rule created successfully",
  "availability": {
    "id": 1,
    "dayOfWeek": 1,
    "startTime": "09:00",
    "endTime": "17:00",
    "intervalMinutes": 30,
    "timeZone": "America/New_York",
    "createdAt": "2024-01-01T10:00:00.000Z"
  }
}
```

#### Get Availability
```http
GET /api/availability
Authorization: Bearer <jwt-token>
```

**Response:**
```json
{
  "availability": [
    {
      "id": 1,
      "dayOfWeek": 1,
      "startTime": "09:00",
      "endTime": "17:00",
      "intervalMinutes": 30,
      "timeZone": "America/New_York",
      "createdAt": "2024-01-01T10:00:00.000Z"
    }
  ],
  "count": 1
}
```

### Available Slots

#### Get Available Slots
```http
GET /api/slots?from=2024-01-15&to=2024-01-20
Authorization: Bearer <jwt-token>
```

**Response:**
```json
{
  "slots": [
    {
      "start": "2024-01-15T14:00:00.000Z",
      "end": "2024-01-15T14:30:00.000Z",
      "startLocal": "2024-01-15 09:00:00",
      "endLocal": "2024-01-15 09:30:00",
      "timezone": "America/New_York",
      "duration": 30
    }
  ],
  "count": 48,
  "dateRange": {
    "from": "2024-01-15T00:00:00.000Z",
    "to": "2024-01-20T23:59:59.999Z"
  },
  "hostTimezone": "America/New_York"
}
```

### Booking Management

#### Create Booking
```http
POST /api/book
Authorization: Bearer <jwt-token>
Content-Type: application/json

{
  "name": "Jane Smith",
  "email": "jane@example.com",
  "slotStart": "2024-01-15T14:00:00.000Z",
  "slotEnd": "2024-01-15T14:30:00.000Z"
}
```

**Response:**
```json
{
  "message": "Booking created successfully",
  "booking": {
    "id": 1,
    "bookingId": "123e4567-e89b-12d3-a456-426614174000",
    "cancelCode": "ABC123",
    "name": "Jane Smith",
    "email": "jane@example.com",
    "slotStart": "2024-01-15T14:00:00.000Z",
    "slotEnd": "2024-01-15T14:30:00.000Z",
    "status": "confirmed",
    "createdAt": "2024-01-01T10:00:00.000Z"
  }
}
```

#### Cancel Booking
```http
POST /api/cancel
Content-Type: application/json

{
  "bookingId": "123e4567-e89b-12d3-a456-426614174000",
  "cancelCode": "ABC123"
}
```

**Response:**
```json
{
  "message": "Booking cancelled successfully",
  "bookingId": "123e4567-e89b-12d3-a456-426614174000",
  "cancelledAt": "2024-01-01T10:00:00.000Z"
}
```

#### Get User Bookings
```http
GET /api/bookings
Authorization: Bearer <jwt-token>
```

**Response:**
```json
{
  "bookings": [
    {
      "id": 1,
      "bookingId": "123e4567-e89b-12d3-a456-426614174000",
      "name": "Jane Smith",
      "email": "jane@example.com",
      "slotStart": "2024-01-15T14:00:00.000Z",
      "slotEnd": "2024-01-15T14:30:00.000Z",
      "status": "confirmed",
      "createdAt": "2024-01-01T10:00:00.000Z"
    }
  ],
  "count": 1
}
```

## 🔒 Business Rules

### Booking Constraints
- **Lead Time**: Bookings must be at least 2 hours in advance
- **Booking Horizon**: Bookings cannot be more than 14 days in advance
- **Slot Duration**: Between 15 minutes and 8 hours
- **No Double Booking**: Prevents overlapping appointments

### Cancellation Policy
- **Cancellation Notice**: Must be at least 12 hours before appointment
- **Cancel Code Required**: 6-character code provided at booking

### Availability Rules
- **Weekly Patterns**: Set availability for each day of the week (0=Sunday, 6=Saturday)
- **Time Slots**: Define start/end times and interval duration
- **Timezone Support**: Full timezone awareness with daylight saving transitions

## 📝 Scripts

```bash
# Development
npm run dev          # Start development server with hot reload
npm run build        # Build TypeScript to JavaScript
npm run start        # Start production server

# Database
npm run migrate      # Run database migrations

# Docker
npm run docker:build # Build Docker images
npm run docker:up    # Start containers
npm run docker:down  # Stop containers
npm run docker:logs  # View container logs
```

## 🧪 Testing with curl

```bash
# Health check
curl http://localhost:3000/health

# Register user
curl -X POST http://localhost:3000/api/signup \
  -H "Content-Type: application/json" \
  -d '{"name":"John Doe","email":"john@example.com","password":"password123"}'

# Login user
curl -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"john@example.com","password":"password123"}'

# Set availability (replace TOKEN)
curl -X POST http://localhost:3000/api/availability \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"dayOfWeek":1,"startTime":"09:00","endTime":"17:00","intervalMin":30,"timeZone":"America/New_York"}'

# Get available slots
curl "http://localhost:3000/api/slots?from=2024-01-15&to=2024-01-20" \
  -H "Authorization: Bearer TOKEN"
```

## 🐳 Docker Configuration

The application includes a complete Docker setup:

- **Multi-stage Dockerfile** for optimized production builds
- **docker-compose.yml** with PostgreSQL and application services
- **Health checks** for both services
- **Volume persistence** for database data
- **Environment variable** configuration

## 🔧 Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `NODE_ENV` | Environment mode | `development` |
| `PORT` | Application port | `3000` |
| `DB_HOST` | Database host | `localhost` |
| `DB_PORT` | Database port | `5432` |
| `DB_NAME` | Database name | `appointment_booking` |
| `DB_USER` | Database user | `postgres` |
| `DB_PASSWORD` | Database password | `postgres` |
| `JWT_SECRET` | JWT signing secret | Required |
| `JWT_EXPIRES_IN` | JWT expiration time | `24h` |

## 🚨 Error Handling

The API returns appropriate HTTP status codes:

- `200` - Success
- `201` - Created
- `400` - Bad Request (validation errors)
- `401` - Unauthorized (invalid/missing token)
- `404` - Not Found
- `409` - Conflict (duplicate resource)
- `500` - Internal Server Error

## 📈 Performance Features

- **Database Indexing** - Optimized queries with proper indexes
- **Connection Pooling** - PostgreSQL connection pool management
- **Request Logging** - Comprehensive request/response logging
- **Error Tracking** - Detailed error logging with context

## 🔐 Security Features

- **Password Hashing** - bcrypt with salt rounds
- **JWT Authentication** - Secure token-based auth
- **Input Validation** - Zod schema validation
- **SQL Injection Prevention** - Parameterized queries
- **CORS Configuration** - Proper cross-origin setup
- **Helmet Security** - Security headers middleware

## 🏗 Project Structure

```
appointment-booking-backend/
├── src/
│   ├── controllers/         # Route handlers (not used, routes handle logic)
│   ├── middleware/          # Custom middleware
│   │   ├── auth.ts         # JWT authentication
│   │   ├── errorHandler.ts # Global error handling
│   │   └── requestLogger.ts # Request logging
│   ├── models/             # Data schemas and types
│   │   └── schemas.ts      # Zod validation schemas
│   ├── routes/             # API route definitions
│   │   ├── auth.ts         # Authentication routes
│   │   ├── availability.ts # Availability management
│   │   ├── booking.ts      # Booking management
│   │   └── slots.ts        # Available slots
│   ├── utils/              # Utility functions
│   │   ├── database.ts     # Database connection
│   │   └── timeUtils.ts    # Time and booking utilities
│   └── app.ts              # Application entry point
├── migrations/             # Database migrations
│   ├── init.sql           # Initial schema
│   └── migrate.ts         # Migration runner
├── docker-compose.yml      # Docker services
├── Dockerfile             # Application container
├── package.json           # Dependencies and scripts
├── tsconfig.json          # TypeScript configuration
├── .env.example           # Environment template
└── README.md              # This file
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

---

**Built with ❤️ using Express.js, TypeScript, PostgreSQL, and Docker**
