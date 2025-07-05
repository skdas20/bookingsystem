# Appointment Booking System Backend

A robust, production-ready appointment booking backend built with Express.js, TypeScript, PostgreSQL, and Docker.

[![GitHub Repo](https://img.shields.io/badge/GitHub-View%20on%20GitHub-blue?logo=github)](https://github.com/skdas20/bookingsystem)

---

## 📦 Code Repository

- **GitHub:** [https://github.com/skdas20/bookingsystem](https://github.com/skdas20/bookingsystem)
- All code, migrations, and documentation are maintained in this repository.

---

## 🗄️ PostgreSQL Migrations

- Database schema is managed via SQL migration scripts in the `migrations/` directory.
- Initial schema: [`migrations/init.sql`](migrations/init.sql)
- To run migrations:
  ```bash
  npm run migrate
  # or manually:
  psql -U <user> -d <db> -f migrations/init.sql
  ```

---

## 🚀 Features
- JWT authentication (secure registration/login)
- Timezone-aware scheduling
- Weekly availability management
- Smart slot generation
- Booking creation & cancellation
- Business logic enforcement (lead time, horizon, cancellation)
- Dockerized setup (API + DB)
- TypeScript, Zod validation, professional error handling

---

## 🛠 Tech Stack
- **Backend:** Express.js + TypeScript
- **Database:** PostgreSQL (with migrations)
- **Auth:** JWT, bcrypt
- **Validation:** Zod
- **Time:** date-fns, date-fns-tz
- **Containerization:** Docker, docker-compose

---

## ⚡ Quick Start (Dockerized Setup)

1. **Clone the Repository**
   ```bash
   git clone https://github.com/skdas20/bookingsystem.git
   cd bookingsystem
   cp .env.example .env
   # Edit .env with your secrets and DB credentials
   ```

2. **Start with Docker**
   ```bash
   docker-compose up -d
   ```

3. **Check Health**
   ```bash
   curl http://localhost:3000/health
   ```

---

## 📝 Sample API Calls

### Register User
```bash
curl -X POST http://localhost:3000/api/signup \
  -H "Content-Type: application/json" \
  -d '{"name":"John Doe","email":"john@example.com","password":"password123"}'
```

### Login User
```bash
curl -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"john@example.com","password":"password123"}'
```

### Set Availability
```bash
curl -X POST http://localhost:3000/api/availability \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"dayOfWeek":1,"startTime":"09:00","endTime":"17:00","intervalMin":30,"timeZone":"America/New_York"}'
```

### Get Available Slots
```bash
curl "http://localhost:3000/api/slots?from=2024-01-15&to=2024-01-20" \
  -H "Authorization: Bearer <TOKEN>"
```

### Create Booking
```bash
curl -X POST http://localhost:3000/api/book \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"name":"Jane Smith","email":"jane@example.com","slotStart":"2024-01-15T14:00:00.000Z","slotEnd":"2024-01-15T14:30:00.000Z"}'
```

---

## 🐳 Dockerized Setup (API + DB)

- **Multi-stage Dockerfile** for optimized production builds
- **docker-compose.yml** launches both the API and PostgreSQL database
- **Health checks** for both services
- **Volume persistence** for database data
- **Environment variable** configuration

### Main Docker Commands
```bash
docker-compose up -d      # Start all services
docker-compose down       # Stop all services
docker-compose logs -f    # View logs
docker-compose exec app bash  # Shell into app container
```

---

## 📊 Database Schema (Summary)
- **users**: Auth and user info
- **availability_rules**: Weekly patterns per user
- **bookings**: Appointments with UUIDs and cancel codes

---

## 🔗 API Endpoints (Summary)
- **POST /api/signup**: Register user
- **POST /api/login**: Login user
- **POST /api/availability**: Set availability (auth)
- **GET /api/availability**: List availability (auth)
- **DELETE /api/availability/:id**: Delete rule (auth)
- **GET /api/slots**: Get available slots (auth)
- **POST /api/book**: Book a slot (auth)
- **POST /api/cancel**: Cancel booking
- **GET /api/bookings**: List bookings (auth)
- **GET /health**: Health check

---

## 🏗 Project Structure
```
appointment-booking-backend/
├── src/
│   ├── middleware/          # Custom middleware
│   ├── models/              # Zod validation schemas
│   ├── routes/              # API route definitions
│   ├── utils/               # Utility functions
│   └── app.ts               # Application entry point
├── migrations/              # Database migrations
├── docker-compose.yml       # Docker services
├── Dockerfile               # Application container
├── package.json             # Dependencies and scripts
├── tsconfig.json            # TypeScript configuration
├── .env.example             # Environment template
└── README.md                # This file
```

---

## 🤝 Contributing
1. Fork the repo
2. Create a feature branch
3. Make changes & add tests
4. Submit a pull request

---

**Repository:** [https://github.com/skdas20/bookingsystem](https://github.com/skdas20/bookingsystem)

**Built with ❤️ using Express.js, TypeScript, PostgreSQL, and Docker**
